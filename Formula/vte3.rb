class Vte3 < Formula
  desc "Terminal emulator widget used by GNOME terminal"
  homepage "https://developer.gnome.org/vte/"
  url "https://download.gnome.org/sources/vte/0.58/vte-0.58.1.tar.xz"
  sha256 "24c58afa1859df02b92f90ca8f668dea5629528237b43955bddd9484144258da"

  bottle do
    sha256 "571868c5bf669296fd84e9761a81e827e259ec2b5e8bad618f2c85033fe13071" => :catalina
    sha256 "3d5a0e06a050f484bc2ddb4f5e4d06b4d0b6d2e157aeb47f42c8490c9c8462e3" => :mojave
    sha256 "f4979e598d8e6866b5e61f469cc05781ccf7e3fa1f19aadb0f2aafee03335354" => :high_sierra
  end

  depends_on "gobject-introspection" => :build
  depends_on "meson" => :build
  depends_on "ninja" => :build
  depends_on "pkg-config" => :build
  depends_on "gettext"
  depends_on "gnutls"
  depends_on "gtk+3"
  depends_on "pcre2"
  depends_on "vala"

  # submitted upstream as https://gitlab.gnome.org/tschoonj/vte/merge_requests/1
  patch :DATA

  def install
    ENV["XML_CATALOG_FILES"] = "#{etc}/xml/catalog"

    args = [
      "--prefix=#{prefix}",
      "-Dgir=true",
      "-Dgtk3=true",
      "-Dgnutls=true",
      "-Dvapi=true",
    ]

    mkdir "build" do
      system "meson", *args, ".."
      system "ninja", "-v"
      system "ninja", "install", "-v"
    end
  end

  test do
    (testpath/"test.c").write <<~EOS
      #include <vte/vte.h>

      int main(int argc, char *argv[]) {
        guint v = vte_get_major_version();
        return 0;
      }
    EOS
    atk = Formula["atk"]
    cairo = Formula["cairo"]
    fontconfig = Formula["fontconfig"]
    freetype = Formula["freetype"]
    gdk_pixbuf = Formula["gdk-pixbuf"]
    gettext = Formula["gettext"]
    glib = Formula["glib"]
    gnutls = Formula["gnutls"]
    gtkx3 = Formula["gtk+3"]
    harfbuzz = Formula["harfbuzz"]
    libepoxy = Formula["libepoxy"]
    libpng = Formula["libpng"]
    libtasn1 = Formula["libtasn1"]
    nettle = Formula["nettle"]
    pango = Formula["pango"]
    pixman = Formula["pixman"]
    flags = %W[
      -I#{atk.opt_include}/atk-1.0
      -I#{cairo.opt_include}/cairo
      -I#{fontconfig.opt_include}
      -I#{freetype.opt_include}/freetype2
      -I#{gdk_pixbuf.opt_include}/gdk-pixbuf-2.0
      -I#{gettext.opt_include}
      -I#{glib.opt_include}/gio-unix-2.0/
      -I#{glib.opt_include}/glib-2.0
      -I#{glib.opt_lib}/glib-2.0/include
      -I#{gnutls.opt_include}
      -I#{gtkx3.opt_include}/gtk-3.0
      -I#{harfbuzz.opt_include}/harfbuzz
      -I#{include}/vte-2.91
      -I#{libepoxy.opt_include}
      -I#{libpng.opt_include}/libpng16
      -I#{libtasn1.opt_include}
      -I#{nettle.opt_include}
      -I#{pango.opt_include}/pango-1.0
      -I#{pixman.opt_include}/pixman-1
      -D_REENTRANT
      -L#{atk.opt_lib}
      -L#{cairo.opt_lib}
      -L#{gdk_pixbuf.opt_lib}
      -L#{gettext.opt_lib}
      -L#{glib.opt_lib}
      -L#{gnutls.opt_lib}
      -L#{gtkx3.opt_lib}
      -L#{lib}
      -L#{pango.opt_lib}
      -latk-1.0
      -lcairo
      -lcairo-gobject
      -lgdk-3
      -lgdk_pixbuf-2.0
      -lgio-2.0
      -lglib-2.0
      -lgnutls
      -lgobject-2.0
      -lgtk-3
      -lpango-1.0
      -lpangocairo-1.0
      -lvte-2.91
      -lz
    ]
    flags << "-lintl" if OS.mac?
    system ENV.cc, "test.c", "-o", "test", *flags
    system "./test"
  end
end

__END__
diff --git a/meson.build b/meson.build
index 82266cf7..2e49d669 100644
--- a/meson.build
+++ b/meson.build
@@ -72,6 +72,8 @@ lt_age = vte_minor_version * 100 + vte_micro_version - lt_revision
 lt_current = vte_major_version + lt_age

 libvte_gtk3_soversion = '@0@.@1@.@2@'.format(libvte_soversion, lt_current, lt_revision)
+osx_version_current = lt_current + 1
+libvte_gtk3_osxversions = [osx_version_current, '@0@.@1@.0'.format(osx_version_current, lt_revision)]
 libvte_gtk4_soversion = libvte_soversion.to_string()

 # i18n
diff --git a/src/meson.build b/src/meson.build
index 1481c089..b9590d26 100644
--- a/src/meson.build
+++ b/src/meson.build
@@ -178,6 +178,7 @@ if get_option('gtk3')
     vte_gtk3_api_name,
     sources: libvte_gtk3_sources,
     version: libvte_gtk3_soversion,
+    darwin_versions: libvte_gtk3_osxversions,
     include_directories: incs,
     dependencies: libvte_gtk3_deps,
     cpp_args: libvte_common_cppflags,

diff --git a/meson.build b/meson.build
index 2e49d669..ed8c2ab4 100644
--- a/meson.build
+++ b/meson.build
@@ -359,13 +359,8 @@ linker_flags = [
   '-Wl,-Bsymbolic-functions'
 ]

-foreach flag: linker_flags
-  assert(cc.has_link_argument(flag), flag + ' is required but not supported')
-  add_project_link_arguments(flag, language: 'c')
-
-  assert(cxx.has_link_argument(flag), flag + ' is required but not supported')
-  add_project_link_arguments(flag, language: 'cpp')
-endforeach
+add_project_link_arguments(cc.get_supported_link_arguments(linker_flags), language: 'c')
+add_project_link_arguments(cxx.get_supported_link_arguments(linker_flags), language: 'cpp')

 # Dependencies
