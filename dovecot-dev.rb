class DovecotDev < Formula
  desc "IMAP/POP3 server"
  homepage "http://dovecot.org/"
  url "https://dovecot.org/releases/2.3/dovecot-2.3.15.tar.gz"
  version "2.3.15"
  sha256 "21bbdd5d45957a99133de8b7e71813ecb73d9476c89dfc63479e9102b3553590"
  license all_of: ["BSD-3-Clause", "LGPL-2.1-or-later", "MIT", "Unicode-DFS-2016", :public_domain]

  depends_on "openssl@1.1"
  depends_on "clucene"
  depends_on "cmake"
  depends_on "libstemmer-dev"

  uses_from_macos "bzip2"
  uses_from_macos "sqlite"

  resource "pigeonhole" do
    url "https://pigeonhole.dovecot.org/releases/2.3/dovecot-2.3-pigeonhole-0.5.15.tar.gz"
    sha256 "e1498f50cef74c351a57474cc423b008627ab1ab60724b859283ead6d00550d0"
  end

  resource "xaps" do
    url "https://github.com/st3fan/dovecot-xaps-plugin/archive/v0.8.tar.gz"
    sha256 "315eb0a7507c94884f636fe348f8ac576916325225fd644fc3e43fa5c28f6433"
  end

  def install
    ldflags = "-L/usr/local/opt/openssl/lib"
    cppflags = "-I/usr/local/opt/openssl/include -Wno-error=implicit-function-declaration"

    args = %W[
      --prefix=#{prefix}
      --libexecdir=#{libexec}
      --sysconfdir=#{etc}
      --localstatedir=#{var}
      --with-lucene
      --with-stemmer
      --with-pam
      --with-sqlite
      --with-bzlib
      --with-zlib
      --with-ssl=openssl
      --disable-dependency-tracking
    ]

    system "./configure", *args
    system "make", "install"

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

    resource("xaps").stage do
      inreplace "CMakeLists.txt" do |s|
        s.sub! "include_directories(/usr/local/include/dovecot)", "include_directories(${DOVECOTINC})"
        s.sub! "find_library(LIBDOVECOT dovecot /usr/lib/dovecot/ /usr/local/lib/dovecot/)", "find_library(LIBDOVECOT dovecot /usr/lib/dovecot/ ${DOVECOTLIB})"
        s.sub! "find_library(LIBDOVECOTSTORAGE dovecot-storage /usr/lib/dovecot/ /usr/local/lib/dovecot/)", "find_library(LIBDOVECOTSTORAGE dovecot-storage /usr/lib/dovecot/ ${DOVECOTLIB})"
        s.sub! "/usr/lib/dovecot/modules", "${DOVECOTLIB}"
        s.sub! "/usr/lib/dovecot/modules", "${DOVECOTLIB}"
      end

      mkdir "build"
      cd "build"
      system "pwd"
      system "cmake", "..", *std_cmake_args, "-DCMAKE_BUILD_TYPE=Release", "-DDOVECOTLIB='#{lib}/dovecot'", "-DDOVECOTINC='#{include}/dovecot'"
      system "make", "install"
    end
  end

  def post_install
    (var/"log").mkpath
  end


  plist_options startup: true

  def plist
    <<~EOS
      <?xml version="1.0" encoding="UTF-8"?>
      <!DOCTYPE plist PUBLIC "-//Apple Computer//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
      <plist version="1.0">
        <dict>
          <key>Label</key>
          <string>#{plist_name}</string>
          <key>KeepAlive</key>
          <false/>
          <key>RunAtLoad</key>
          <true/>
          <key>ProgramArguments</key>
          <array>
            <string>#{opt_sbin}/dovecot</string>
            <string>-F</string>
          </array>
          <key>StandardErrorPath</key>
          <string>#{var}/log/dovecot/dovecot.log</string>
          <key>StandardOutPath</key>
          <string>#{var}/log/dovecot/dovecot.log</string>
          <key>SoftResourceLimits</key>
          <dict>
          <key>NumberOfFiles</key>
          <integer>1000</integer>
          </dict>
          <key>HardResourceLimits</key>
          <dict>
          <key>NumberOfFiles</key>
          <integer>1024</integer>
          </dict>
        </dict>
      </plist>
    EOS
  end

  test do
    system "false"
  end
end
