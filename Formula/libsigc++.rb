# libsigc++: Build a bottle for Linuxbrew
class Libsigcxx < Formula
  desc "Callback framework for C++"
  homepage "https://libsigcplusplus.github.io/libsigcplusplus/"
  url "https://download.gnome.org/sources/libsigc++/3.0/libsigc++-3.0.0.tar.xz"
  sha256 "50a0855c1eb26e6044ffe888dbe061938ab4241f96d8f3754ea7ead38ab8ed06"

  bottle do
    cellar :any
    sha256 "1b22b26529168f83d74cef10cd9839b774e701e7929d174edcf3b3b4f50c3272" => :catalina
    sha256 "34d97436f679f9ed9d76a1878d87b29eab692b487cb24aa2b18ba34e6856ab25" => :mojave
    sha256 "ea4710c4dee791bf3109ed28b2cf1d17deb07811f334fc8ff462aafdcf222fc4" => :high_sierra
    sha256 "b5441a1a27991d7653a56d49d9d198348dae821b578523f4965c2bf720246cf6" => :x86_64_linux
  end

  depends_on :macos => :high_sierra if OS.mac? # needs C++17
  unless OS.mac?
    depends_on "m4" => :build
    depends_on "gcc@7"

    fails_with :gcc => "4"
    fails_with :gcc => "5"
    fails_with :gcc => "6"
  end

  def install
    ENV.cxx11
    system "./configure", "--prefix=#{prefix}", "--disable-dependency-tracking"
    system "make"
    system "make", "check"
    system "make", "install"
  end
  test do
    (testpath/"test.cpp").write <<~EOS
      #include <iostream>
      #include <string>
      #include <sigc++/sigc++.h>

      void on_print(const std::string& str) {
        std::cout << str;
      }

      int main(int argc, char *argv[]) {
        sigc::signal<void(const std::string&)> signal_print;

        signal_print.connect(sigc::ptr_fun(&on_print));

        signal_print.emit("hello world\\n");
        return 0;
      }
    EOS
    system ENV.cxx, "-std=c++17", "test.cpp",
                   "-L#{lib}", "-lsigc-3.0", "-I#{include}/sigc++-3.0", "-I#{lib}/sigc++-3.0/include", "-o", "test"
    assert_match "hello world", shell_output("./test")
  end
end
