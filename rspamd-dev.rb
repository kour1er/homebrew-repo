class RspamdDev < Formula
  desc "Rspamd filtering system is created as a replacement of popular spamassassin spamd and is designed to be fast, modular and easily extendable system."
  homepage "https://github.com/rspamd/rspamd/"
  url "https://github.com/rspamd/rspamd/archive/refs/tags/3.4.tar.gz"
  version "3.4"
  sha256 "f8d3e2b9a1a6ed6521c60fe505e97086624407f67366f0ce882eee433a53c355"

  depends_on "cmake"
  depends_on "fann"
  depends_on "gd"
  depends_on "glib-openssl"
  depends_on "gmime"
  depends_on "hyperscan"
  depends_on "icu4c"
  depends_on "kour1er/repo/libstemmer-dev"
  depends_on "libevent"
  depends_on "libmagic"
  depends_on "libsodium"
  depends_on "lua"
  depends_on "luajit"
  depends_on "openblas"
  depends_on "openssl@1.1"
  depends_on "pcre2"
  depends_on "perl"
  depends_on "pkgconfig"
  depends_on "ragel"
  depends_on "redis"
  depends_on "sqlite3"
  depends_on "zlib"

  def install

    args = %W[
    -DCMAKE_EXPORT_COMPILE_COMMANDS=ON
    -DENABLE_FANN=ON
    -DENABLE_GD=ON
    -DENABLE_HYPERSCAN=ON
    -DENABLE_LUAJIT=ON
    -DENABLE_PCRE2=ON
    -DENABLE_SNOWBALL=ON
    -DENABLE_TORCH=ON
    -DINSTALL_EXAMPLES=ON
    -DNO_SHARED=ON
    -DCMAKE_INSTALL_PREFIX=#{prefix}
    -DCONFDIR=#{etc}/rspamd
    -DDBDIR=#{var}/lib/rspamd
    -DLIBDIR=#{prefix}/lib
    -DLOGDIR=#{var}/log
    -DMANDIR=#{prefix}/share/man
    -DRUNDIR=#{var}
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
