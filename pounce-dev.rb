class PounceDev < Formula
  desc "Pounce is a multi-client, TLS-only IRC bouncer. It maintains a persistent connection to an IRC server, acting as a proxy and buffer for a number of clients."
  url "https://git.causal.agency/pounce/snapshot/pounce-41e471e7a77939f9ca1faab32f4f2d84c293d46b.tar.gz"
  version "3.2"
  sha256 "bb9cf3b4ccd250e957baf527d92e1e05f60222fd5fd632e4cd9dbeb59d41644f"

  depends_on "pkgconfig"
  depends_on "libretls"
  depends_on "sqlite3"

  def install
    args = %W[
        --prefix=#{prefix}
        --enable-palaver
    ]

    system "./configure", *args
    system "make"
    system "make", "install"
  end

  test do
    system "false"
  end
end
