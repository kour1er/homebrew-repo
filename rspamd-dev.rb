class RspamdDev < Formula
  desc "Rspamd filtering system is created as a replacement of popular spamassassin spamd and is designed to be fast, modular and easily extendable system."
  homepage "https://github.com/rspamd/rspamd/"
  url "https://github.com/rspamd/rspamd/archive/refs/tags/3.4.tar.gz"
  version "3.4"
  sha256 "f8d3e2b9a1a6ed6521c60fe505e97086624407f67366f0ce882eee433a53c355"

  depends_on "cmake"
  depends_on "glib-openssl"
  depends_on "hyperscan"
  depends_on "icu4c"
  depends_on "libevent"
  depends_on "libmagic"
  depends_on "libsodium"
  depends_on "luajit"
  depends_on "openssl@1.1"
  depends_on "pkgconfig"
  depends_on "ragel"
  depends_on "redis"
  depends_on "sqlite3"

  def install
# Critical dependency note: port:pcre and port:pcre2 break the rspamd binary;
# use native /usr/lib/libpcre.dylib.  See https://github.com/rspamd/rspamd/issues/2884

    args = %W[
    -DCMAKE_EXPORT_COMPILE_COMMANDS=ON
    -DENABLE_HYPERSCAN=ON
    -DENABLE_LUAJIT=ON
    -DENABLE_SNOWBALL=ON
    -DENABLE_TORCH=ON
    -DINSTALL_EXAMPLES=ON
    -DLIBDIR=#{prefix}/lib
    -DDBDIR=#{var}/lib/rspamd
    -DLOGDIR=#{var}/log
    -DRUNDIR=#{var}
    -DMANDIR=#{prefix}/share/man
    -DCMAKE_INSTALL_PREFIX=#{prefix}
    -DCONFDIR=#{etc}/rspamd
    -DNO_SHARED=ON
    -DPCRE_ROOT_DIR=/usr/lib
    ]

    system "cmake", *args
    system "make", "clean"
    system "make"
    system "make", "install"

  end

def post_install
  (var/"lib/rspamd").mkpath
  (var/"run/rspamd").mkpath
end

  def caveats
    <<~EOS
        This dev version uses redis - make sure that service is running.
    EOS
  end

  def plist
    <<~EOS
      <?xml version="1.0" encoding="UTF-8"?>
      <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
      <plist version="1.0">
        <dict>
          <key>Label</key>
          <string>#{plist_name}</string>
          <key>ProgramArguments</key>
          <array>
            <string>#{bin}/rspamd</string>
            <string>-f</string>
          </array>
          <key>StandardErrorPath</key>
          <string>#{var}/log/rspamd.log</string>
          <key>StandardOutPath</key>
          <string>#{var}/log/rspamd.log</string>
          <key>RunAtLoad</key>
          <true/>
        </dict>
      </plist>
    EOS
  end

  test do
    system "false"
  end
end
