class LibstemmerDev < Formula
  desc "Algorithmic Stemmer Library"
  url "https://snowballstem.org/dist/libstemmer_c-2.1.0.tar.gz"
  version "2.1.0"
  sha256 "8c148d3a27745981d29db4909681ec1bc922950b1ade45a01846edea2fb161e6"

  def install
    system "make"

    mkdir "#{prefix}/lib"
    mkdir "#{prefix}/include"
    mv "libstemmer.o", "#{lib}/libstemmer.a"
    mv "include/libstemmer.h", "#{include}/libstemmer.h"
  end

  test do
    system "false"
  end
end
