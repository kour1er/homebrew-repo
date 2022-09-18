class Libexttextcat < Formula
  desc "N-gram-based text categorization library"
  homepage "https://dev-www.libreoffice.org/src/libexttextcat/"
  url "https://dev-www.libreoffice.org/src/libexttextcat/libexttextcat-3.4.6.tar.xz"
  sha256 "6d77eace20e9ea106c1330e268ede70c9a4a89744ddc25715682754eca3368df"
  license ""

  livecheck do
    url :homepage
    regex(/href=.*?libtextcat[._-]v?(\d+(?:\.\d+)+)\.t/i)
  end



  def install
    system "./configure", "--prefix=#{prefix}"
    system "make", "install"
    (include/"libexttextcat/").install Dir["src/*.h"]
    share.install "langclass/LM", "langclass/ShortTexts"
  end


end
