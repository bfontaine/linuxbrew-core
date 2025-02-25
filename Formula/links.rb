class Links < Formula
  desc "Lynx-like WWW browser that supports tables, menus, etc."
  homepage "http://links.twibright.com/"
  url "http://links.twibright.com/download/links-2.20.1.tar.bz2"
  sha256 "bb28a72cb72ca275742ef79e92ba468f0707863366bff2704b0ff6ce52790405"

  bottle do
    cellar :any
    sha256 "02e54327ff6086906bc9d1e499298f52ae5032b2e68f625541a9151cf23dcee5" => :catalina
    sha256 "66ed3179fd7e8e439d3c19b5e11a9903a16ac994baef6aa3b6595e697ebce14d" => :mojave
    sha256 "89b10181d05992aead0afb46a818c9fa3c1218b215146efe864574c877c84545" => :high_sierra
    sha256 "aa2902faaaff12df4013e05c7cd85ff09be788378729091fc0cf140a18c060c2" => :sierra
    sha256 "b039f30c1e0400edc2ca877dbf873dd78330fd3c866e13d83017d91922436a9d" => :x86_64_linux
  end

  depends_on "pkg-config" => :build
  depends_on "jpeg"
  depends_on "librsvg"
  depends_on "libtiff"
  depends_on "openssl@1.1"
  depends_on "linuxbrew/xorg/xorg" unless OS.mac?

  def install
    args = %W[
      --disable-debug
      --disable-dependency-tracking
      --prefix=#{prefix}
      --mandir=#{man}
      --with-ssl=#{Formula["openssl@1.1"].opt_prefix}
      --without-lzma
    ]

    system "./configure", *args
    system "make", "install"
    doc.install Dir["doc/*"]
  end

  test do
    system bin/"links", "-dump", "https://duckduckgo.com"
  end
end
