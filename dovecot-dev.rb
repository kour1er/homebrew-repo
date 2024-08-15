class DovecotDev < Formula
  desc "IMAP/POP3 server"
  homepage "https://dovecot.org/"
  url "https://dovecot.org/releases/2.3/dovecot-2.3.21.1.tar.gz"
  sha256 "2d90a178c4297611088bf7daae5492a3bc3d5ab6328c3a032eb425d2c249097e"
  license all_of: ["BSD-3-Clause", "LGPL-2.1-or-later", "MIT", "Unicode-DFS-2016", :public_domain]

  depends_on "cmake"
  depends_on "icu4c"
  depends_on "libstemmer-dev"
  depends_on "pkg-config" => :build
  depends_on "openssl@3"

  depends_on "xapian"
  depends_on "libtool"
  depends_on "gettext"
  depends_on "autoconf"
  depends_on "automake"

  uses_from_macos "bzip2"
  uses_from_macos "libxcrypt"
  uses_from_macos "sqlite"

  resource "pigeonhole" do
    url "https://pigeonhole.dovecot.org/releases/2.3/dovecot-2.3-pigeonhole-0.5.21.1.tar.gz"
    sha256 "0377db284b620723de060431115fb2e7791e1df4321411af718201d6925c4692"
  end

  resource "flatcurve" do
      url "https://github.com/slusarz/dovecot-fts-flatcurve/archive/refs/tags/v1.0.2.tar.gz"
      sha256 "4ef23d757fed47b55a98bb34df4944a09c06299fd70b5f3a765991fc90a8745a"
  end

  resource "xaps" do
      url "https://github.com/freswa/dovecot-xaps-plugin/archive/refs/tags/v1.0.tar.gz"
      sha256 "3b7a000730315a4b205da8af24b10081a8cab2f6aa32cc19e3729ba15090a332"
  end

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

    system "./configure", *args
    system "make", "install"

    ################################
    # Flatcurve plugin
    ################################
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
