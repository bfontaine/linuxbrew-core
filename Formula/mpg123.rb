class Mpg123 < Formula
  desc "MP3 player for Linux and UNIX"
  homepage "https://www.mpg123.de/"
  url "https://downloads.sourceforge.net/project/mpg123/mpg123/1.25.12/mpg123-1.25.12.tar.bz2"
  sha256 "1ffec7c9683dfb86ea9040d6a53d6ea819ecdda215df347f79def08f1fe731d1"

  bottle do
    sha256 "7e26860cdc0e59aca6d177bf1eb2078fd84668741d33f0e3609a5c6e009b868a" => :catalina
    sha256 "43477cb887e991b1ae0425f25f04028eb59525afb7b4238e9f2c75cf0d0f64fa" => :mojave
    sha256 "abfccbe7e5e75449a097ca95deae82b04d93062d5dd370ad04cbbef656808201" => :high_sierra
    sha256 "b640cb47e7116c278b63fdb37d03653317ceb4af83fc3778ae51646bdd786de0" => :sierra
    sha256 "94f960616da12a720cf6ede09c3423ed3e4f0c68b3f080ae24f25e37012f7512" => :x86_64_linux
  end

  def install
    args = %W[
      --disable-debug
      --disable-dependency-tracking
      --prefix=#{prefix}
      --with-module-suffix=.so
      --with-cpu=x86-64
    ]
    system "./configure", *args
    system "make", "install"
  end

  test do
    system bin/"mpg123", "--test", test_fixtures("test.mp3")
  end
end
