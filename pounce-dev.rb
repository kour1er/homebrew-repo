class PounceDev < Formula
  desc "Pounce is a multi-client, TLS-only IRC bouncer. It maintains a persistent connection to an IRC server, acting as a proxy and buffer for a number of clients."
  url "https://git.causal.agency/pounce/snapshot/pounce-3.1.tar.gz"
  version "3.1"
  sha256 "97f245556b1cc940553fca18f4d7d82692e6c11a30f612415e5e391e5d96604e"

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
