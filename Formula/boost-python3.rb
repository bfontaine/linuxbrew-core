class BoostPython3 < Formula
  desc "C++ library for C++/Python3 interoperability"
  homepage "https://www.boost.org/"
  url "https://dl.bintray.com/boostorg/release/1.71.0/source/boost_1_71_0.tar.bz2"
  sha256 "d73a8da01e8bf8c7eda40b4c84915071a8c8a0df4a6734537ddde4a8580524ee"
  head "https://github.com/boostorg/boost.git"

  bottle do
    cellar :any_skip_relocation
    sha256 "df8408fcf0b39d564ad7e7b926255becc52f00c87db0655c37000f50632ad231" => :catalina
    sha256 "030715604eb213ac9154c7e8e60f189d52f839fc87a580416c7e6088722d7e1a" => :mojave
    sha256 "ec1ebb266260e7f488caccb09c2ae87af5b7d2c1b137033bc7d365165d14eeef" => :high_sierra
    sha256 "66cfacedfd90dd4b88d5d3f990c3f81bf314417376380ed8d9b9d464e4f5a884" => :sierra
    sha256 "9bfcd0f2cf448160c884527bfdd0586f6c50ec64c35d40cde4bb34a3e6f45a68" => :x86_64_linux
  end

  depends_on "boost"
  depends_on "python"

  resource "numpy" do
    url "https://files.pythonhosted.org/packages/2d/80/1809de155bad674b494248bcfca0e49eb4c5d8bee58f26fe7a0dd45029e2/numpy-1.15.4.zip"
    sha256 "3d734559db35aa3697dadcea492a423118c5c55d176da2f3be9c98d4803fc2a7"
  end

  def install
    # "layout" should be synchronized with boost
    args = %W[
      --prefix=#{prefix}
      --libdir=#{lib}
      -d2
      -j#{ENV.make_jobs}
      --layout=tagged-1.66
      --user-config=user-config.jam
      threading=multi,single
      link=shared,static
    ]

    # Boost is using "clang++ -x c" to select C compiler which breaks C++14
    # handling using ENV.cxx14. Using "cxxflags" and "linkflags" still works.
    args << "cxxflags=-std=c++14"
    if ENV.compiler == :clang
      args << "cxxflags=-stdlib=libc++" << "linkflags=-stdlib=libc++"
    end

    # disable python detection in bootstrap.sh; it guesses the wrong include
    # directory for Python 3 headers, so we configure python manually in
    # user-config.jam below.
    inreplace "bootstrap.sh", "using python", "#using python"

    pyver = Language::Python.major_minor_version "python3"
    if OS.mac?
      py_prefix = Formula["python3"].opt_frameworks/"Python.framework/Versions/#{pyver}"
    else
      py_prefix = Formula["python3"].opt_prefix
    end

    numpy_site_packages = buildpath/"homebrew-numpy/lib/python#{pyver}/site-packages"
    numpy_site_packages.mkpath
    ENV["PYTHONPATH"] = numpy_site_packages
    resource("numpy").stage do
      unless OS.mac?
        openblas = Formula["openblas"].opt_prefix
        ENV["ATLAS"] = "None" # avoid linking against Accelerate.framework
        ENV["BLAS"] = ENV["LAPACK"] = "#{openblas}/lib/libopenblas.so"
        config = <<~EOS
          [openblas]
          libraries = openblas
          library_dirs = #{openblas}/lib
          include_dirs = #{openblas}/include
        EOS
        Pathname("site.cfg").write config
      end
      system "python3", *Language::Python.setup_install_args(buildpath/"homebrew-numpy")
    end

    # Force boost to compile with the desired compiler
    darwin = OS.mac? ? "using darwin : : #{ENV.cxx} ;" : ""
    (buildpath/"user-config.jam").write <<~EOS
      #{darwin}
      using python : #{pyver}
                   : python3
                   : #{py_prefix}/include/python#{pyver}m
                   : #{py_prefix}/lib ;
    EOS

    system "./bootstrap.sh", "--prefix=#{prefix}", "--libdir=#{lib}",
                             "--with-libraries=python", "--with-python=python3",
                             "--with-python-root=#{py_prefix}"

    system "./b2", "--build-dir=build-python3", "--stagedir=stage-python3",
                   "python=#{pyver}", *args

    lib.install Dir["stage-python3/lib/*py*"]
    doc.install Dir["libs/python/doc/*"]
  end

  test do
    (testpath/"hello.cpp").write <<~EOS
      #include <boost/python.hpp>
      char const* greet() {
        return "Hello, world!";
      }
      BOOST_PYTHON_MODULE(hello)
      {
        boost::python::def("greet", greet);
      }
    EOS

    pyincludes = Utils.popen_read("python3-config --includes").chomp.split(" ")
    pylib = Utils.popen_read("python3-config --ldflags").chomp.split(" ")
    pyver = Language::Python.major_minor_version("python3").to_s.delete(".")

    system ENV.cxx, "-shared", *("-fPIC" unless OS.mac?), "hello.cpp", "-L#{lib}", "-lboost_python#{pyver}", "-o",
           "hello.so", *pyincludes, *pylib

    output = <<~EOS
      import hello
      print(hello.greet())
    EOS
    assert_match "Hello, world!", pipe_output("python3", output, 0)
  end
end
