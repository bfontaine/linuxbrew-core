# Patches for Qt must be at the very least submitted to Qt's Gerrit codereview
# rather than their bug-report Jira. The latter is rarely reviewed by Qt.
class Qt < Formula
  desc "Cross-platform application and UI framework"
  homepage "https://www.qt.io/"
  url "https://download.qt.io/official_releases/qt/5.13/5.13.1/single/qt-everywhere-src-5.13.1.tar.xz"
  mirror "https://qt.mirror.constant.com/archive/qt/5.13/5.13.1/single/qt-everywhere-src-5.13.1.tar.xz"
  mirror "https://ftp.osuosl.org/pub/blfs/conglomeration/qt5/qt-everywhere-src-5.13.1.tar.xz"
  sha256 "adf00266dc38352a166a9739f1a24a1e36f1be9c04bf72e16e142a256436974e"

  head "https://code.qt.io/qt/qt5.git", :branch => "dev", :shallow => false

  bottle do
    cellar :any
    sha256 "d734eff21324701858605d7896763cbba2440c1350969cd3804d3969b3147d89" => :catalina
    sha256 "a58effe9b3aa460fcd6cc41aa4cef235b6e88d83fe1c863100a6423a37482f8b" => :mojave
    sha256 "eae71268c2333dd6429a704123021ccca05737a629f89d5f7efbf1b1b7c0250b" => :high_sierra
    sha256 "3af3d51d19936f6e46bab0f1dc6c3b1e650090796d74110a2b607b985006b0b1" => :sierra
    sha256 "971579e313ae70f5409e28126c9a48bba96c78988853b815344dd16839d1dab3" => :x86_64_linux
  end

  keg_only "Qt 5 has CMake issues when linked"

  depends_on "pkg-config" => :build
  depends_on :xcode => :build if OS.mac?
  depends_on :macos => :sierra if OS.mac?

  unless OS.mac?
    depends_on "fontconfig"
    depends_on "glib"
    depends_on "icu4c"
    depends_on "libproxy"
    depends_on "pulseaudio"
    depends_on "python@2"
    depends_on "sqlite"
    depends_on "systemd"
    depends_on "libxkbcommon"
    depends_on "linuxbrew/xorg/mesa"
    depends_on "linuxbrew/xorg/xcb-util-image"
    depends_on "linuxbrew/xorg/xcb-util-keysyms"
    depends_on "linuxbrew/xorg/xcb-util-renderutil"
    depends_on "linuxbrew/xorg/xcb-util"
    depends_on "linuxbrew/xorg/xcb-util-wm"
    depends_on "linuxbrew/xorg/xorg"
  end

  def install
    args = %W[
      -verbose
      -prefix #{prefix}
      -release
      -opensource -confirm-license
      -qt-libpng
      -qt-libjpeg
      -qt-freetype
      -qt-pcre
      -nomake examples
      -nomake tests
      -pkg-config
      -dbus-runtime
      -proprietary-codecs
    ]

    if OS.mac?
      args << "-no-rpath"
      args << "-system-zlib"
    elsif OS.linux?
      args << "-system-xcb"
      args << "-R#{lib}"
      # https://bugreports.qt.io/projects/QTBUG/issues/QTBUG-71564
      args << "-no-avx2"
      args << "-no-avx512"
      args << "-qt-zlib"
    end

    system "./configure", *args
    system "make"
    ENV.deparallelize
    system "make", "install"

    # Some config scripts will only find Qt in a "Frameworks" folder
    frameworks.install_symlink Dir["#{lib}/*.framework"]

    # The pkg-config files installed suggest that headers can be found in the
    # `include` directory. Make this so by creating symlinks from `include` to
    # the Frameworks' Headers folders.
    Pathname.glob("#{lib}/*.framework/Headers") do |path|
      include.install_symlink path => path.parent.basename(".framework")
    end

    # Move `*.app` bundles into `libexec` to expose them to `brew linkapps` and
    # because we don't like having them in `bin`.
    # (Note: This move breaks invocation of Assistant via the Help menu
    # of both Designer and Linguist as that relies on Assistant being in `bin`.)
    libexec.mkpath
    Pathname.glob("#{bin}/*.app") { |app| mv app, libexec }
  end

  def caveats; <<~EOS
    We agreed to the Qt open source license for you.
    If this is unacceptable you should uninstall.
  EOS
  end

  test do
    (testpath/"hello.pro").write <<~EOS
      QT       += core
      QT       -= gui
      TARGET = hello
      CONFIG   += console
      CONFIG   -= app_bundle
      TEMPLATE = app
      SOURCES += main.cpp
    EOS

    (testpath/"main.cpp").write <<~EOS
      #include <QCoreApplication>
      #include <QDebug>

      int main(int argc, char *argv[])
      {
        QCoreApplication a(argc, argv);
        qDebug() << "Hello World!";
        return 0;
      }
    EOS

    system bin/"qmake", testpath/"hello.pro"
    system "make"
    assert_predicate testpath/"hello", :exist?
    assert_predicate testpath/"main.o", :exist?
    system "./hello"
  end
end
