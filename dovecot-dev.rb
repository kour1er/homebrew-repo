class DovecotDev < Formula
  desc "IMAP/POP3 server"
  homepage "https://dovecot.org/"
  url "https://dovecot.org/releases/2.3/dovecot-2.3.20.tar.gz"
  sha256 "caa832eb968148abdf35ee9d0f534b779fa732c0ce4a913d9ab8c3469b218552"
  license all_of: ["BSD-3-Clause", "LGPL-2.1-or-later", "MIT", "Unicode-DFS-2016", :public_domain]

  depends_on "clucene"
  depends_on "cmake"
  depends_on "icu4c"
  depends_on "libstemmer-dev"
  depends_on "pkg-config" => :build
  depends_on "solr"
  depends_on "openssl@3"

  uses_from_macos "bzip2"
  uses_from_macos "libxcrypt"
  uses_from_macos "sqlite"

  resource "pigeonhole" do
    url "https://pigeonhole.dovecot.org/releases/2.3/dovecot-2.3-pigeonhole-0.5.20.tar.gz"
    sha256 "ae32bd4870ea2c1328ae09ba206e9ec12128046d6afca52fbbc9ef7f75617c98"

    # Fix -flat_namespace being used on Big Sur and later.
    patch do
      url "https://raw.githubusercontent.com/kour1er/homebrew-repo/main/Patches/dovecot_patch.diff"
      sha256 "35acd6aebc19843f1a2b3a63e880baceb0f5278ab1ace661e57a502d9d78c93c"
    end
  end

  resource "xaps" do
      url "https://github.com/st3fan/dovecot-xaps-plugin/archive/v0.8.tar.gz"
      sha256 "315eb0a7507c94884f636fe348f8ac576916325225fd644fc3e43fa5c28f6433"
  end

  # Fix -flat_namespace being used on Big Sur and later.
  patch do
      url "https://raw.githubusercontent.com/kour1er/homebrew-repo/main/Patches/dovecot_patch.diff"
      sha256 "35acd6aebc19843f1a2b3a63e880baceb0f5278ab1ace661e57a502d9d78c93c"
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
      --with-lucene
      --with-stemmer
      --with-solr
    ]

    system "./configure", *args
    system "make", "install"

    ####################
    # Pigeonhole plugin
    ####################
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
