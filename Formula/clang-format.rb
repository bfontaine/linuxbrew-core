class ClangFormat < Formula
  desc "Formatting tools for C, C++, Obj-C, Java, JavaScript, TypeScript"
  homepage "https://clang.llvm.org/docs/ClangFormat.html"
  version "2019-01-18"

  stable do
    depends_on "subversion" => :build
    url "https://llvm.org/svn/llvm-project/llvm/tags/google/stable/2019-01-18/", :using => :svn

    resource "clang" do
      url "https://llvm.org/svn/llvm-project/cfe/tags/google/stable/2019-01-18/", :using => :svn
    end

    resource "libcxx" do
      url "https://releases.llvm.org/7.0.0/libcxx-7.0.0.src.tar.xz"
      sha256 "9b342625ba2f4e65b52764ab2061e116c0337db2179c6bce7f9a0d70c52134f0"
    end
  end

  bottle do
    cellar :any_skip_relocation
    sha256 "c4853df4dff64d36da2718b9cb2d48713ba40eb1c320e94526db6c581824105a" => :catalina
    sha256 "e21e425f294cb6daf81dce2de430401dbc00369fc7cc2c3ff76770eee50b149f" => :mojave
    sha256 "2937b78b833fa1ad75a170e31d90fda274b400bad21e509797fe1d6fa95812fd" => :high_sierra
    sha256 "d88400e9a753ad87ff398d0a9d270110d39d34129894c109f1f1612394b2d942" => :sierra
    sha256 "3def6f73bc82c86f646aec165aa626b08bd8573948f16efd81fb29d97897e351" => :x86_64_linux
  end

  head do
    url "https://git.llvm.org/git/llvm.git"

    resource "clang" do
      url "https://git.llvm.org/git/clang.git"
    end

    resource "libcxx" do
      url "https://git.llvm.org/git/libcxx.git"
    end
  end

  depends_on "cmake" => :build
  depends_on "ninja" => :build
  depends_on "subversion" => :build
  unless OS.mac?
    depends_on "bison" => :build
    depends_on "gcc" # needed for libstdc++
    depends_on "glibc" => (Formula["glibc"].installed? || OS::Linux::Glibc.system_version < Formula["glibc"].version) ? :recommended : :optional
    depends_on "libedit" # llvm requires <histedit.h>
    depends_on "ncurses"
    depends_on "libxml2"
    depends_on "zlib"
  end

  def install
    (buildpath/"projects/libcxx").install resource("libcxx") if OS.mac?
    (buildpath/"tools/clang").install resource("clang")

    mkdir "build" do
      args = std_cmake_args
      args << "-DCMAKE_OSX_SYSROOT=/" unless OS.mac? && MacOS::Xcode.installed?
      args << "-DLLVM_ENABLE_LIBCXX=ON" if OS.mac?
      args << "-DLLVM_ENABLE_LIBCXX=OFF" unless OS.mac?
      args << ".."
      system "cmake", "-G", "Ninja", *args
      system "ninja", *("-j2" if ENV["CIRCLECI"]), "clang-format"
      bin.install "bin/clang-format"
    end
    bin.install "tools/clang/tools/clang-format/git-clang-format"
    (share/"clang").install Dir["tools/clang/tools/clang-format/clang-format*"]
  end

  test do
    # NB: below C code is messily formatted on purpose.
    (testpath/"test.c").write <<~EOS
      int         main(char *args) { \n   \t printf("hello"); }
    EOS

    assert_equal "int main(char *args) { printf(\"hello\"); }\n",
        shell_output("#{bin}/clang-format -style=Google test.c")
  end
end
