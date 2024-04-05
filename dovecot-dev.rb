class DovecotDev < Formula
  desc "IMAP/POP3 server"
  homepage "https://dovecot.org/"
  url "https://dovecot.org/releases/2.3/dovecot-2.3.21.tar.gz"
  version "2.3.21_1"
  sha256 "05b11093a71c237c2ef309ad587510721cc93bbee6828251549fc1586c36502d"
  license all_of: ["BSD-3-Clause", "LGPL-2.1-or-later", "MIT", "Unicode-DFS-2016", :public_domain]

  option "with-solr", "Compiles with optional Solr support"
  option "with-flatcurve", "Compiles with optional Flatcurve support"

  depends_on "cmake"
  depends_on "icu4c"
  depends_on "libstemmer-dev"
  depends_on "pkg-config" => :build
  depends_on "openssl@3"

  depends_on "solr" if build.with? "solr"
  depends_on "xapian" if build.with? "flatcurve"
  # depends_on "libtextcat" if build.with? "flatcurve"
  depends_on "libtool" if build.with? "flatcurve"
  depends_on "gettext" if build.with? "flatcurve"
  depends_on "autoconf" if build.with? "flatcurve"
  depends_on "automake" if build.with? "flatcurve"

  uses_from_macos "bzip2"
  uses_from_macos "libxcrypt"
  uses_from_macos "sqlite"

  resource "pigeonhole" do
    url "https://pigeonhole.dovecot.org/releases/2.3/dovecot-2.3-pigeonhole-0.5.21.tar.gz"
    sha256 "1ca71d2659076712058a72030288f150b2b076b0306453471c5261498d3ded27"
  end

  resource "flatcurve" do
      url "https://github.com/slusarz/dovecot-fts-flatcurve/archive/refs/tags/v1.0.2.tar.gz"
      sha256 "4ef23d757fed47b55a98bb34df4944a09c06299fd70b5f3a765991fc90a8745a"
  end

  resource "xaps" do
      url "https://github.com/freswa/dovecot-xaps-plugin/archive/refs/tags/v1.0.tar.gz"
      sha256 "3b7a000730315a4b205da8af24b10081a8cab2f6aa32cc19e3729ba15090a332"
  end

  # dbox-storage.c:296:32: error: no member named 'st_atim' in 'struct stat'
  # dbox-storage.c:297:24: error: no member named 'st_ctim' in 'struct stat'
  # Following two patches submitted upstream at https://github.com/dovecot/core/pull/211
  patch do
    url "https://github.com/dovecot/core/commit/6b2eb995da62b8eca9d8f713bd5858d3d9be8062.patch?full_index=1"
    sha256 "3e3f74b95f95a1587a804e9484467b1ed77396376b0a18be548e91e1b904ae1b"
  end

  patch do
    url "https://github.com/dovecot/core/commit/eca7b6b9984dd1cb5fcd28f7ebccaa5301aead1e.patch?full_index=1"
    sha256 "cedfeadd1cd43df3eebfcf3f465314fad4f6785c33000cbbd1349e3e0eb8c0ee"
  end

  def install
    args = %W[
      --prefix=#{prefix}
      --disable-dependency-tracking
      --libexecdir=#{libexec}
      --sysconfdir=#{etc}
      --localstatedir=#{var}
      --with-pam
      --with-sqlite
      --with-bzlib
      --with-zlib
      --with-ssl=openssl
      --with-icu
      --with-stemmer
    ]

  if build.with? "solr"
      puts "building with solr..."
      args << "--with-solr"
    end

    system "./configure", *args
    system "make", "install"

    ################################
    # Flatcurve plugin
    ################################
    if build.with? "flatcurve"
        puts "compiling Flatcurve plugin..."
        resource("flatcurve").stage do
            args = %W[
                --with-dovecot=#{lib}/dovecot
                --prefix=#{prefix}
            ]

            system "./autogen.sh"
            system "./configure", *args
            system "make"
            system "make", "install"
        end
    end

    ####################
    # Pigeonhole plugin
    ####################
    puts "building Pigeonhole plugin..."
    resource("pigeonhole").stage do
      args = %W[
        --disable-dependency-tracking
        --with-dovecot=#{lib}/dovecot
        --prefix=#{prefix}
      ]

      system "./configure", *args
      system "make"
      system "make", "install"
    end

    ################################
    # XAPS push notification plugin
    ################################
    puts "building XAPS plugin..."
    resource("xaps").stage do
      inreplace "CMakeLists.txt" do |s|
        s.sub! "include_directories(/usr/local/include/dovecot)", "include_directories(${DOVECOTINC})"
        s.sub! "find_library(LIBDOVECOT dovecot /usr/lib/dovecot/ /usr/local/lib/dovecot/)", "find_library(LIBDOVECOT dovecot /usr/lib/dovecot/ ${DOVECOTLIB})"
        s.sub! "find_library(LIBDOVECOTSTORAGE dovecot-storage /usr/lib/dovecot/ /usr/local/lib/dovecot/)", "find_library(LIBDOVECOTSTORAGE dovecot-storage /usr/lib/dovecot/ ${DOVECOTLIB})"
        s.sub! "/usr/lib/dovecot/modules", "${DOVECOTLIB}"
        s.sub! "/usr/lib/dovecot/modules", "${DOVECOTLIB}"
      end

      args = %W[
        -DCMAKE_BUILD_TYPE=Release
        -DDOVECOTLIB=#{lib}/dovecot
        -DDOVECOTINC=#{include}/dovecot
      ]

      mkdir "build"
      cd "build"
      system "cmake", "..", *std_cmake_args, *args
      system "make", "install"
    end

  end

  def caveats
    <<~EOS
      For Dovecot to work, you may need to create a dovecot user
      and group depending on your configuration file options.
    EOS
  end

  service do
    run [opt_sbin/"dovecot", "-F"]
    require_root true
    environment_variables PATH: std_service_path_env
    error_log_path var/"log/dovecot/dovecot.log"
    log_path var/"log/dovecot/dovecot.log"
  end

  test do
    assert_match version.to_s, shell_output("#{sbin}/dovecot --version")

    cp_r share/"doc/dovecot/example-config", testpath/"example"
    inreplace testpath/"example/conf.d/10-master.conf" do |s|
      s.gsub! "#default_login_user = dovenull", "default_login_user = #{ENV["USER"]}"
      s.gsub! "#default_internal_user = dovecot", "default_internal_user = #{ENV["USER"]}"
    end
    system bin/"doveconf", "-c", testpath/"example/dovecot.conf"
  end
end
