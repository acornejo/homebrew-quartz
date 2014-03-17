require 'formula'

class InkscapeQuartz < Formula
  homepage 'http://www.inkscape.org'
  url 'http://downloads.sourceforge.net/inkscape/inkscape-0.48.2.tar.bz2'
  md5 'f60b98013bd1121b2cc301f3485076ba'

  # Inkscape is a meaty bastard.
  depends_on 'pkg-config' => :build
  depends_on 'intltool' => :build
  depends_on 'boost-build' => :build
  depends_on :x11
  depends_on 'boehmgc'
  depends_on 'boost'
  depends_on 'gsl'
  depends_on 'hicolor-icon-theme'
  depends_on 'little-cms'
  depends_on 'libwpg'
  depends_on 'popt'

  depends_on 'acornejo/quartz/cairomm-quartz'
  depends_on 'acornejo/quartz/pango-quartz'
  depends_on 'acornejo/quartz/gtkmm-quartz'
  depends_on 'acornejo/quartz/librsvg-quartz'
  depends_on 'acornejo/quartz/poppler-quartz'

  def patches
      # fixes glib issues, png issues, clang issues, configure gcc bug & makefile --enable-dynamic flag
      DATA
  end

  def install
    ENV.x11
    args = ["--disable-debug", "--disable-dependency-tracking", "--prefix=#{prefix}"]
    system "./configure", *args
    system "make install"
  end
end
__END__
diff -urEw inkscape-0.48.2/configure ./configure
--- inkscape-0.48.2/configure	2012-09-12 00:50:23.000000000 -0400
+++ ./configure	2012-09-12 00:45:28.000000000 -0400
@@ -7202,9 +7202,9 @@
 	test -n "$cc_vers_patch" || cc_vers_patch=0
 	cc_vers_all=`expr $cc_vers_major '*' 1000000 + $cc_vers_minor '*' 1000 + $cc_vers_patch`
 
-	if test $cc_vers_major -lt 3; then
-		as_fn_error $? "gcc >= 3.0 is needed to compile inkscape" "$LINENO" 5
-	fi
+	# if test $cc_vers_major -lt 3; then
+	# 	as_fn_error $? "gcc >= 3.0 is needed to compile inkscape" "$LINENO" 5
+	# fi
 fi
 
 # Detect a working version of unordered containers.
diff -urEw inkscape-0.48.2/src/2geom/basic-intersection.cpp ./src/2geom/basic-intersection.cpp
--- inkscape-0.48.2/src/2geom/basic-intersection.cpp	2012-09-12 00:50:23.000000000 -0400
+++ ./src/2geom/basic-intersection.cpp	2012-09-11 17:16:21.000000000 -0400
@@ -64,24 +64,24 @@
 void split(vector<Point> const &p, double t, 
            vector<Point> &left, vector<Point> &right) {
     const unsigned sz = p.size();
-    Geom::Point Vtemp[sz][sz];
+    std::vector<Geom::Point> Vtemp(sz*sz);
 
     /* Copy control points	*/
-    std::copy(p.begin(), p.end(), Vtemp[0]);
+    std::copy(p.begin(), p.end(), Vtemp.begin());
 
     /* Triangle computation	*/
     for (unsigned i = 1; i < sz; i++) {
         for (unsigned j = 0; j < sz - i; j++) {
-            Vtemp[i][j] = lerp(t, Vtemp[i-1][j], Vtemp[i-1][j+1]);
+            Vtemp[i+j*sz] = lerp(t, Vtemp[(i-1)+j*sz], Vtemp[(i-1)+(j+1)*sz]);
         }
     }
 
     left.resize(sz);
     right.resize(sz);
     for (unsigned j = 0; j < sz; j++)
-        left[j]  = Vtemp[j][0];
+        left[j]  = Vtemp[j];
     for (unsigned j = 0; j < sz; j++)
-        right[j] = Vtemp[sz-1-j][j];
+        right[j] = Vtemp[sz-1-j+j*sz];
 }
 
 
diff -urEw inkscape-0.48.2/src/2geom/matrix.h ./src/2geom/matrix.h
--- inkscape-0.48.2/src/2geom/matrix.h	2012-09-12 00:50:23.000000000 -0400
+++ ./src/2geom/matrix.h	2012-09-11 16:14:09.000000000 -0400
@@ -17,7 +17,7 @@
  * This code is in public domain.
  */
 
-//#include <glib/gmessages.h>
+//#include <glib.h>
 
 #include <2geom/point.h>
 
diff -urEw inkscape-0.48.2/src/2geom/solve-bezier-parametric.cpp ./src/2geom/solve-bezier-parametric.cpp
--- inkscape-0.48.2/src/2geom/solve-bezier-parametric.cpp	2012-09-12 00:50:23.000000000 -0400
+++ ./src/2geom/solve-bezier-parametric.cpp	2012-09-12 00:07:54.000000000 -0400
@@ -69,12 +69,12 @@
     }
 
     /* Otherwise, solve recursively after subdividing control polygon  */
-    Geom::Point Left[degree+1],	/* New left and right  */
-        Right[degree+1];	/* control polygons  */
-    Bezier(w, degree, 0.5, Left, Right);
+    std::vector<Geom::Point> Left(degree+1), /* New left and right  */
+        Right(degree+1);	/* control polygons  */
+    Bezier(w, degree, 0.5, &Left[0], &Right[0]);
     total_subs ++;
-    find_parametric_bezier_roots(Left,  degree, solutions, depth+1);
-    find_parametric_bezier_roots(Right, degree, solutions, depth+1);
+    find_parametric_bezier_roots(&Left[0],  degree, solutions, depth+1);
+    find_parametric_bezier_roots(&Right[0], degree, solutions, depth+1);
 }
 
 
@@ -191,24 +191,25 @@
        Geom::Point *Left,	/* RETURN left half ctl pts */
        Geom::Point *Right)	/* RETURN right half ctl pts */
 {
-    Geom::Point Vtemp[degree+1][degree+1];
+    const unsigned int sz=degree+1;
+    std::vector<Geom::Point> Vtemp(sz*sz);
 
     /* Copy control points	*/
-    std::copy(V, V+degree+1, Vtemp[0]);
+    std::copy(V, V+sz, Vtemp.begin());
 
     /* Triangle computation	*/
     for (unsigned i = 1; i <= degree; i++) {	
         for (unsigned j = 0; j <= degree - i; j++) {
-            Vtemp[i][j] = lerp(t, Vtemp[i-1][j], Vtemp[i-1][j+1]);
+            Vtemp[i+j*sz] = lerp(t, Vtemp[i-1+j*sz], Vtemp[i-1+(j+1)*sz]);
         }
     }
     
     for (unsigned j = 0; j <= degree; j++)
-        Left[j]  = Vtemp[j][0];
+        Left[j]  = Vtemp[j];
     for (unsigned j = 0; j <= degree; j++)
-        Right[j] = Vtemp[degree-j][j];
+        Right[j] = Vtemp[degree-j+j*sz];
 
-    return (Vtemp[degree][0]);
+    return Vtemp[degree];
 }
 
 };
diff -urEw inkscape-0.48.2/src/Makefile.am ./src/Makefile.am
--- inkscape-0.48.2/src/Makefile.am	2011-07-08 14:25:09.000000000 -0400
+++ ./src/Makefile.am	2012-09-12 00:46:54.000000000 -0400
@@ -206,7 +206,7 @@
 inkscape_SOURCES += main.cpp $(win32_sources)
 inkscape_LDADD = $(all_libs)
 if PLATFORM_OSX
-inkscape_LDFLAGS = --export-dynamic $(kdeldflags) $(mwindows)
+inkscape_LDFLAGS = $(kdeldflags) $(mwindows)
 else
 inkscape_LDFLAGS = -Wl,--export-dynamic $(kdeldflags) $(mwindows)
 endif
diff -urEw inkscape-0.48.2/src/Makefile.in ./src/Makefile.in
--- inkscape-0.48.2/src/Makefile.in	2011-07-08 15:25:02.000000000 -0400
+++ ./src/Makefile.in	2012-09-12 00:47:03.000000000 -0400
@@ -2981,7 +2981,7 @@
 libinkscape_a_SOURCES = $(ink_common_sources)
 inkscape_LDADD = $(all_libs)
 @PLATFORM_OSX_FALSE@inkscape_LDFLAGS = -Wl,--export-dynamic $(kdeldflags) $(mwindows)
-@PLATFORM_OSX_TRUE@inkscape_LDFLAGS = --export-dynamic $(kdeldflags) $(mwindows)
+@PLATFORM_OSX_TRUE@inkscape_LDFLAGS = $(kdeldflags) $(mwindows)
 inkview_LDADD = $(all_libs)
 inkview_LDFLAGS = $(mwindows) 
 
diff -urEw inkscape-0.48.2/src/application/application.h ./src/application/application.h
--- inkscape-0.48.2/src/application/application.h	2012-09-12 00:50:23.000000000 -0400
+++ ./src/application/application.h	2012-09-11 16:14:09.000000000 -0400
@@ -13,7 +13,7 @@
 #ifndef INKSCAPE_APPLICATION_APPLICATION_H
 #define INKSCAPE_APPLICATION_APPLICATION_H
 
-#include <glib/gtypes.h>
+#include <glib.h>
 
 namespace Gtk {
 class Main;
diff -urEw inkscape-0.48.2/src/application/editor.h ./src/application/editor.h
--- inkscape-0.48.2/src/application/editor.h	2012-09-12 00:50:23.000000000 -0400
+++ ./src/application/editor.h	2012-09-11 16:14:09.000000000 -0400
@@ -16,7 +16,7 @@
 #define INKSCAPE_APPLICATION_EDITOR_H
 
 #include <sigc++/sigc++.h>
-#include <glib/gslist.h>
+#include <glib.h>
 #include <glibmm/ustring.h>
 #include <set>
 #include "app-prototype.h"
diff -urEw inkscape-0.48.2/src/attributes-test.h ./src/attributes-test.h
--- inkscape-0.48.2/src/attributes-test.h	2012-09-12 00:50:23.000000000 -0400
+++ ./src/attributes-test.h	2012-09-11 16:14:09.000000000 -0400
@@ -6,7 +6,7 @@
 
 #include <vector>
 #include <glib.h>
-#include <glib/gprintf.h>
+#include <glib.h>
 #include "attributes.h"
 #include "streq.h"
 
diff -urEw inkscape-0.48.2/src/attributes.cpp ./src/attributes.cpp
--- inkscape-0.48.2/src/attributes.cpp	2012-09-12 00:50:23.000000000 -0400
+++ ./src/attributes.cpp	2012-09-11 16:41:59.000000000 -0400
@@ -18,7 +18,7 @@
 #endif
 
 #include <glib.h> // g_assert()
-#include <glib/ghash.h>
+#include <glib.h>
 #include "attributes.h"
 
 typedef struct {
diff -urEw inkscape-0.48.2/src/attributes.h ./src/attributes.h
--- inkscape-0.48.2/src/attributes.h	2012-09-12 00:50:23.000000000 -0400
+++ ./src/attributes.h	2012-09-11 16:14:09.000000000 -0400
@@ -13,8 +13,8 @@
  *
  * Released under GNU GPL, read the file 'COPYING' for more information
  */
-#include <glib/gtypes.h>
-#include <glib/gmessages.h>
+#include <glib.h>
+#include <glib.h>
 
 unsigned int sp_attribute_lookup(gchar const *key);
 unsigned char const *sp_attribute_name(unsigned int id);
diff -urEw inkscape-0.48.2/src/bind/javabind.cpp ./src/bind/javabind.cpp
--- inkscape-0.48.2/src/bind/javabind.cpp	2012-09-12 00:50:23.000000000 -0400
+++ ./src/bind/javabind.cpp	2012-09-11 16:41:59.000000000 -0400
@@ -52,7 +52,7 @@
 #include "javabind-private.h"
 #include <path-prefix.h>
 #include <prefix.h>
-#include <glib/gmessages.h>
+#include <glib.h>
 
 //For repr and document
 #include <document.h>
diff -urEw inkscape-0.48.2/src/box3d.cpp ./src/box3d.cpp
--- inkscape-0.48.2/src/box3d.cpp	2012-09-12 00:50:23.000000000 -0400
+++ ./src/box3d.cpp	2012-09-11 16:41:59.000000000 -0400
@@ -460,7 +460,7 @@
     Box3D::Line diag2(A, E); // diag2 is only taken into account if id equals -1, i.e., if we are snapping the center
 
     int num_snap_lines = (id != -1) ? 3 : 4;
-    Geom::Point snap_pts[num_snap_lines];
+    Geom::Point snap_pts[4];
 
     snap_pts[0] = pl1.closest_to (pt);
     snap_pts[1] = pl2.closest_to (pt);
diff -urEw inkscape-0.48.2/src/color-profile-fns.h ./src/color-profile-fns.h
--- inkscape-0.48.2/src/color-profile-fns.h	2012-09-12 00:50:23.000000000 -0400
+++ ./src/color-profile-fns.h	2012-09-11 16:14:09.000000000 -0400
@@ -6,7 +6,7 @@
  */
 
 #include <glib-object.h>
-#include <glib/gtypes.h>
+#include <glib.h>
 #if ENABLE_LCMS
 #include <vector>
 #include <glibmm/ustring.h>
diff -urEw inkscape-0.48.2/src/color-profile.cpp ./src/color-profile.cpp
--- inkscape-0.48.2/src/color-profile.cpp	2012-09-12 00:50:23.000000000 -0400
+++ ./src/color-profile.cpp	2012-09-11 16:43:07.000000000 -0400
@@ -4,6 +4,7 @@
 
 #define noDEBUG_LCMS
 
+#include <glib.h>
 #include <glib/gstdio.h>
 #include <sys/fcntl.h>
 #include <gdkmm/color.h>
diff -urEw inkscape-0.48.2/src/color-profile.h ./src/color-profile.h
--- inkscape-0.48.2/src/color-profile.h	2012-09-12 00:50:23.000000000 -0400
+++ ./src/color-profile.h	2012-09-11 16:14:09.000000000 -0400
@@ -5,7 +5,7 @@
  * SPColorProfile: SVG <color-profile> implementation
  */
 
-#include <glib/gtypes.h>
+#include <glib.h>
 #include <sp-object.h>
 #include <glibmm/ustring.h>
 #if ENABLE_LCMS
diff -urEw inkscape-0.48.2/src/color-rgba.h ./src/color-rgba.h
--- inkscape-0.48.2/src/color-rgba.h	2012-09-12 00:50:23.000000000 -0400
+++ ./src/color-rgba.h	2012-09-11 16:14:09.000000000 -0400
@@ -13,7 +13,7 @@
 #define SEEN_COLOR_RGBA_H
 
 #include <glib.h> // g_assert()
-#include <glib/gmessages.h>
+#include <glib.h>
 #include "libnr/nr-pixops.h"
 #include "decimal-round.h"
 
diff -urEw inkscape-0.48.2/src/conn-avoid-ref.h ./src/conn-avoid-ref.h
--- inkscape-0.48.2/src/conn-avoid-ref.h	2012-09-12 00:50:23.000000000 -0400
+++ ./src/conn-avoid-ref.h	2012-09-11 16:14:09.000000000 -0400
@@ -13,7 +13,7 @@
  * Released under GNU GPL, read the file 'COPYING' for more information
  */
 
-#include <glib/gslist.h>
+#include <glib.h>
 #include <stddef.h>
 #include <sigc++/connection.h>
 
diff -urEw inkscape-0.48.2/src/debug/logger.cpp ./src/debug/logger.cpp
--- inkscape-0.48.2/src/debug/logger.cpp	2012-09-12 00:50:23.000000000 -0400
+++ ./src/debug/logger.cpp	2012-09-11 16:41:59.000000000 -0400
@@ -11,7 +11,7 @@
 
 #include <fstream>
 #include <vector>
-#include <glib/gmessages.h>
+#include <glib.h>
 #include "inkscape-version.h"
 #include "debug/logger.h"
 #include "debug/simple-event.h"
diff -urEw inkscape-0.48.2/src/debug/simple-event.h ./src/debug/simple-event.h
--- inkscape-0.48.2/src/debug/simple-event.h	2012-09-12 00:50:23.000000000 -0400
+++ ./src/debug/simple-event.h	2012-09-11 16:14:09.000000000 -0400
@@ -15,8 +15,8 @@
 #include <stdarg.h>
 #include <vector>
 #include <glib.h> // g_assert()
-#include <glib/gstrfuncs.h>
-#include <glib/gmessages.h>
+#include <glib.h>
+#include <glib.h>
 
 #include "gc-alloc.h"
 #include "debug/event.h"
diff -urEw inkscape-0.48.2/src/debug/timestamp.cpp ./src/debug/timestamp.cpp
--- inkscape-0.48.2/src/debug/timestamp.cpp	2012-09-12 00:50:23.000000000 -0400
+++ ./src/debug/timestamp.cpp	2012-09-11 16:41:59.000000000 -0400
@@ -10,8 +10,8 @@
  */
 
 
-#include <glib/gtypes.h>
-#include <glib/gmain.h>
+#include <glib.h>
+#include <glib.h>
 #include <glibmm/ustring.h>
 #include "debug/simple-event.h"
 
diff -urEw inkscape-0.48.2/src/desktop-style.h ./src/desktop-style.h
--- inkscape-0.48.2/src/desktop-style.h	2012-09-12 00:50:23.000000000 -0400
+++ ./src/desktop-style.h	2012-09-11 16:14:09.000000000 -0400
@@ -13,7 +13,7 @@
  * Released under GNU GPL, read the file 'COPYING' for more information
  */
 
-#include <glib/gtypes.h>
+#include <glib.h>
 
 class ColorRGBA;
 struct SPCSSAttr;
diff -urEw inkscape-0.48.2/src/dialogs/clonetiler.cpp ./src/dialogs/clonetiler.cpp
--- inkscape-0.48.2/src/dialogs/clonetiler.cpp	2012-09-12 00:50:23.000000000 -0400
+++ ./src/dialogs/clonetiler.cpp	2012-09-11 16:41:59.000000000 -0400
@@ -12,7 +12,7 @@
 #ifdef HAVE_CONFIG_H
 # include "config.h"
 #endif
-#include <glib/gmem.h>
+#include <glib.h>
 #include <gtk/gtk.h>
 #include <glibmm/i18n.h>
 
diff -urEw inkscape-0.48.2/src/dir-util.cpp ./src/dir-util.cpp
--- inkscape-0.48.2/src/dir-util.cpp	2012-09-12 00:50:23.000000000 -0400
+++ ./src/dir-util.cpp	2012-09-11 16:41:59.000000000 -0400
@@ -7,11 +7,7 @@
 #include <errno.h>
 #include <string>
 #include <cstring>
-#include <glib/gutils.h>
-#include <glib/gmem.h>
-#include <glib/gerror.h>
-#include <glib/gconvert.h>
-#include <glib/gstrfuncs.h>
+#include <glib.h>
 
 /** Returns a form of \a path relative to \a base if that is easy to construct (e.g. if \a path
     appears to be in the directory specified by \a base), otherwise returns \a path.
diff -urEw inkscape-0.48.2/src/dir-util.h ./src/dir-util.h
--- inkscape-0.48.2/src/dir-util.h	2012-09-12 00:50:23.000000000 -0400
+++ ./src/dir-util.h	2012-09-11 16:14:10.000000000 -0400
@@ -10,7 +10,7 @@
  */
 
 #include <stdlib.h>
-#include <glib/gtypes.h>
+#include <glib.h>
 
 char const *sp_relative_path_from_path(char const *path, char const *base);
 char const *sp_extension_from_path(char const *path);
diff -urEw inkscape-0.48.2/src/display/canvas-bpath.h ./src/display/canvas-bpath.h
--- inkscape-0.48.2/src/display/canvas-bpath.h	2012-09-12 00:50:23.000000000 -0400
+++ ./src/display/canvas-bpath.h	2012-09-11 16:14:10.000000000 -0400
@@ -13,7 +13,7 @@
  *
  */
 
-#include <glib/gtypes.h>
+#include <glib.h>
 
 #include <display/sp-canvas.h>
 
diff -urEw inkscape-0.48.2/src/display/curve.cpp ./src/display/curve.cpp
--- inkscape-0.48.2/src/display/curve.cpp	2012-09-12 00:50:23.000000000 -0400
+++ ./src/display/curve.cpp	2012-09-11 16:41:59.000000000 -0400
@@ -19,7 +19,7 @@
 
 #include "display/curve.h"
 
-#include <glib/gmessages.h>
+#include <glib.h>
 #include <2geom/pathvector.h>
 #include <2geom/sbasis-geometric.h>
 #include <2geom/sbasis-to-bezier.h>
diff -urEw inkscape-0.48.2/src/display/curve.h ./src/display/curve.h
--- inkscape-0.48.2/src/display/curve.h	2012-09-12 00:50:23.000000000 -0400
+++ ./src/display/curve.h	2012-09-11 16:14:10.000000000 -0400
@@ -15,8 +15,8 @@
  * Released under GNU GPL
  */
 
-#include <glib/gtypes.h>
-#include <glib/gslist.h>
+#include <glib.h>
+#include <glib.h>
 
 #include <2geom/forward.h>
 
diff -urEw inkscape-0.48.2/src/display/gnome-canvas-acetate.h ./src/display/gnome-canvas-acetate.h
--- inkscape-0.48.2/src/display/gnome-canvas-acetate.h	2012-09-12 00:50:23.000000000 -0400
+++ ./src/display/gnome-canvas-acetate.h	2012-09-11 16:14:10.000000000 -0400
@@ -15,7 +15,7 @@
  * Released under GNU GPL, read the file 'COPYING' for more information
  */
 
-#include <glib/gtypes.h>
+#include <glib.h>
 #include "display/sp-canvas.h"
 
 
diff -urEw inkscape-0.48.2/src/display/nr-3dutils.cpp ./src/display/nr-3dutils.cpp
--- inkscape-0.48.2/src/display/nr-3dutils.cpp	2012-09-12 00:50:23.000000000 -0400
+++ ./src/display/nr-3dutils.cpp	2012-09-11 16:41:59.000000000 -0400
@@ -9,7 +9,7 @@
  * Released under GNU GPL, read the file 'COPYING' for more information
  */
 
-#include <glib/gmessages.h>
+#include <glib.h>
 
 #include "libnr/nr-pixblock.h"
 #include "display/nr-3dutils.h"
diff -urEw inkscape-0.48.2/src/display/nr-arena.h ./src/display/nr-arena.h
--- inkscape-0.48.2/src/display/nr-arena.h	2012-09-12 00:50:23.000000000 -0400
+++ ./src/display/nr-arena.h	2012-09-11 16:14:10.000000000 -0400
@@ -13,7 +13,7 @@
  * Released under GNU GPL, read the file 'COPYING' for more information
  */
 
-#include <glib/gmacros.h>
+#include <glib.h>
 
 #include "display/rendermode.h"
 
diff -urEw inkscape-0.48.2/src/display/nr-filter-diffuselighting.cpp ./src/display/nr-filter-diffuselighting.cpp
--- inkscape-0.48.2/src/display/nr-filter-diffuselighting.cpp	2012-09-12 00:50:23.000000000 -0400
+++ ./src/display/nr-filter-diffuselighting.cpp	2012-09-11 16:41:59.000000000 -0400
@@ -10,7 +10,7 @@
  * Released under GNU GPL, read the file 'COPYING' for more information
  */
 
-#include <glib/gmessages.h>
+#include <glib.h>
 
 #include "display/nr-3dutils.h"
 #include "display/nr-arena-item.h"
diff -urEw inkscape-0.48.2/src/display/nr-filter-gaussian.cpp ./src/display/nr-filter-gaussian.cpp
--- inkscape-0.48.2/src/display/nr-filter-gaussian.cpp	2012-09-12 00:50:23.000000000 -0400
+++ ./src/display/nr-filter-gaussian.cpp	2012-09-11 16:57:59.000000000 -0400
@@ -708,22 +708,22 @@
         };
     } else if ( scr_len_x > 0 ) { // !use_IIR_x
         // Filter kernel for x direction
-        FIRValue kernel[scr_len_x+1];
-        _make_kernel(kernel, deviation_x);
+        std::vector<FIRValue> kernel(scr_len_x + 1);
+        _make_kernel(&kernel[0], deviation_x);
 
         // Filter (x)
         switch(in->mode) {
         case NR_PIXBLOCK_MODE_A8:        ///< Grayscale
-            filter2D_FIR<unsigned char,1>(NR_PIXBLOCK_PX(out), 1, out->rs, NR_PIXBLOCK_PX(ssin), 1, ssin->rs, width, height, kernel, scr_len_x, NTHREADS);
+            filter2D_FIR<unsigned char,1>(NR_PIXBLOCK_PX(out), 1, out->rs, NR_PIXBLOCK_PX(ssin), 1, ssin->rs, width, height, &kernel[0], scr_len_x, NTHREADS);
             break;
         case NR_PIXBLOCK_MODE_R8G8B8:    ///< 8 bit RGB
-            filter2D_FIR<unsigned char,3>(NR_PIXBLOCK_PX(out), 3, out->rs, NR_PIXBLOCK_PX(ssin), 3, ssin->rs, width, height, kernel, scr_len_x, NTHREADS);
+            filter2D_FIR<unsigned char,3>(NR_PIXBLOCK_PX(out), 3, out->rs, NR_PIXBLOCK_PX(ssin), 3, ssin->rs, width, height, &kernel[0], scr_len_x, NTHREADS);
             break;
         //case NR_PIXBLOCK_MODE_R8G8B8A8N: ///< Normal 8 bit RGBA
-        //    filter2D_FIR<unsigned char,4>(NR_PIXBLOCK_PX(out), 4, out->rs, NR_PIXBLOCK_PX(ssin), 4, ssin->rs, width, height, kernel, scr_len_x, NTHREADS);
+        //    filter2D_FIR<unsigned char,4>(NR_PIXBLOCK_PX(out), 4, out->rs, NR_PIXBLOCK_PX(ssin), 4, ssin->rs, width, height, &kernel[0], scr_len_x, NTHREADS);
         //    break;
         case NR_PIXBLOCK_MODE_R8G8B8A8P: ///< Premultiplied 8 bit RGBA
-            filter2D_FIR<unsigned char,4>(NR_PIXBLOCK_PX(out), 4, out->rs, NR_PIXBLOCK_PX(ssin), 4, ssin->rs, width, height, kernel, scr_len_x, NTHREADS);
+            filter2D_FIR<unsigned char,4>(NR_PIXBLOCK_PX(out), 4, out->rs, NR_PIXBLOCK_PX(ssin), 4, ssin->rs, width, height, &kernel[0], scr_len_x, NTHREADS);
             break;
         default:
             assert(false);
@@ -770,22 +770,22 @@
         };
     } else if ( scr_len_y > 0 ) { // !use_IIR_y
         // Filter kernel for y direction
-        FIRValue kernel[scr_len_y+1];
-        _make_kernel(kernel, deviation_y);
+        std::vector<FIRValue> kernel(scr_len_y + 1);
+        _make_kernel(&kernel[0], deviation_y);
 
         // Filter (y)
         switch(in->mode) {
         case NR_PIXBLOCK_MODE_A8:        ///< Grayscale
-            filter2D_FIR<unsigned char,1>(NR_PIXBLOCK_PX(out), out->rs, 1, NR_PIXBLOCK_PX(out), out->rs, 1, height, width, kernel, scr_len_y, NTHREADS);
+            filter2D_FIR<unsigned char,1>(NR_PIXBLOCK_PX(out), out->rs, 1, NR_PIXBLOCK_PX(out), out->rs, 1, height, width, &kernel[0], scr_len_y, NTHREADS);
             break;
         case NR_PIXBLOCK_MODE_R8G8B8:    ///< 8 bit RGB
-            filter2D_FIR<unsigned char,3>(NR_PIXBLOCK_PX(out), out->rs, 3, NR_PIXBLOCK_PX(out), out->rs, 3, height, width, kernel, scr_len_y, NTHREADS);
+            filter2D_FIR<unsigned char,3>(NR_PIXBLOCK_PX(out), out->rs, 3, NR_PIXBLOCK_PX(out), out->rs, 3, height, width, &kernel[0], scr_len_y, NTHREADS);
             break;
         //case NR_PIXBLOCK_MODE_R8G8B8A8N: ///< Normal 8 bit RGBA
-        //    filter2D_FIR<unsigned char,4>(NR_PIXBLOCK_PX(out), out->rs, 4, NR_PIXBLOCK_PX(out), out->rs, 4, height, width, kernel, scr_len_y, NTHREADS);
+        //    filter2D_FIR<unsigned char,4>(NR_PIXBLOCK_PX(out), out->rs, 4, NR_PIXBLOCK_PX(out), out->rs, 4, height, width, &kernel[0], scr_len_y, NTHREADS);
         //    break;
         case NR_PIXBLOCK_MODE_R8G8B8A8P: ///< Premultiplied 8 bit RGBA
-            filter2D_FIR<unsigned char,4>(NR_PIXBLOCK_PX(out), out->rs, 4, NR_PIXBLOCK_PX(out), out->rs, 4, height, width, kernel, scr_len_y, NTHREADS);
+            filter2D_FIR<unsigned char,4>(NR_PIXBLOCK_PX(out), out->rs, 4, NR_PIXBLOCK_PX(out), out->rs, 4, height, width, &kernel[0], scr_len_y, NTHREADS);
             break;
         default:
             assert(false);
diff -urEw inkscape-0.48.2/src/display/nr-filter-specularlighting.cpp ./src/display/nr-filter-specularlighting.cpp
--- inkscape-0.48.2/src/display/nr-filter-specularlighting.cpp	2012-09-12 00:50:23.000000000 -0400
+++ ./src/display/nr-filter-specularlighting.cpp	2012-09-11 16:41:59.000000000 -0400
@@ -10,7 +10,7 @@
  * Released under GNU GPL, read the file 'COPYING' for more information
  */
 
-#include <glib/gmessages.h>
+#include <glib.h>
 #include <cmath>
 
 #include "display/nr-3dutils.h"
diff -urEw inkscape-0.48.2/src/display/nr-plain-stuff.cpp ./src/display/nr-plain-stuff.cpp
--- inkscape-0.48.2/src/display/nr-plain-stuff.cpp	2012-09-12 00:50:23.000000000 -0400
+++ ./src/display/nr-plain-stuff.cpp	2012-09-11 16:41:59.000000000 -0400
@@ -11,7 +11,7 @@
  * Released under GNU GPL
  */
 
-#include <glib/gmessages.h>
+#include <glib.h>
 #include <libnr/nr-pixops.h>
 #include "nr-plain-stuff.h"
 
diff -urEw inkscape-0.48.2/src/display/nr-plain-stuff.h ./src/display/nr-plain-stuff.h
--- inkscape-0.48.2/src/display/nr-plain-stuff.h	2012-09-12 00:50:23.000000000 -0400
+++ ./src/display/nr-plain-stuff.h	2012-09-11 16:14:10.000000000 -0400
@@ -12,7 +12,7 @@
  * Released under GNU GPL
  */
 
-#include <glib/gtypes.h>
+#include <glib.h>
 
 void nr_render_checkerboard_rgb (guchar *px, gint w, gint h, gint rs, gint xoff, gint yoff);
 void nr_render_checkerboard_rgb_custom (guchar *px, gint w, gint h, gint rs, gint xoff, gint yoff, guint32 c0, guint32 c1, gint sizep2);
diff -urEw inkscape-0.48.2/src/display/sodipodi-ctrlrect.h ./src/display/sodipodi-ctrlrect.h
--- inkscape-0.48.2/src/display/sodipodi-ctrlrect.h	2012-09-12 00:50:23.000000000 -0400
+++ ./src/display/sodipodi-ctrlrect.h	2012-09-11 16:14:10.000000000 -0400
@@ -16,7 +16,7 @@
  *
  */
 
-#include <glib/gtypes.h>
+#include <glib.h>
 #include "sp-canvas.h"
 
 #define SP_TYPE_CTRLRECT (sp_ctrlrect_get_type ())
diff -urEw inkscape-0.48.2/src/display/sp-canvas.h ./src/display/sp-canvas.h
--- inkscape-0.48.2/src/display/sp-canvas.h	2012-09-12 00:50:23.000000000 -0400
+++ ./src/display/sp-canvas.h	2012-09-11 16:14:10.000000000 -0400
@@ -27,7 +27,7 @@
 # endif
 #endif
 
-#include <glib/gtypes.h>
+#include <glib.h>
 #include <gdk/gdk.h>
 #include <gtk/gtk.h>
 
diff -urEw inkscape-0.48.2/src/document-subset.cpp ./src/document-subset.cpp
--- inkscape-0.48.2/src/document-subset.cpp	2012-09-12 00:50:23.000000000 -0400
+++ ./src/document-subset.cpp	2012-09-11 16:41:59.000000000 -0400
@@ -12,7 +12,7 @@
 #include "document.h"
 #include "sp-object.h"
 
-#include <glib/gmessages.h>
+#include <glib.h>
 
 #include <sigc++/signal.h>
 #include <sigc++/functors/mem_fun.h>
diff -urEw inkscape-0.48.2/src/draw-anchor.h ./src/draw-anchor.h
--- inkscape-0.48.2/src/draw-anchor.h	2012-09-12 00:50:23.000000000 -0400
+++ ./src/draw-anchor.h	2012-09-11 16:14:10.000000000 -0400
@@ -5,7 +5,7 @@
  * Drawing anchors. 
  */
 
-#include <glib/gtypes.h>
+#include <glib.h>
 #include <2geom/point.h>
 
 struct SPDrawContext;
diff -urEw inkscape-0.48.2/src/dyna-draw-context.cpp ./src/dyna-draw-context.cpp
--- inkscape-0.48.2/src/dyna-draw-context.cpp	2012-09-12 00:50:23.000000000 -0400
+++ ./src/dyna-draw-context.cpp	2012-09-11 16:42:00.000000000 -0400
@@ -38,7 +38,7 @@
 #include <2geom/pathvector.h>
 #include <2geom/bezier-utils.h>
 #include "display/curve.h"
-#include <glib/gmem.h>
+#include <glib.h>
 #include "macros.h"
 #include "document.h"
 #include "selection.h"
diff -urEw inkscape-0.48.2/src/eraser-context.cpp ./src/eraser-context.cpp
--- inkscape-0.48.2/src/eraser-context.cpp	2012-09-12 00:50:23.000000000 -0400
+++ ./src/eraser-context.cpp	2012-09-11 16:42:00.000000000 -0400
@@ -36,7 +36,7 @@
 #include "display/canvas-bpath.h"
 #include <2geom/bezier-utils.h>
 
-#include <glib/gmem.h>
+#include <glib.h>
 #include "macros.h"
 #include "document.h"
 #include "selection.h"
diff -urEw inkscape-0.48.2/src/extension/internal/bitmap/imagemagick.cpp ./src/extension/internal/bitmap/imagemagick.cpp
--- inkscape-0.48.2/src/extension/internal/bitmap/imagemagick.cpp	2012-09-12 00:50:23.000000000 -0400
+++ ./src/extension/internal/bitmap/imagemagick.cpp	2012-09-11 16:42:00.000000000 -0400
@@ -15,7 +15,7 @@
 #include <gtkmm/spinbutton.h>
 #include <gtkmm.h>
 
-#include <glib/gstdio.h>
+#include <glib.h>
 
 #include "desktop.h"
 #include "desktop-handles.h"
diff -urEw inkscape-0.48.2/src/extension/internal/cairo-render-context.cpp ./src/extension/internal/cairo-render-context.cpp
--- inkscape-0.48.2/src/extension/internal/cairo-render-context.cpp	2012-09-12 00:50:23.000000000 -0400
+++ ./src/extension/internal/cairo-render-context.cpp	2012-09-11 16:42:00.000000000 -0400
@@ -29,7 +29,7 @@
 #include <errno.h>
 #include <2geom/pathvector.h>
 
-#include <glib/gmem.h>
+#include <glib.h>
 
 #include <glibmm/i18n.h>
 #include "display/nr-arena.h"
diff -urEw inkscape-0.48.2/src/extension/internal/cairo-renderer.cpp ./src/extension/internal/cairo-renderer.cpp
--- inkscape-0.48.2/src/extension/internal/cairo-renderer.cpp	2012-09-12 00:50:23.000000000 -0400
+++ ./src/extension/internal/cairo-renderer.cpp	2012-09-11 16:42:00.000000000 -0400
@@ -33,7 +33,7 @@
 #include <2geom/transforms.h>
 #include <2geom/pathvector.h>
 
-#include <glib/gmem.h>
+#include <glib.h>
 
 #include <glibmm/i18n.h>
 #include "display/nr-arena.h"
diff -urEw inkscape-0.48.2/src/extension/internal/gdkpixbuf-input.cpp ./src/extension/internal/gdkpixbuf-input.cpp
--- inkscape-0.48.2/src/extension/internal/gdkpixbuf-input.cpp	2012-09-12 00:50:23.000000000 -0400
+++ ./src/extension/internal/gdkpixbuf-input.cpp	2012-09-11 16:42:00.000000000 -0400
@@ -1,7 +1,7 @@
 #ifdef HAVE_CONFIG_H
 # include <config.h>
 #endif
-#include <glib/gprintf.h>
+#include <glib.h>
 #include <glibmm/i18n.h>
 #include "document-private.h"
 #include <dir-util.h>
diff -urEw inkscape-0.48.2/src/extension/internal/pdfinput/svg-builder.cpp ./src/extension/internal/pdfinput/svg-builder.cpp
--- inkscape-0.48.2/src/extension/internal/pdfinput/svg-builder.cpp	2012-09-12 00:50:23.000000000 -0400
+++ ./src/extension/internal/pdfinput/svg-builder.cpp	2012-09-11 17:00:30.000000000 -0400
@@ -1443,7 +1443,7 @@
         return NULL;
     }
     // Set error handler
-    if (setjmp(png_ptr->jmpbuf)) {
+    if (png_jmpbuf(png_ptr)) {
         png_destroy_write_struct(&png_ptr, &info_ptr);
         return NULL;
     }
diff -urEw inkscape-0.48.2/src/extension/internal/pdfinput/svg-builder.h ./src/extension/internal/pdfinput/svg-builder.h
--- inkscape-0.48.2/src/extension/internal/pdfinput/svg-builder.h	2012-09-12 00:50:23.000000000 -0400
+++ ./src/extension/internal/pdfinput/svg-builder.h	2012-09-11 16:14:11.000000000 -0400
@@ -49,7 +49,7 @@
 class SPCSSAttr;
 
 #include <vector>
-#include <glib/gtypes.h>
+#include <glib.h>
 
 namespace Inkscape {
 namespace Extension {
diff -urEw inkscape-0.48.2/src/extension/internal/win32.cpp ./src/extension/internal/win32.cpp
--- inkscape-0.48.2/src/extension/internal/win32.cpp	2012-09-12 00:50:23.000000000 -0400
+++ ./src/extension/internal/win32.cpp	2012-09-11 16:42:00.000000000 -0400
@@ -13,7 +13,7 @@
 # include "config.h"
 #endif
 
-#include <glib/gmem.h>
+#include <glib.h>
 #include <libnr/nr-macros.h>
 #include <2geom/transforms.h>
 
diff -urEw inkscape-0.48.2/src/extract-uri.h ./src/extract-uri.h
--- inkscape-0.48.2/src/extract-uri.h	2012-09-12 00:50:23.000000000 -0400
+++ ./src/extract-uri.h	2012-09-11 16:14:11.000000000 -0400
@@ -1,7 +1,7 @@
 #ifndef SEEN_EXTRACT_URI_H
 #define SEEN_EXTRACT_URI_H
 
-#include <glib/gtypes.h>
+#include <glib.h>
 
 gchar *extract_uri(gchar const *s, gchar const** endptr = 0);
 
diff -urEw inkscape-0.48.2/src/file.cpp ./src/file.cpp
--- inkscape-0.48.2/src/file.cpp	2012-09-12 00:50:23.000000000 -0400
+++ ./src/file.cpp	2012-09-11 16:42:00.000000000 -0400
@@ -27,7 +27,7 @@
 #endif
 
 #include <gtk/gtk.h>
-#include <glib/gmem.h>
+#include <glib.h>
 #include <glibmm/i18n.h>
 #include <libnr/nr-pixops.h>
 
diff -urEw inkscape-0.48.2/src/file.h ./src/file.h
--- inkscape-0.48.2/src/file.h	2012-09-12 00:50:23.000000000 -0400
+++ ./src/file.h	2012-09-11 16:14:11.000000000 -0400
@@ -16,7 +16,7 @@
  */
 
 #include <gtkmm.h>
-#include <glib/gslist.h>
+#include <glib.h>
 #include <gtk/gtk.h>
 
 #include "extension/extension-forward.h"
diff -urEw inkscape-0.48.2/src/filters/blend-fns.h ./src/filters/blend-fns.h
--- inkscape-0.48.2/src/filters/blend-fns.h	2012-09-12 00:50:23.000000000 -0400
+++ ./src/filters/blend-fns.h	2012-09-11 16:14:11.000000000 -0400
@@ -6,7 +6,7 @@
  */
 
 #include <glib-object.h>
-#include <glib/gtypes.h>
+#include <glib.h>
 
 namespace Inkscape {
 namespace XML {
diff -urEw inkscape-0.48.2/src/filters/colormatrix-fns.h ./src/filters/colormatrix-fns.h
--- inkscape-0.48.2/src/filters/colormatrix-fns.h	2012-09-12 00:50:23.000000000 -0400
+++ ./src/filters/colormatrix-fns.h	2012-09-11 16:14:11.000000000 -0400
@@ -6,7 +6,7 @@
  */
 
 #include <glib-object.h>
-#include <glib/gtypes.h>
+#include <glib.h>
 
 namespace Inkscape {
 namespace XML {
diff -urEw inkscape-0.48.2/src/filters/componenttransfer-fns.h ./src/filters/componenttransfer-fns.h
--- inkscape-0.48.2/src/filters/componenttransfer-fns.h	2012-09-12 00:50:23.000000000 -0400
+++ ./src/filters/componenttransfer-fns.h	2012-09-11 16:14:11.000000000 -0400
@@ -6,7 +6,7 @@
  */
 
 #include <glib-object.h>
-#include <glib/gtypes.h>
+#include <glib.h>
 
 namespace Inkscape {
 namespace XML {
diff -urEw inkscape-0.48.2/src/filters/composite-fns.h ./src/filters/composite-fns.h
--- inkscape-0.48.2/src/filters/composite-fns.h	2012-09-12 00:50:23.000000000 -0400
+++ ./src/filters/composite-fns.h	2012-09-11 16:14:11.000000000 -0400
@@ -6,7 +6,7 @@
  */
 
 #include <glib-object.h>
-#include <glib/gtypes.h>
+#include <glib.h>
 
 namespace Inkscape {
 namespace XML {
diff -urEw inkscape-0.48.2/src/filters/convolvematrix-fns.h ./src/filters/convolvematrix-fns.h
--- inkscape-0.48.2/src/filters/convolvematrix-fns.h	2012-09-12 00:50:23.000000000 -0400
+++ ./src/filters/convolvematrix-fns.h	2012-09-11 16:14:11.000000000 -0400
@@ -6,7 +6,7 @@
  */
 
 #include <glib-object.h>
-#include <glib/gtypes.h>
+#include <glib.h>
 
 namespace Inkscape {
 namespace XML {
diff -urEw inkscape-0.48.2/src/filters/diffuselighting-fns.h ./src/filters/diffuselighting-fns.h
--- inkscape-0.48.2/src/filters/diffuselighting-fns.h	2012-09-12 00:50:23.000000000 -0400
+++ ./src/filters/diffuselighting-fns.h	2012-09-11 16:14:11.000000000 -0400
@@ -6,7 +6,7 @@
  */
 
 #include <glib-object.h>
-#include <glib/gtypes.h>
+#include <glib.h>
 
 namespace Inkscape {
 namespace XML {
diff -urEw inkscape-0.48.2/src/filters/displacementmap-fns.h ./src/filters/displacementmap-fns.h
--- inkscape-0.48.2/src/filters/displacementmap-fns.h	2012-09-12 00:50:23.000000000 -0400
+++ ./src/filters/displacementmap-fns.h	2012-09-11 16:14:11.000000000 -0400
@@ -6,7 +6,7 @@
  */
 
 #include <glib-object.h>
-#include <glib/gtypes.h>
+#include <glib.h>
 
 namespace Inkscape {
 namespace XML {
diff -urEw inkscape-0.48.2/src/filters/flood-fns.h ./src/filters/flood-fns.h
--- inkscape-0.48.2/src/filters/flood-fns.h	2012-09-12 00:50:23.000000000 -0400
+++ ./src/filters/flood-fns.h	2012-09-11 16:14:11.000000000 -0400
@@ -6,7 +6,7 @@
  */
 
 #include <glib-object.h>
-#include <glib/gtypes.h>
+#include <glib.h>
 
 namespace Inkscape {
 namespace XML {
diff -urEw inkscape-0.48.2/src/filters/image-fns.h ./src/filters/image-fns.h
--- inkscape-0.48.2/src/filters/image-fns.h	2012-09-12 00:50:23.000000000 -0400
+++ ./src/filters/image-fns.h	2012-09-11 16:14:11.000000000 -0400
@@ -6,7 +6,7 @@
  */
 
 #include <glib-object.h>
-#include <glib/gtypes.h>
+#include <glib.h>
 
 namespace Inkscape {
 namespace XML {
diff -urEw inkscape-0.48.2/src/filters/merge-fns.h ./src/filters/merge-fns.h
--- inkscape-0.48.2/src/filters/merge-fns.h	2012-09-12 00:50:23.000000000 -0400
+++ ./src/filters/merge-fns.h	2012-09-11 16:14:11.000000000 -0400
@@ -6,7 +6,7 @@
  */
 
 #include <glib-object.h>
-#include <glib/gtypes.h>
+#include <glib.h>
 
 namespace Inkscape {
 namespace XML {
diff -urEw inkscape-0.48.2/src/filters/morphology-fns.h ./src/filters/morphology-fns.h
--- inkscape-0.48.2/src/filters/morphology-fns.h	2012-09-12 00:50:23.000000000 -0400
+++ ./src/filters/morphology-fns.h	2012-09-11 16:14:11.000000000 -0400
@@ -6,7 +6,7 @@
  */
 
 #include <glib-object.h>
-#include <glib/gtypes.h>
+#include <glib.h>
 
 namespace Inkscape {
 namespace XML {
diff -urEw inkscape-0.48.2/src/filters/offset-fns.h ./src/filters/offset-fns.h
--- inkscape-0.48.2/src/filters/offset-fns.h	2012-09-12 00:50:23.000000000 -0400
+++ ./src/filters/offset-fns.h	2012-09-11 16:14:11.000000000 -0400
@@ -6,7 +6,7 @@
  */
 
 #include <glib-object.h>
-#include <glib/gtypes.h>
+#include <glib.h>
 
 namespace Inkscape {
 namespace XML {
diff -urEw inkscape-0.48.2/src/filters/specularlighting-fns.h ./src/filters/specularlighting-fns.h
--- inkscape-0.48.2/src/filters/specularlighting-fns.h	2012-09-12 00:50:23.000000000 -0400
+++ ./src/filters/specularlighting-fns.h	2012-09-11 16:14:11.000000000 -0400
@@ -6,7 +6,7 @@
  */
 
 #include <glib-object.h>
-#include <glib/gtypes.h>
+#include <glib.h>
 
 namespace Inkscape {
 namespace XML {
diff -urEw inkscape-0.48.2/src/filters/tile-fns.h ./src/filters/tile-fns.h
--- inkscape-0.48.2/src/filters/tile-fns.h	2012-09-12 00:50:23.000000000 -0400
+++ ./src/filters/tile-fns.h	2012-09-11 16:14:11.000000000 -0400
@@ -6,7 +6,7 @@
  */
 
 #include <glib-object.h>
-#include <glib/gtypes.h>
+#include <glib.h>
 
 namespace Inkscape {
 namespace XML {
diff -urEw inkscape-0.48.2/src/filters/turbulence-fns.h ./src/filters/turbulence-fns.h
--- inkscape-0.48.2/src/filters/turbulence-fns.h	2012-09-12 00:50:23.000000000 -0400
+++ ./src/filters/turbulence-fns.h	2012-09-11 16:14:11.000000000 -0400
@@ -6,7 +6,7 @@
  */
 
 #include <glib-object.h>
-#include <glib/gtypes.h>
+#include <glib.h>
 
 namespace Inkscape {
 namespace XML {
diff -urEw inkscape-0.48.2/src/gc-anchored.h ./src/gc-anchored.h
--- inkscape-0.48.2/src/gc-anchored.h	2012-09-12 00:50:23.000000000 -0400
+++ ./src/gc-anchored.h	2012-09-11 16:14:11.000000000 -0400
@@ -11,7 +11,8 @@
 #ifndef SEEN_INKSCAPE_GC_ANCHORED_H
 #define SEEN_INKSCAPE_GC_ANCHORED_H
 
-#include <glib/gmessages.h>
+#define GLIB_COMPILATION
+#include <glib.h>
 #include "gc-managed.h"
 
 namespace Inkscape {
diff -urEw inkscape-0.48.2/src/gc-core.h ./src/gc-core.h
--- inkscape-0.48.2/src/gc-core.h	2012-09-12 00:50:23.000000000 -0400
+++ ./src/gc-core.h	2012-09-11 16:14:11.000000000 -0400
@@ -24,7 +24,8 @@
 #else
 # include <gc.h>
 #endif
-#include <glib/gmain.h>
+#define GLIB_COMPILATION
+#include <glib.h>
 
 namespace Inkscape {
 namespace GC {
diff -urEw inkscape-0.48.2/src/gc.cpp ./src/gc.cpp
--- inkscape-0.48.2/src/gc.cpp	2012-09-12 00:50:23.000000000 -0400
+++ ./src/gc.cpp	2012-09-11 16:42:00.000000000 -0400
@@ -13,7 +13,7 @@
 #include <stdexcept>
 #include <cstring>
 #include <string>
-#include <glib/gmessages.h>
+#include <glib.h>
 #include <sigc++/functors/ptr_fun.h>
 #include <glibmm/main.h>
 #include <cstddef>
diff -urEw inkscape-0.48.2/src/gradient-drag.h ./src/gradient-drag.h
--- inkscape-0.48.2/src/gradient-drag.h	2012-09-12 00:50:23.000000000 -0400
+++ ./src/gradient-drag.h	2012-09-11 16:14:11.000000000 -0400
@@ -14,7 +14,7 @@
  * Released under GNU GPL, read the file 'COPYING' for more information
  */
 
-#include <glib/gslist.h>
+#include <glib.h>
 #include <stddef.h>
 #include <sigc++/sigc++.h>
 #include <vector>
diff -urEw inkscape-0.48.2/src/graphlayout.cpp ./src/graphlayout.cpp
--- inkscape-0.48.2/src/graphlayout.cpp	2012-09-12 00:50:23.000000000 -0400
+++ ./src/graphlayout.cpp	2012-09-11 16:42:00.000000000 -0400
@@ -155,11 +155,12 @@
          ++i)
     {
         SPItem *iu=*i;
-        map<string,unsigned>::iterator i=nodelookup.find(iu->getId());
-        if(i==nodelookup.end()) {
+        map<string,unsigned>::iterator i_iter=nodelookup.find(iu->getId());
+        map<string,unsigned>::iterator i_iter_end=nodelookup.end();
+        if(i_iter==i_iter_end) {
             continue;
         }
-        unsigned u=i->second;
+        unsigned u=i_iter->second;
         GSList *nlist=iu->avoidRef->getAttachedConnectors(Avoid::runningFrom);
         list<SPItem *> connectors;
 
diff -urEw inkscape-0.48.2/src/help.h ./src/help.h
--- inkscape-0.48.2/src/help.h	2012-09-12 00:50:23.000000000 -0400
+++ ./src/help.h	2012-09-11 16:14:11.000000000 -0400
@@ -13,7 +13,7 @@
  * Released under GNU GPL, read the file 'COPYING' for more information
  */
 
-#include <glib/gtypes.h>
+#include <glib.h>
 #include <gtk/gtk.h>
 
 void sp_help_about(void);
diff -urEw inkscape-0.48.2/src/helper/gnome-utils.h ./src/helper/gnome-utils.h
--- inkscape-0.48.2/src/helper/gnome-utils.h	2012-09-12 00:50:23.000000000 -0400
+++ ./src/helper/gnome-utils.h	2012-09-11 16:14:11.000000000 -0400
@@ -15,8 +15,8 @@
 #ifndef __GNOME_UTILS_H__
 #define __GNOME_UTILS_H__
 
-#include <glib/gtypes.h>
-#include <glib/glist.h>
+#include <glib.h>
+#include <glib.h>
 
 GList *gnome_uri_list_extract_uris(gchar const *uri_list);
 
diff -urEw inkscape-0.48.2/src/helper/pixbuf-ops.cpp ./src/helper/pixbuf-ops.cpp
--- inkscape-0.48.2/src/helper/pixbuf-ops.cpp	2012-09-12 00:50:23.000000000 -0400
+++ ./src/helper/pixbuf-ops.cpp	2012-09-11 16:42:00.000000000 -0400
@@ -18,7 +18,7 @@
 #include <interface.h>
 #include <libnr/nr-pixops.h>
 #include <glib.h>
-#include <glib/gmessages.h>
+#include <glib.h>
 #include <png.h>
 #include "png-write.h"
 #include <display/nr-arena-item.h>
diff -urEw inkscape-0.48.2/src/helper/pixbuf-ops.h ./src/helper/pixbuf-ops.h
--- inkscape-0.48.2/src/helper/pixbuf-ops.h	2012-09-12 00:50:23.000000000 -0400
+++ ./src/helper/pixbuf-ops.h	2012-09-11 16:14:11.000000000 -0400
@@ -12,7 +12,7 @@
  * Released under GNU GPL, read the file 'COPYING' for more information
  */
 
-#include <glib/gtypes.h>
+#include <glib.h>
 
 struct SPDocument;
 
diff -urEw inkscape-0.48.2/src/helper/png-write.cpp ./src/helper/png-write.cpp
--- inkscape-0.48.2/src/helper/png-write.cpp	2012-09-12 00:50:23.000000000 -0400
+++ ./src/helper/png-write.cpp	2012-09-11 16:42:00.000000000 -0400
@@ -20,7 +20,7 @@
 #include <libnr/nr-pixops.h>
 #include <libnr/nr-translate-scale-ops.h>
 #include <2geom/rect.h>
-#include <glib/gmessages.h>
+#include <glib.h>
 #include <png.h>
 #include "png-write.h"
 #include "io/sys.h"
@@ -165,7 +165,7 @@
     /* Set error handling.  REQUIRED if you aren't supplying your own
      * error hadnling functions in the png_create_write_struct() call.
      */
-    if (setjmp(png_ptr->jmpbuf)) {
+    if (png_jmpbuf(png_ptr)) {
         /* If we get here, we had a problem reading the file */
         fclose(fp);
         png_destroy_write_struct(&png_ptr, &info_ptr);
diff -urEw inkscape-0.48.2/src/helper/png-write.h ./src/helper/png-write.h
--- inkscape-0.48.2/src/helper/png-write.h	2012-09-12 00:50:23.000000000 -0400
+++ ./src/helper/png-write.h	2012-09-11 16:14:11.000000000 -0400
@@ -12,7 +12,7 @@
  * Released under GNU GPL, read the file 'COPYING' for more information
  */
 
-#include <glib/gtypes.h>
+#include <glib.h>
 #include <2geom/forward.h>
 struct SPDocument;
 
diff -urEw inkscape-0.48.2/src/helper/sp-marshal.cpp ./src/helper/sp-marshal.cpp
--- inkscape-0.48.2/src/helper/sp-marshal.cpp	2012-09-12 00:50:23.000000000 -0400
+++ ./src/helper/sp-marshal.cpp	2012-09-11 16:42:00.000000000 -0400
@@ -5,7 +5,7 @@
 
 #ifdef G_ENABLE_DEBUG
 #define g_marshal_value_peek_boolean(v)  g_value_get_boolean (v)
-#define g_marshal_value_peek_char(v)     g_value_get_char (v)
+#define g_marshal_value_peek_char(v)     g_value_get_schar (v)
 #define g_marshal_value_peek_uchar(v)    g_value_get_uchar (v)
 #define g_marshal_value_peek_int(v)      g_value_get_int (v)
 #define g_marshal_value_peek_uint(v)     g_value_get_uint (v)
diff -urEw inkscape-0.48.2/src/helper/stlport.h ./src/helper/stlport.h
--- inkscape-0.48.2/src/helper/stlport.h	2012-09-12 00:50:23.000000000 -0400
+++ ./src/helper/stlport.h	2012-09-11 16:14:11.000000000 -0400
@@ -3,8 +3,8 @@
 
 
 #include <list>
-#include <glib/glist.h>
-#include <glib/gslist.h>
+#include <glib.h>
+#include <glib.h>
 
 template <typename T>
 class StlConv {
diff -urEw inkscape-0.48.2/src/helper/stock-items.h ./src/helper/stock-items.h
--- inkscape-0.48.2/src/helper/stock-items.h	2012-09-12 00:50:23.000000000 -0400
+++ ./src/helper/stock-items.h	2012-09-11 16:14:11.000000000 -0400
@@ -12,7 +12,7 @@
  *
  */
 
-#include <glib/gtypes.h>
+#include <glib.h>
 
 #include <forward.h>
 
diff -urEw inkscape-0.48.2/src/helper/unit-menu.h ./src/helper/unit-menu.h
--- inkscape-0.48.2/src/helper/unit-menu.h	2012-09-12 00:50:23.000000000 -0400
+++ ./src/helper/unit-menu.h	2012-09-11 16:14:11.000000000 -0400
@@ -10,7 +10,7 @@
  *
  */
 
-#include <glib/gtypes.h>
+#include <glib.h>
 #include <gtk/gtk.h>
 
 #include <helper/helper-forward.h>
diff -urEw inkscape-0.48.2/src/helper/units.h ./src/helper/units.h
--- inkscape-0.48.2/src/helper/units.h	2012-09-12 00:50:23.000000000 -0400
+++ ./src/helper/units.h	2012-09-11 16:14:11.000000000 -0400
@@ -14,10 +14,11 @@
  * Copyright 1999-2001 Ximian, Inc. and authors
  *
  */
+#include "config.h"
 
-#include <glib/gmessages.h>
-#include <glib/gslist.h>
-#include <glib/gtypes.h>
+#include <glib.h>
+#include <glib.h>
+#include <glib.h>
 #include "sp-metric.h"
 
 
diff -urEw inkscape-0.48.2/src/inkscape.cpp ./src/inkscape.cpp
--- inkscape-0.48.2/src/inkscape.cpp	2012-09-12 00:50:23.000000000 -0400
+++ ./src/inkscape.cpp	2012-09-11 16:43:55.000000000 -0400
@@ -37,8 +37,8 @@
 #endif
 
 #include <cstring>
-#include <glib/gstdio.h>
 #include <glib.h>
+#include <glib/gstdio.h>
 #include <glibmm/i18n.h>
 #include <gtk/gtk.h>
 #include <gtkmm/messagedialog.h>
diff -urEw inkscape-0.48.2/src/inkscape.h ./src/inkscape.h
--- inkscape-0.48.2/src/inkscape.h	2012-09-12 00:50:23.000000000 -0400
+++ ./src/inkscape.h	2012-09-11 16:14:11.000000000 -0400
@@ -13,7 +13,7 @@
  */
 
 #include <list>
-#include <glib/gtypes.h>
+#include <glib.h>
 
 struct SPDesktop;
 struct SPDocument;
diff -urEw inkscape-0.48.2/src/inkview.cpp ./src/inkview.cpp
--- inkscape-0.48.2/src/inkview.cpp	2012-09-12 00:50:23.000000000 -0400
+++ ./src/inkview.cpp	2012-09-11 16:42:01.000000000 -0400
@@ -39,7 +39,7 @@
 #include <sys/stat.h>
 #include <locale.h>
 
-#include <glib/gmem.h>
+#include <glib.h>
 #include <libnr/nr-macros.h>
 
 // #include <stropts.h>
diff -urEw inkscape-0.48.2/src/io/inkjar.h ./src/io/inkjar.h
--- inkscape-0.48.2/src/io/inkjar.h	2012-09-12 00:50:23.000000000 -0400
+++ ./src/io/inkjar.h	2012-09-11 16:14:11.000000000 -0400
@@ -26,8 +26,8 @@
 # endif
 #endif
 
-#include <glib/garray.h>
-#include <glib/gtypes.h>
+#include <glib.h>
+#include <glib.h>
 
 namespace Inkjar {
 
diff -urEw inkscape-0.48.2/src/io/resource.cpp ./src/io/resource.cpp
--- inkscape-0.48.2/src/io/resource.cpp	2012-09-12 00:50:23.000000000 -0400
+++ ./src/io/resource.cpp	2012-09-11 16:42:01.000000000 -0400
@@ -17,9 +17,9 @@
 #endif
 
 #include <glib.h> // g_assert()
-#include <glib/gmessages.h>
-#include <glib/gstrfuncs.h>
-#include <glib/gfileutils.h>
+#include <glib.h>
+#include <glib.h>
+#include <glib.h>
 #include "path-prefix.h"
 #include "inkscape.h"
 #include "io/resource.h"
diff -urEw inkscape-0.48.2/src/io/sys.cpp ./src/io/sys.cpp
--- inkscape-0.48.2/src/io/sys.cpp	2012-09-12 00:50:23.000000000 -0400
+++ ./src/io/sys.cpp	2012-09-11 17:01:13.000000000 -0400
@@ -17,10 +17,9 @@
 
 #include <glib.h>
 #include <glib/gstdio.h>
-#include <glib/gutils.h>
 #include <glibmm/fileutils.h>
 #if GLIB_CHECK_VERSION(2,6,0)
-    #include <glib/gstdio.h>
+    #include <glib.h>
 #endif
 #include <glibmm/ustring.h>
 #include <gtk/gtk.h>
diff -urEw inkscape-0.48.2/src/io/sys.h ./src/io/sys.h
--- inkscape-0.48.2/src/io/sys.h	2012-09-12 00:50:23.000000000 -0400
+++ ./src/io/sys.h	2012-09-11 16:14:11.000000000 -0400
@@ -15,9 +15,9 @@
 #include <stdio.h>
 #include <sys/stat.h>
 #include <sys/types.h>
-#include <glib/gtypes.h>
-#include <glib/gdir.h>
-#include <glib/gfileutils.h>
+#include <glib.h>
+#include <glib.h>
+#include <glib.h>
 #include <glibmm/spawn.h>
 #include <string>
 
diff -urEw inkscape-0.48.2/src/knot-holder-entity.h ./src/knot-holder-entity.h
--- inkscape-0.48.2/src/knot-holder-entity.h	2012-09-12 00:50:23.000000000 -0400
+++ ./src/knot-holder-entity.h	2012-09-11 16:14:11.000000000 -0400
@@ -17,7 +17,7 @@
  * Released under GNU GPL
  */
 
-#include <glib/gtypes.h>
+#include <glib.h>
 #include "knot.h"
 #include <2geom/forward.h>
 #include "snapper.h"
diff -urEw inkscape-0.48.2/src/knotholder.h ./src/knotholder.h
--- inkscape-0.48.2/src/knotholder.h	2012-09-12 00:50:23.000000000 -0400
+++ ./src/knotholder.h	2012-09-11 16:14:11.000000000 -0400
@@ -17,7 +17,7 @@
  *
  */
 
-#include <glib/gtypes.h>
+#include <glib.h>
 #include "knot-enums.h"
 #include "forward.h"
 #include "libnr/nr-forward.h"
diff -urEw inkscape-0.48.2/src/libcola/shortest_paths.cpp ./src/libcola/shortest_paths.cpp
--- inkscape-0.48.2/src/libcola/shortest_paths.cpp	2012-09-12 00:50:23.000000000 -0400
+++ ./src/libcola/shortest_paths.cpp	2012-09-11 17:09:21.000000000 -0400
@@ -81,9 +81,9 @@
         double* eweights)
 {
     assert(s<n);
-    Node vs[n];
-    dijkstra_init(vs,es,eweights);
-    dijkstra(s,n,vs,d);
+    std::vector<Node> vs(n);
+    dijkstra_init(&vs[0],es,eweights);
+    dijkstra(s,n,&vs[0],d);
 }
 void johnsons(
         unsigned n,
@@ -91,10 +91,10 @@
         vector<Edge>& es,
         double* eweights) 
 {
-    Node vs[n];
-    dijkstra_init(vs,es,eweights);
+    std::vector<Node> vs(n);
+    dijkstra_init(&vs[0],es,eweights);
     for(unsigned k=0;k<n;k++) {
-        dijkstra(k,n,vs,D[k]);
+        dijkstra(k,n,&vs[0],D[k]);
     }
 }
 }
diff -urEw inkscape-0.48.2/src/libcroco/cr-libxml-node-iface.h ./src/libcroco/cr-libxml-node-iface.h
--- inkscape-0.48.2/src/libcroco/cr-libxml-node-iface.h	2012-09-12 00:50:23.000000000 -0400
+++ ./src/libcroco/cr-libxml-node-iface.h	2012-09-11 16:14:11.000000000 -0400
@@ -1,7 +1,7 @@
 #ifndef __CR_LIBXML_NODE_IFACE_H__
 #define __CR_LIBXML_NODE_IFACE_H__
 
-#include <glib/gmacros.h>
+#include <glib.h>
 #include "cr-node-iface.h"
 
 G_BEGIN_DECLS
diff -urEw inkscape-0.48.2/src/libcroco/cr-node-iface.h ./src/libcroco/cr-node-iface.h
--- inkscape-0.48.2/src/libcroco/cr-node-iface.h	2012-09-12 00:50:23.000000000 -0400
+++ ./src/libcroco/cr-node-iface.h	2012-09-11 16:14:11.000000000 -0400
@@ -1,8 +1,8 @@
 #ifndef __CR_NODE_IFACE_H__
 #define __CR_NODE_IFACE_H__
 
-#include <glib/gmacros.h>
-#include <glib/gtypes.h>
+#include <glib.h>
+#include <glib.h>
 
 G_BEGIN_DECLS
 
diff -urEw inkscape-0.48.2/src/libgdl/gdl-stock.h ./src/libgdl/gdl-stock.h
--- inkscape-0.48.2/src/libgdl/gdl-stock.h	2012-09-12 00:50:23.000000000 -0400
+++ ./src/libgdl/gdl-stock.h	2012-09-11 16:14:12.000000000 -0400
@@ -22,7 +22,7 @@
 #ifndef __GDL_STOCK_H__
 #define __GDL_STOCK_H__
 
-#include <glib/gmacros.h>   // G_BEGIN_DECLS
+#include <glib.h>   // G_BEGIN_DECLS
 
 G_BEGIN_DECLS
 
diff -urEw inkscape-0.48.2/src/libnr/in-svg-plane-test.h ./src/libnr/in-svg-plane-test.h
--- inkscape-0.48.2/src/libnr/in-svg-plane-test.h	2012-09-12 00:50:23.000000000 -0400
+++ ./src/libnr/in-svg-plane-test.h	2012-09-11 16:14:12.000000000 -0400
@@ -1,6 +1,6 @@
 #include <cxxtest/TestSuite.h>
 
-#include <glib/gmacros.h>
+#include <glib.h>
 #include <cmath>
 
 #include "libnr/in-svg-plane.h"
diff -urEw inkscape-0.48.2/src/libnr/nr-gradient.cpp ./src/libnr/nr-gradient.cpp
--- inkscape-0.48.2/src/libnr/nr-gradient.cpp	2012-09-12 00:50:23.000000000 -0400
+++ ./src/libnr/nr-gradient.cpp	2012-09-11 16:42:01.000000000 -0400
@@ -26,7 +26,7 @@
 #include <libnr/nr-blit.h>
 #include <libnr/nr-gradient.h>
 #include <libnr/nr-matrix-ops.h>
-#include <glib/gtypes.h>
+#include <glib.h>
 #include <stdio.h>
 
 /* Common */
diff -urEw inkscape-0.48.2/src/libnr/nr-i-coord.h ./src/libnr/nr-i-coord.h
--- inkscape-0.48.2/src/libnr/nr-i-coord.h	2012-09-12 00:50:23.000000000 -0400
+++ ./src/libnr/nr-i-coord.h	2012-09-11 16:14:12.000000000 -0400
@@ -1,7 +1,7 @@
 #ifndef SEEN_NR_I_COORD_H
 #define SEEN_NR_I_COORD_H
 
-#include <glib/gtypes.h>
+#include <glib.h>
 
 namespace NR {
 
diff -urEw inkscape-0.48.2/src/libnr/nr-matrix.h ./src/libnr/nr-matrix.h
--- inkscape-0.48.2/src/libnr/nr-matrix.h	2012-09-12 00:50:23.000000000 -0400
+++ ./src/libnr/nr-matrix.h	2012-09-11 16:14:12.000000000 -0400
@@ -18,7 +18,6 @@
  */
 
 #include <glib.h> // g_assert()
-#include <glib/gmessages.h>
 
 #include "libnr/nr-coord.h"
 #include "libnr/nr-values.h"
diff -urEw inkscape-0.48.2/src/libnr/nr-object.cpp ./src/libnr/nr-object.cpp
--- inkscape-0.48.2/src/libnr/nr-object.cpp	2012-09-12 00:50:23.000000000 -0400
+++ ./src/libnr/nr-object.cpp	2012-09-11 16:42:01.000000000 -0400
@@ -15,7 +15,7 @@
 
 #include <typeinfo>
 
-#include <glib/gmem.h>
+#include <glib.h>
 #include <libnr/nr-macros.h>
 
 #include "nr-object.h"
diff -urEw inkscape-0.48.2/src/libnr/nr-object.h ./src/libnr/nr-object.h
--- inkscape-0.48.2/src/libnr/nr-object.h	2012-09-12 00:50:23.000000000 -0400
+++ ./src/libnr/nr-object.h	2012-09-11 16:14:12.000000000 -0400
@@ -15,7 +15,7 @@
 #include "config.h"
 #endif
 
-#include <glib/gtypes.h>
+#include <glib.h>
 #include "gc-managed.h"
 #include "gc-finalized.h"
 #include "gc-anchored.h"
diff -urEw inkscape-0.48.2/src/libnr/nr-pixblock-pattern.cpp ./src/libnr/nr-pixblock-pattern.cpp
--- inkscape-0.48.2/src/libnr/nr-pixblock-pattern.cpp	2012-09-12 00:50:23.000000000 -0400
+++ ./src/libnr/nr-pixblock-pattern.cpp	2012-09-11 16:42:01.000000000 -0400
@@ -10,7 +10,7 @@
  */
 
 
-#include <glib/gmem.h>
+#include <glib.h>
 #include "nr-pixops.h"
 #include "nr-pixblock-pattern.h"
 
diff -urEw inkscape-0.48.2/src/libnr/nr-pixblock.cpp ./src/libnr/nr-pixblock.cpp
--- inkscape-0.48.2/src/libnr/nr-pixblock.cpp	2012-09-12 00:50:23.000000000 -0400
+++ ./src/libnr/nr-pixblock.cpp	2012-09-11 16:42:01.000000000 -0400
@@ -13,7 +13,7 @@
 #include <cstring>
 #include <string>
 #include <string.h>
-#include <glib/gmem.h>
+#include <glib.h>
 #include "nr-pixblock.h"
 
 /// Size of buffer that needs no allocation (default 4).
diff -urEw inkscape-0.48.2/src/libnr/nr-point-fns-test.h ./src/libnr/nr-point-fns-test.h
--- inkscape-0.48.2/src/libnr/nr-point-fns-test.h	2012-09-12 00:50:23.000000000 -0400
+++ ./src/libnr/nr-point-fns-test.h	2012-09-11 16:14:12.000000000 -0400
@@ -3,7 +3,7 @@
 
 #include <cassert>
 #include <cmath>
-#include <glib/gmacros.h>
+#include <glib.h>
 #include <stdlib.h>
 
 #include "libnr/nr-point-fns.h"
diff -urEw inkscape-0.48.2/src/libnr/nr-rotate-fns-test.h ./src/libnr/nr-rotate-fns-test.h
--- inkscape-0.48.2/src/libnr/nr-rotate-fns-test.h	2012-09-12 00:50:23.000000000 -0400
+++ ./src/libnr/nr-rotate-fns-test.h	2012-09-11 16:14:12.000000000 -0400
@@ -1,7 +1,7 @@
 #include <cxxtest/TestSuite.h>
 
 #include <cmath>
-#include <glib/gmacros.h>
+#include <glib.h>
 
 #include <libnr/nr-rotate-fns.h>
 
diff -urEw inkscape-0.48.2/src/libnrtype/FontFactory.cpp ./src/libnrtype/FontFactory.cpp
--- inkscape-0.48.2/src/libnrtype/FontFactory.cpp	2012-09-12 00:50:23.000000000 -0400
+++ ./src/libnrtype/FontFactory.cpp	2012-09-11 16:42:01.000000000 -0400
@@ -15,7 +15,7 @@
 #endif
 
 #include <glibmm.h>
-#include <glib/gmem.h>
+#include <glib.h>
 #include <glibmm/i18n.h> // _()
 #include <pango/pangoft2.h>
 #include "libnrtype/FontFactory.h"
diff -urEw inkscape-0.48.2/src/libnrtype/Layout-TNG-Output.cpp ./src/libnrtype/Layout-TNG-Output.cpp
--- inkscape-0.48.2/src/libnrtype/Layout-TNG-Output.cpp	2012-09-12 00:50:23.000000000 -0400
+++ ./src/libnrtype/Layout-TNG-Output.cpp	2012-09-11 16:42:01.000000000 -0400
@@ -8,7 +8,7 @@
  *
  * Released under GNU GPL, read the file 'COPYING' for more information
  */
-#include <glib/gmem.h>
+#include <glib.h>
 #include "Layout-TNG.h"
 #include "display/nr-arena-glyphs.h"
 #include "style.h"
diff -urEw inkscape-0.48.2/src/libnrtype/nr-type-primitives.cpp ./src/libnrtype/nr-type-primitives.cpp
--- inkscape-0.48.2/src/libnrtype/nr-type-primitives.cpp	2012-09-12 00:50:23.000000000 -0400
+++ ./src/libnrtype/nr-type-primitives.cpp	2012-09-11 16:42:01.000000000 -0400
@@ -14,7 +14,7 @@
 
 #include <stdlib.h>
 #include <string.h>
-#include <glib/gmem.h>
+#include <glib.h>
 #include <libnr/nr-macros.h>
 #include "nr-type-primitives.h"
 
diff -urEw inkscape-0.48.2/src/libnrtype/nr-type-primitives.h ./src/libnrtype/nr-type-primitives.h
--- inkscape-0.48.2/src/libnrtype/nr-type-primitives.h	2012-09-12 00:50:23.000000000 -0400
+++ ./src/libnrtype/nr-type-primitives.h	2012-09-11 16:14:12.000000000 -0400
@@ -11,7 +11,7 @@
  * This code is in public domain
  */
 
-#include <glib/gtypes.h>
+#include <glib.h>
 
 struct NRNameList;
 struct NRStyleList;
diff -urEw inkscape-0.48.2/src/livarot/AlphaLigne.cpp ./src/livarot/AlphaLigne.cpp
--- inkscape-0.48.2/src/livarot/AlphaLigne.cpp	2012-09-12 00:50:23.000000000 -0400
+++ ./src/livarot/AlphaLigne.cpp	2012-09-11 16:42:01.000000000 -0400
@@ -12,7 +12,7 @@
 #include <math.h>
 #include <stdio.h>
 #include <stdlib.h>
-#include <glib/gmem.h>
+#include <glib.h>
 
 AlphaLigne::AlphaLigne(int iMin,int iMax)
 {
diff -urEw inkscape-0.48.2/src/livarot/BitLigne.cpp ./src/livarot/BitLigne.cpp
--- inkscape-0.48.2/src/livarot/BitLigne.cpp	2012-09-12 00:50:23.000000000 -0400
+++ ./src/livarot/BitLigne.cpp	2012-09-11 16:42:01.000000000 -0400
@@ -15,7 +15,7 @@
 #include <string>
 #include <cmath>
 #include <cstdio>
-#include <glib/gmem.h>
+#include <glib.h>
 
 BitLigne::BitLigne(int ist,int ien,float iScale)
 {
diff -urEw inkscape-0.48.2/src/livarot/PathSimplify.cpp ./src/livarot/PathSimplify.cpp
--- inkscape-0.48.2/src/livarot/PathSimplify.cpp	2012-09-12 00:50:23.000000000 -0400
+++ ./src/livarot/PathSimplify.cpp	2012-09-11 16:42:01.000000000 -0400
@@ -6,7 +6,7 @@
  *
  */
 
-#include <glib/gmem.h>
+#include <glib.h>
 #include <libnr/nr-point-matrix-ops.h>
 #include "livarot/Path.h"
 #include "livarot/path-description.h"
diff -urEw inkscape-0.48.2/src/livarot/Shape.cpp ./src/livarot/Shape.cpp
--- inkscape-0.48.2/src/livarot/Shape.cpp	2012-09-12 00:50:23.000000000 -0400
+++ ./src/livarot/Shape.cpp	2012-09-11 16:42:01.000000000 -0400
@@ -8,7 +8,7 @@
 
 #include <cstdio>
 #include <cstdlib>
-#include <glib/gmem.h>
+#include <glib.h>
 #include "Shape.h"
 #include "livarot/sweep-event-queue.h"
 #include "livarot/sweep-tree-list.h"
diff -urEw inkscape-0.48.2/src/livarot/ShapeSweep.cpp ./src/livarot/ShapeSweep.cpp
--- inkscape-0.48.2/src/livarot/ShapeSweep.cpp	2012-09-12 00:50:23.000000000 -0400
+++ ./src/livarot/ShapeSweep.cpp	2012-09-11 16:42:01.000000000 -0400
@@ -9,7 +9,7 @@
 #include <cstdio>
 #include <cstdlib>
 #include <cstring>
-#include <glib/gmem.h>
+#include <glib.h>
 #include "Shape.h"
 #include "livarot/sweep-event-queue.h"
 #include "livarot/sweep-tree-list.h"
diff -urEw inkscape-0.48.2/src/livarot/int-line.cpp ./src/livarot/int-line.cpp
--- inkscape-0.48.2/src/livarot/int-line.cpp	2012-09-12 00:50:23.000000000 -0400
+++ ./src/livarot/int-line.cpp	2012-09-11 16:42:01.000000000 -0400
@@ -9,7 +9,7 @@
  *
  */
 
-#include <glib/gmem.h>
+#include <glib.h>
 #include <cmath>
 #include <cstring>
 #include <string>
diff -urEw inkscape-0.48.2/src/livarot/sweep-event.cpp ./src/livarot/sweep-event.cpp
--- inkscape-0.48.2/src/livarot/sweep-event.cpp	2012-09-12 00:50:23.000000000 -0400
+++ ./src/livarot/sweep-event.cpp	2012-09-11 16:42:01.000000000 -0400
@@ -1,4 +1,4 @@
-#include <glib/gmem.h>
+#include <glib.h>
 #include "livarot/sweep-event-queue.h"
 #include "livarot/sweep-tree.h"
 #include "livarot/sweep-event.h"
diff -urEw inkscape-0.48.2/src/livarot/sweep-tree-list.cpp ./src/livarot/sweep-tree-list.cpp
--- inkscape-0.48.2/src/livarot/sweep-tree-list.cpp	2012-09-12 00:50:23.000000000 -0400
+++ ./src/livarot/sweep-tree-list.cpp	2012-09-11 16:42:01.000000000 -0400
@@ -1,4 +1,4 @@
-#include <glib/gmem.h>
+#include <glib.h>
 #include "livarot/sweep-tree.h"
 #include "livarot/sweep-tree-list.h"
 
diff -urEw inkscape-0.48.2/src/live_effects/parameter/array.h ./src/live_effects/parameter/array.h
--- inkscape-0.48.2/src/live_effects/parameter/array.h	2012-09-12 00:50:23.000000000 -0400
+++ ./src/live_effects/parameter/array.h	2012-09-11 16:14:12.000000000 -0400
@@ -11,7 +11,7 @@
 
 #include <vector>
 
-#include <glib/gtypes.h>
+#include <glib.h>
 
 #include <gtkmm/tooltips.h>
 
diff -urEw inkscape-0.48.2/src/live_effects/parameter/bool.h ./src/live_effects/parameter/bool.h
--- inkscape-0.48.2/src/live_effects/parameter/bool.h	2012-09-12 00:50:23.000000000 -0400
+++ ./src/live_effects/parameter/bool.h	2012-09-11 16:14:12.000000000 -0400
@@ -9,7 +9,7 @@
  * Released under GNU GPL, read the file 'COPYING' for more information
  */
 
-#include <glib/gtypes.h>
+#include <glib.h>
 
 #include "live_effects/parameter/parameter.h"
 
diff -urEw inkscape-0.48.2/src/live_effects/parameter/enum.h ./src/live_effects/parameter/enum.h
--- inkscape-0.48.2/src/live_effects/parameter/enum.h	2012-09-12 00:50:23.000000000 -0400
+++ ./src/live_effects/parameter/enum.h	2012-09-11 16:14:12.000000000 -0400
@@ -9,7 +9,7 @@
  * Released under GNU GPL, read the file 'COPYING' for more information
  */
 
-#include <glib/gtypes.h>
+#include <glib.h>
 
 #include "ui/widget/registered-enums.h"
 #include <gtkmm/tooltips.h>
diff -urEw inkscape-0.48.2/src/live_effects/parameter/path.h ./src/live_effects/parameter/path.h
--- inkscape-0.48.2/src/live_effects/parameter/path.h	2012-09-12 00:50:23.000000000 -0400
+++ ./src/live_effects/parameter/path.h	2012-09-11 16:14:12.000000000 -0400
@@ -9,7 +9,7 @@
  * Released under GNU GPL, read the file 'COPYING' for more information
  */
 
-#include <glib/gtypes.h>
+#include <glib.h>
 #include <2geom/path.h>
 
 #include <gtkmm/tooltips.h>
diff -urEw inkscape-0.48.2/src/live_effects/parameter/point.h ./src/live_effects/parameter/point.h
--- inkscape-0.48.2/src/live_effects/parameter/point.h	2012-09-12 00:50:23.000000000 -0400
+++ ./src/live_effects/parameter/point.h	2012-09-11 16:14:12.000000000 -0400
@@ -9,7 +9,7 @@
  * Released under GNU GPL, read the file 'COPYING' for more information
  */
 
-#include <glib/gtypes.h>
+#include <glib.h>
 #include <2geom/point.h>
 
 #include <gtkmm/tooltips.h>
diff -urEw inkscape-0.48.2/src/live_effects/parameter/text.h ./src/live_effects/parameter/text.h
--- inkscape-0.48.2/src/live_effects/parameter/text.h	2012-09-12 00:50:23.000000000 -0400
+++ ./src/live_effects/parameter/text.h	2012-09-11 16:14:12.000000000 -0400
@@ -13,7 +13,7 @@
  * Released under GNU GPL, read the file 'COPYING' for more information
  */
 
-#include <glib/gtypes.h>
+#include <glib.h>
 
 #include "display/canvas-bpath.h"
 #include "live_effects/parameter/parameter.h"
diff -urEw inkscape-0.48.2/src/live_effects/parameter/vector.h ./src/live_effects/parameter/vector.h
--- inkscape-0.48.2/src/live_effects/parameter/vector.h	2012-09-12 00:50:23.000000000 -0400
+++ ./src/live_effects/parameter/vector.h	2012-09-11 16:14:12.000000000 -0400
@@ -9,7 +9,7 @@
  * Released under GNU GPL, read the file 'COPYING' for more information
  */
 
-#include <glib/gtypes.h>
+#include <glib.h>
 #include <2geom/point.h>
 
 #include <gtkmm/tooltips.h>
diff -urEw inkscape-0.48.2/src/main-cmdlineact.h ./src/main-cmdlineact.h
--- inkscape-0.48.2/src/main-cmdlineact.h	2012-09-12 00:50:23.000000000 -0400
+++ ./src/main-cmdlineact.h	2012-09-11 16:14:12.000000000 -0400
@@ -15,7 +15,7 @@
  * Released under GNU GPL v2.x, read the file 'COPYING' for more information
  */
 
-#include <glib/gtypes.h>
+#include <glib.h>
 
 namespace Inkscape {
 
diff -urEw inkscape-0.48.2/src/main.cpp ./src/main.cpp
--- inkscape-0.48.2/src/main.cpp	2012-09-12 00:50:23.000000000 -0400
+++ ./src/main.cpp	2012-09-11 16:42:01.000000000 -0400
@@ -48,7 +48,7 @@
 
 #include <libxml/tree.h>
 #include <glib.h>
-#include <glib/gprintf.h>
+#include <glib.h>
 #include <glib-object.h>
 #include <gtk/gtk.h>
 
diff -urEw inkscape-0.48.2/src/message-context.cpp ./src/message-context.cpp
--- inkscape-0.48.2/src/message-context.cpp	2012-09-12 00:50:23.000000000 -0400
+++ ./src/message-context.cpp	2012-09-11 16:42:01.000000000 -0400
@@ -9,7 +9,7 @@
  * Released under GNU GPL, read the file 'COPYING' for more information
  */
 
-#include <glib/gstrfuncs.h>
+#include <glib.h>
 #include "message-context.h"
 #include "message-stack.h"
 
diff -urEw inkscape-0.48.2/src/message-stack.cpp ./src/message-stack.cpp
--- inkscape-0.48.2/src/message-stack.cpp	2012-09-12 00:50:23.000000000 -0400
+++ ./src/message-stack.cpp	2012-09-11 16:42:01.000000000 -0400
@@ -10,7 +10,7 @@
  */
 
 #include <string.h>
-#include <glib/gstrfuncs.h>
+#include <glib.h>
 #include <cstring>
 #include <string>
 #include "message-stack.h"
diff -urEw inkscape-0.48.2/src/modifier-fns.h ./src/modifier-fns.h
--- inkscape-0.48.2/src/modifier-fns.h	2012-09-12 00:50:23.000000000 -0400
+++ ./src/modifier-fns.h	2012-09-11 16:14:13.000000000 -0400
@@ -12,7 +12,7 @@
  */
 
 #include <gdk/gdk.h>
-#include <glib/gtypes.h>
+#include <glib.h>
 
 inline bool
 mod_shift(guint const state)
diff -urEw inkscape-0.48.2/src/number-opt-number.h ./src/number-opt-number.h
--- inkscape-0.48.2/src/number-opt-number.h	2012-09-12 00:50:23.000000000 -0400
+++ ./src/number-opt-number.h	2012-09-11 16:14:13.000000000 -0400
@@ -18,7 +18,7 @@
 #endif
 
 #include <glib.h>
-#include <glib/gprintf.h>
+#include <glib.h>
 //todo: use glib instead of stdlib
 #include <stdlib.h>
 #include "svg/stringstream.h"
diff -urEw inkscape-0.48.2/src/object-hierarchy.h ./src/object-hierarchy.h
--- inkscape-0.48.2/src/object-hierarchy.h	2012-09-12 00:50:23.000000000 -0400
+++ ./src/object-hierarchy.h	2012-09-11 16:14:13.000000000 -0400
@@ -17,7 +17,7 @@
 #include <stddef.h>
 #include <sigc++/connection.h>
 #include <sigc++/signal.h>
-#include <glib/gmessages.h>
+#include <glib.h>
 
 class SPObject;
 
diff -urEw inkscape-0.48.2/src/path-chemistry.cpp ./src/path-chemistry.cpp
--- inkscape-0.48.2/src/path-chemistry.cpp	2012-09-12 00:50:23.000000000 -0400
+++ ./src/path-chemistry.cpp	2012-09-11 16:42:01.000000000 -0400
@@ -22,7 +22,7 @@
 #include "xml/repr.h"
 #include "svg/svg.h"
 #include "display/curve.h"
-#include <glib/gmem.h>
+#include <glib.h>
 #include <glibmm/i18n.h>
 #include "sp-path.h"
 #include "sp-text.h"
diff -urEw inkscape-0.48.2/src/removeoverlap.h ./src/removeoverlap.h
--- inkscape-0.48.2/src/removeoverlap.h	2012-09-12 00:50:23.000000000 -0400
+++ ./src/removeoverlap.h	2012-09-11 16:14:13.000000000 -0400
@@ -13,7 +13,7 @@
 #ifndef SEEN_REMOVEOVERLAP_H
 #define SEEN_REMOVEOVERLAP_H
 
-#include <glib/gslist.h>
+#include <glib.h>
 
 void removeoverlap(GSList const *items, double xGap, double yGap);
 
diff -urEw inkscape-0.48.2/src/sp-conn-end-pair.h ./src/sp-conn-end-pair.h
--- inkscape-0.48.2/src/sp-conn-end-pair.h	2012-09-12 00:50:23.000000000 -0400
+++ ./src/sp-conn-end-pair.h	2012-09-11 16:14:13.000000000 -0400
@@ -11,7 +11,7 @@
  *
  * Released under GNU GPL, read the file 'COPYING' for more information
  */
-#include <glib/gtypes.h>
+#include <glib.h>
 
 #include "forward.h"
 #include "libnr/nr-point.h"
diff -urEw inkscape-0.48.2/src/sp-conn-end.h ./src/sp-conn-end.h
--- inkscape-0.48.2/src/sp-conn-end.h	2012-09-12 00:50:23.000000000 -0400
+++ ./src/sp-conn-end.h	2012-09-11 16:14:13.000000000 -0400
@@ -1,7 +1,7 @@
 #ifndef SEEN_SP_CONN_END
 #define SEEN_SP_CONN_END
 
-#include <glib/gtypes.h>
+#include <glib.h>
 #include <stddef.h>
 #include <sigc++/connection.h>
 
diff -urEw inkscape-0.48.2/src/sp-filter-fns.h ./src/sp-filter-fns.h
--- inkscape-0.48.2/src/sp-filter-fns.h	2012-09-12 00:50:23.000000000 -0400
+++ ./src/sp-filter-fns.h	2012-09-11 16:14:13.000000000 -0400
@@ -5,7 +5,7 @@
  * Macros and fn declarations related to filters.
  */
 
-#include <glib/gtypes.h>
+#include <glib.h>
 #include <glib-object.h>
 #include "libnr/nr-forward.h"
 #include "sp-filter-units.h"
diff -urEw inkscape-0.48.2/src/sp-gaussian-blur-fns.h ./src/sp-gaussian-blur-fns.h
--- inkscape-0.48.2/src/sp-gaussian-blur-fns.h	2012-09-12 00:50:23.000000000 -0400
+++ ./src/sp-gaussian-blur-fns.h	2012-09-11 16:14:13.000000000 -0400
@@ -6,7 +6,7 @@
  */
 
 #include <glib-object.h>
-#include <glib/gtypes.h>
+#include <glib.h>
 
 namespace Inkscape {
 namespace XML {
diff -urEw inkscape-0.48.2/src/sp-gradient-fns.h ./src/sp-gradient-fns.h
--- inkscape-0.48.2/src/sp-gradient-fns.h	2012-09-12 00:50:23.000000000 -0400
+++ ./src/sp-gradient-fns.h	2012-09-11 16:14:13.000000000 -0400
@@ -5,7 +5,7 @@
  * Macros and fn declarations related to gradients.
  */
 
-#include <glib/gtypes.h>
+#include <glib.h>
 #include <glib-object.h>
 #include <2geom/forward.h>
 #include "sp-gradient-spread.h"
diff -urEw inkscape-0.48.2/src/sp-gradient-vector.h ./src/sp-gradient-vector.h
--- inkscape-0.48.2/src/sp-gradient-vector.h	2012-09-12 00:50:23.000000000 -0400
+++ ./src/sp-gradient-vector.h	2012-09-11 16:14:13.000000000 -0400
@@ -1,7 +1,7 @@
 #ifndef SEEN_SP_GRADIENT_VECTOR_H
 #define SEEN_SP_GRADIENT_VECTOR_H
 
-#include <glib/gtypes.h>
+#include <glib.h>
 #include <vector>
 #include "color.h"
 
diff -urEw inkscape-0.48.2/src/sp-image.cpp ./src/sp-image.cpp
--- inkscape-0.48.2/src/sp-image.cpp	2012-09-12 00:50:23.000000000 -0400
+++ ./src/sp-image.cpp	2012-09-11 16:48:31.000000000 -0400
@@ -30,6 +30,7 @@
 //#include <gdk-pixbuf/gdk-pixbuf-io.h>
 #include "display/nr-arena-image.h"
 #include <display/curve.h>
+#include <glib.h>
 #include <glib/gstdio.h>
 
 //Added for preserveAspectRatio support -- EAF
@@ -390,9 +391,9 @@
                     int compression_type = 0;
                     char* profile = 0;
                     png_uint_32 proflen = 0;
-                    if ( png_get_iCCP(pngPtr, infoPtr, &name, &compression_type, &profile, &proflen) ) {
-//                                         g_message("Found an iCCP chunk named [%s] with %d bytes and comp %d", name, proflen, compression_type);
-                    }
+//                     if ( png_get_iCCP(pngPtr, infoPtr, &name, &compression_type, &profile, &proflen) ) {
+// //                                         g_message("Found an iCCP chunk named [%s] with %d bytes and comp %d", name, proflen, compression_type);
+//                     }
                 }
 #endif // defined(PNG_iCCP_SUPPORTED)
 
diff -urEw inkscape-0.48.2/src/sp-linear-gradient-fns.h ./src/sp-linear-gradient-fns.h
--- inkscape-0.48.2/src/sp-linear-gradient-fns.h	2012-09-12 00:50:23.000000000 -0400
+++ ./src/sp-linear-gradient-fns.h	2012-09-11 16:14:13.000000000 -0400
@@ -6,7 +6,7 @@
  */
 
 #include <glib-object.h>
-#include <glib/gtypes.h>
+#include <glib.h>
 
 namespace Inkscape {
 namespace XML {
diff -urEw inkscape-0.48.2/src/sp-metrics.h ./src/sp-metrics.h
--- inkscape-0.48.2/src/sp-metrics.h	2012-09-12 00:50:23.000000000 -0400
+++ ./src/sp-metrics.h	2012-09-11 16:14:13.000000000 -0400
@@ -1,8 +1,8 @@
 #ifndef SP_METRICS_H
 #define SP_METRICS_H
 
-#include <glib/gstring.h>
-#include <glib/gtypes.h>
+#include <glib.h>
+#include <glib.h>
 #include "sp-metric.h"
 
 gdouble sp_absolute_metric_to_metric (gdouble length_src, const SPMetric metric_src, const SPMetric metric_dst);
diff -urEw inkscape-0.48.2/src/sp-radial-gradient.h ./src/sp-radial-gradient.h
--- inkscape-0.48.2/src/sp-radial-gradient.h	2012-09-12 00:50:23.000000000 -0400
+++ ./src/sp-radial-gradient.h	2012-09-11 16:14:13.000000000 -0400
@@ -5,7 +5,7 @@
  * SPRadialGradient: SVG <radialgradient> implementtion.
  */
 
-#include <glib/gtypes.h>
+#include <glib.h>
 #include "sp-gradient.h"
 #include "svg/svg-length.h"
 #include "sp-radial-gradient-fns.h"
diff -urEw inkscape-0.48.2/src/sp-stop.h ./src/sp-stop.h
--- inkscape-0.48.2/src/sp-stop.h	2012-09-12 00:50:23.000000000 -0400
+++ ./src/sp-stop.h	2012-09-11 16:14:13.000000000 -0400
@@ -8,7 +8,7 @@
  * Authors?
  */
 
-#include <glib/gtypes.h>
+#include <glib.h>
 #include <glibmm/ustring.h>
 #include "sp-object.h"
 #include "color.h"
diff -urEw inkscape-0.48.2/src/sp-text.h ./src/sp-text.h
--- inkscape-0.48.2/src/sp-text.h	2012-09-12 00:50:23.000000000 -0400
+++ ./src/sp-text.h	2012-09-11 16:14:13.000000000 -0400
@@ -13,7 +13,7 @@
  * Released under GNU GPL, read the file 'COPYING' for more information
  */
 
-#include <glib/gtypes.h>
+#include <glib.h>
 #include <stddef.h>
 #include <sigc++/sigc++.h>
 #include "sp-item.h"
diff -urEw inkscape-0.48.2/src/sp-textpath.h ./src/sp-textpath.h
--- inkscape-0.48.2/src/sp-textpath.h	2012-09-12 00:50:23.000000000 -0400
+++ ./src/sp-textpath.h	2012-09-11 16:14:13.000000000 -0400
@@ -1,7 +1,7 @@
 #ifndef INKSCAPE_SP_TEXTPATH_H
 #define INKSCAPE_SP_TEXTPATH_H
 
-#include <glib/gtypes.h>
+#include <glib.h>
 #include "svg/svg-length.h"
 #include "sp-item.h"
 #include "sp-text.h"
diff -urEw inkscape-0.48.2/src/sp-tspan.h ./src/sp-tspan.h
--- inkscape-0.48.2/src/sp-tspan.h	2012-09-12 00:50:23.000000000 -0400
+++ ./src/sp-tspan.h	2012-09-11 16:14:13.000000000 -0400
@@ -5,7 +5,7 @@
  * tspan and textpath, based on the flowtext routines
  */
 
-#include <glib/gtypes.h>
+#include <glib.h>
 #include "sp-item.h"
 #include "text-tag-attributes.h"
 
diff -urEw inkscape-0.48.2/src/splivarot.cpp ./src/splivarot.cpp
--- inkscape-0.48.2/src/splivarot.cpp	2012-09-12 00:50:23.000000000 -0400
+++ ./src/splivarot.cpp	2012-09-11 16:42:02.000000000 -0400
@@ -20,7 +20,7 @@
 #include <cstring>
 #include <string>
 #include <vector>
-#include <glib/gmem.h>
+#include <glib.h>
 #include "xml/repr.h"
 #include "svg/svg.h"
 #include "sp-path.h"
diff -urEw inkscape-0.48.2/src/spray-context.cpp ./src/spray-context.cpp
--- inkscape-0.48.2/src/spray-context.cpp	2012-09-12 00:50:23.000000000 -0400
+++ ./src/spray-context.cpp	2012-09-11 16:42:02.000000000 -0400
@@ -29,7 +29,7 @@
 #include "svg/svg.h"
 #include "display/canvas-bpath.h"
 
-#include <glib/gmem.h>
+#include <glib.h>
 #include "macros.h"
 #include "document.h"
 #include "selection.h"
diff -urEw inkscape-0.48.2/src/svg/css-ostringstream.cpp ./src/svg/css-ostringstream.cpp
--- inkscape-0.48.2/src/svg/css-ostringstream.cpp	2012-09-12 00:50:23.000000000 -0400
+++ ./src/svg/css-ostringstream.cpp	2012-09-11 16:42:02.000000000 -0400
@@ -1,8 +1,8 @@
 #include "svg/css-ostringstream.h"
 #include "svg/strip-trailing-zeros.h"
 #include "preferences.h"
-#include <glib/gmessages.h>
-#include <glib/gstrfuncs.h>
+#include <glib.h>
+#include <glib.h>
 
 Inkscape::CSSOStringStream::CSSOStringStream()
 {
diff -urEw inkscape-0.48.2/src/svg/css-ostringstream.h ./src/svg/css-ostringstream.h
--- inkscape-0.48.2/src/svg/css-ostringstream.h	2012-09-12 00:50:23.000000000 -0400
+++ ./src/svg/css-ostringstream.h	2012-09-11 16:14:13.000000000 -0400
@@ -1,7 +1,7 @@
 #ifndef SVG_CSS_OSTRINGSTREAM_H_INKSCAPE
 #define SVG_CSS_OSTRINGSTREAM_H_INKSCAPE
 
-#include <glib/gtypes.h>
+#include <glib.h>
 #include <sstream>
 
 namespace Inkscape {
diff -urEw inkscape-0.48.2/src/svg/stringstream.h ./src/svg/stringstream.h
--- inkscape-0.48.2/src/svg/stringstream.h	2012-09-12 00:50:23.000000000 -0400
+++ ./src/svg/stringstream.h	2012-09-11 16:14:13.000000000 -0400
@@ -1,7 +1,7 @@
 #ifndef INKSCAPE_STRINGSTREAM_H
 #define INKSCAPE_STRINGSTREAM_H
 
-#include <glib/gtypes.h>
+#include <glib.h>
 #include <sstream>
 #include <string>
 
diff -urEw inkscape-0.48.2/src/svg/strip-trailing-zeros.cpp ./src/svg/strip-trailing-zeros.cpp
--- inkscape-0.48.2/src/svg/strip-trailing-zeros.cpp	2012-09-12 00:50:23.000000000 -0400
+++ ./src/svg/strip-trailing-zeros.cpp	2012-09-11 16:42:02.000000000 -0400
@@ -1,7 +1,7 @@
 
 #include <cstring>
 #include <string>
-#include <glib/gmessages.h>
+#include <glib.h>
 
 #include "svg/strip-trailing-zeros.h"
 
diff -urEw inkscape-0.48.2/src/svg/svg-affine.cpp ./src/svg/svg-affine.cpp
--- inkscape-0.48.2/src/svg/svg-affine.cpp	2012-09-12 00:50:23.000000000 -0400
+++ ./src/svg/svg-affine.cpp	2012-09-11 16:42:02.000000000 -0400
@@ -19,7 +19,7 @@
 #include <string>
 #include <cstdlib>
 #include <cstdio>
-#include <glib/gstrfuncs.h>
+#include <glib.h>
 #include <libnr/nr-matrix-fns.h>
 #include <libnr/nr-matrix-ops.h>
 #include <2geom/transforms.h>
diff -urEw inkscape-0.48.2/src/svg/svg-color.cpp ./src/svg/svg-color.cpp
--- inkscape-0.48.2/src/svg/svg-color.cpp	2012-09-12 00:50:23.000000000 -0400
+++ ./src/svg/svg-color.cpp	2012-09-11 16:42:02.000000000 -0400
@@ -23,12 +23,12 @@
 #include <string>
 #include <cassert>
 #include <math.h>
-#include <glib/gmem.h>
+#include <glib.h>
 #include <glib.h> // g_assert
-#include <glib/gmessages.h>
-#include <glib/gstrfuncs.h>
-#include <glib/ghash.h>
-#include <glib/gutils.h>
+#include <glib.h>
+#include <glib.h>
+#include <glib.h>
+#include <glib.h>
 #include <errno.h>
 
 #include "strneq.h"
diff -urEw inkscape-0.48.2/src/svg/svg-color.h ./src/svg/svg-color.h
--- inkscape-0.48.2/src/svg/svg-color.h	2012-09-12 00:50:23.000000000 -0400
+++ ./src/svg/svg-color.h	2012-09-11 16:14:13.000000000 -0400
@@ -1,7 +1,7 @@
 #ifndef SVG_SVG_COLOR_H_SEEN
 #define SVG_SVG_COLOR_H_SEEN
 
-#include <glib/gtypes.h>
+#include <glib.h>
 
 class SVGICCColor;
 
diff -urEw inkscape-0.48.2/src/svg/svg-length.cpp ./src/svg/svg-length.cpp
--- inkscape-0.48.2/src/svg/svg-length.cpp	2012-09-12 00:50:23.000000000 -0400
+++ ./src/svg/svg-length.cpp	2012-09-11 16:42:02.000000000 -0400
@@ -19,7 +19,7 @@
 #include <cstring>
 #include <string>
 #include <math.h>
-#include <glib/gstrfuncs.h>
+#include <glib.h>
 
 #include "svg.h"
 #include "stringstream.h"
diff -urEw inkscape-0.48.2/src/svg/svg-length.h ./src/svg/svg-length.h
--- inkscape-0.48.2/src/svg/svg-length.h	2012-09-12 00:50:23.000000000 -0400
+++ ./src/svg/svg-length.h	2012-09-11 16:14:13.000000000 -0400
@@ -16,7 +16,7 @@
  * Released under GNU GPL, read the file 'COPYING' for more information
  */
 
-#include <glib/gtypes.h>
+#include <glib.h>
 
 class SVGLength
 {
diff -urEw inkscape-0.48.2/src/svg/svg-path-geom-test.h ./src/svg/svg-path-geom-test.h
--- inkscape-0.48.2/src/svg/svg-path-geom-test.h	2012-09-12 00:50:23.000000000 -0400
+++ ./src/svg/svg-path-geom-test.h	2012-09-11 16:14:13.000000000 -0400
@@ -8,7 +8,7 @@
 #include <stdio.h>
 #include <string>
 #include <vector>
-#include <glib/gmem.h>
+#include <glib.h>
 
 class SvgPathGeomTest : public CxxTest::TestSuite
 {
diff -urEw inkscape-0.48.2/src/svg/svg-path.cpp ./src/svg/svg-path.cpp
--- inkscape-0.48.2/src/svg/svg-path.cpp	2012-09-12 00:50:23.000000000 -0400
+++ ./src/svg/svg-path.cpp	2012-09-11 16:42:02.000000000 -0400
@@ -31,9 +31,9 @@
 #include <cstring>
 #include <string>
 #include <cassert>
-#include <glib/gmem.h>
-#include <glib/gmessages.h>
-#include <glib/gstrfuncs.h>
+#include <glib.h>
+#include <glib.h>
+#include <glib.h>
 #include <glib.h> // g_assert()
 
 #include "svg/svg.h"
diff -urEw inkscape-0.48.2/src/svg/svg.h ./src/svg/svg.h
--- inkscape-0.48.2/src/svg/svg.h	2012-09-12 00:50:23.000000000 -0400
+++ ./src/svg/svg.h	2012-09-11 16:14:13.000000000 -0400
@@ -11,7 +11,7 @@
  *
  * Released under GNU GPL, read the file 'COPYING' for more information
  */
-#include <glib/gtypes.h>
+#include <glib.h>
 #include <vector>
 #include <cstring>
 #include <string>
diff -urEw inkscape-0.48.2/src/text-editing.h ./src/text-editing.h
--- inkscape-0.48.2/src/text-editing.h	2012-09-12 00:50:23.000000000 -0400
+++ ./src/text-editing.h	2012-09-11 16:14:13.000000000 -0400
@@ -13,7 +13,7 @@
  * Released under GNU GPL, read the file 'COPYING' for more information
  */
 
-#include <glib/gtypes.h>
+#include <glib.h>
 #include <utility>   // std::pair
 #include "libnrtype/Layout-TNG.h"
 #include <libnr/nr-forward.h>
diff -urEw inkscape-0.48.2/src/text-tag-attributes.h ./src/text-tag-attributes.h
--- inkscape-0.48.2/src/text-tag-attributes.h	2012-09-12 00:50:23.000000000 -0400
+++ ./src/text-tag-attributes.h	2012-09-11 16:14:13.000000000 -0400
@@ -2,7 +2,7 @@
 #define INKSCAPE_TEXT_TAG_ATTRIBUTES_H
 
 #include <vector>
-#include <glib/gtypes.h>
+#include <glib.h>
 #include "libnrtype/Layout-TNG.h"
 #include "svg/svg-length.h"
 
diff -urEw inkscape-0.48.2/src/trace/potrace/potracelib.cpp ./src/trace/potrace/potracelib.cpp
--- inkscape-0.48.2/src/trace/potrace/potracelib.cpp	2012-09-12 00:50:23.000000000 -0400
+++ ./src/trace/potrace/potracelib.cpp	2012-09-11 16:42:02.000000000 -0400
@@ -4,7 +4,7 @@
 
 #include <stdlib.h>
 #include <string.h>
-#include <glib/gstrfuncs.h>
+#include <glib.h>
 
 #include "potracelib.h"
 #include "inkscape-version.h"
diff -urEw inkscape-0.48.2/src/tweak-context.cpp ./src/tweak-context.cpp
--- inkscape-0.48.2/src/tweak-context.cpp	2012-09-12 00:50:23.000000000 -0400
+++ ./src/tweak-context.cpp	2012-09-11 16:42:02.000000000 -0400
@@ -22,7 +22,7 @@
 #include "svg/svg.h"
 #include "display/canvas-bpath.h"
 
-#include <glib/gmem.h>
+#include <glib.h>
 #include "macros.h"
 #include "document.h"
 #include "selection.h"
diff -urEw inkscape-0.48.2/src/ui/cache/svg_preview_cache.cpp ./src/ui/cache/svg_preview_cache.cpp
--- inkscape-0.48.2/src/ui/cache/svg_preview_cache.cpp	2012-09-12 00:50:23.000000000 -0400
+++ ./src/ui/cache/svg_preview_cache.cpp	2012-09-11 16:42:02.000000000 -0400
@@ -19,7 +19,7 @@
 # include "config.h"
 #endif
 
-#include <glib/gmem.h>
+#include <glib.h>
 #include <gtk/gtk.h>
 #include "sp-namedview.h"
 #include "selection.h"
diff -urEw inkscape-0.48.2/src/ui/clipboard.cpp ./src/ui/clipboard.cpp
--- inkscape-0.48.2/src/ui/clipboard.cpp	2012-09-12 00:50:23.000000000 -0400
+++ ./src/ui/clipboard.cpp	2012-09-11 17:03:21.000000000 -0400
@@ -26,7 +26,8 @@
 #include <gtkmm/clipboard.h>
 #include <glibmm/ustring.h>
 #include <glibmm/i18n.h>
-#include <glib/gstdio.h> // for g_file_set_contents etc., used in _onGet and paste
+#include <glib.h> // for g_file_set_contents etc., used in _onGet and paste
+#include <glib/gstdio.h>
 #include "gc-core.h"
 #include "xml/repr.h"
 #include "inkscape.h"
diff -urEw inkscape-0.48.2/src/ui/dialog/desktop-tracker.h ./src/ui/dialog/desktop-tracker.h
--- inkscape-0.48.2/src/ui/dialog/desktop-tracker.h	2012-09-12 00:50:23.000000000 -0400
+++ ./src/ui/dialog/desktop-tracker.h	2012-09-11 16:14:14.000000000 -0400
@@ -13,7 +13,7 @@
 
 #include <stddef.h>
 #include <sigc++/connection.h>
-#include <glib/gtypes.h>
+#include <glib.h>
 
 typedef struct _GtkWidget GtkWidget;
 class SPDesktop;
diff -urEw inkscape-0.48.2/src/ui/dialog/dialog-manager.h ./src/ui/dialog/dialog-manager.h
--- inkscape-0.48.2/src/ui/dialog/dialog-manager.h	2012-09-12 00:50:23.000000000 -0400
+++ ./src/ui/dialog/dialog-manager.h	2012-09-11 16:14:14.000000000 -0400
@@ -14,7 +14,7 @@
 #ifndef INKSCAPE_UI_DIALOG_MANAGER_H
 #define INKSCAPE_UI_DIALOG_MANAGER_H
 
-#include <glib/gquark.h>
+#include <glib.h>
 #include "dialog.h"
 #include <map>
 
diff -urEw inkscape-0.48.2/src/ui/dialog/filedialogimpl-gtkmm.cpp ./src/ui/dialog/filedialogimpl-gtkmm.cpp
--- inkscape-0.48.2/src/ui/dialog/filedialogimpl-gtkmm.cpp	2012-09-12 00:50:23.000000000 -0400
+++ ./src/ui/dialog/filedialogimpl-gtkmm.cpp	2012-09-11 17:04:02.000000000 -0400
@@ -25,6 +25,7 @@
 #include "io/sys.h"
 #include "path-prefix.h"
 #include "preferences.h"
+#include <glib/gstdio.h>
 
 #ifdef WITH_GNOME_VFS
 # include <libgnomevfs/gnome-vfs.h>
diff -urEw inkscape-0.48.2/src/ui/dialog/filedialogimpl-gtkmm.h ./src/ui/dialog/filedialogimpl-gtkmm.h
--- inkscape-0.48.2/src/ui/dialog/filedialogimpl-gtkmm.h	2012-09-12 00:50:23.000000000 -0400
+++ ./src/ui/dialog/filedialogimpl-gtkmm.h	2012-09-11 16:14:14.000000000 -0400
@@ -30,7 +30,7 @@
 
 //Gtk includes
 #include <glibmm/i18n.h>
-#include <glib/gstdio.h>
+#include <glib.h>
 
 //Temporary ugly hack
 //Remove this after the get_filter() calls in
diff -urEw inkscape-0.48.2/src/ui/dialog/filedialogimpl-win32.cpp ./src/ui/dialog/filedialogimpl-win32.cpp
--- inkscape-0.48.2/src/ui/dialog/filedialogimpl-win32.cpp	2012-09-12 00:50:23.000000000 -0400
+++ ./src/ui/dialog/filedialogimpl-win32.cpp	2012-09-11 16:42:02.000000000 -0400
@@ -22,7 +22,7 @@
 #include <errno.h>
 #include <set>
 #include <gdk/gdkwin32.h>
-#include <glib/gstdio.h>
+#include <glib.h>
 #include <glibmm/i18n.h>
 #include <gtkmm/window.h>
 
diff -urEw inkscape-0.48.2/src/ui/dialog/icon-preview.cpp ./src/ui/dialog/icon-preview.cpp
--- inkscape-0.48.2/src/ui/dialog/icon-preview.cpp	2012-09-12 00:50:23.000000000 -0400
+++ ./src/ui/dialog/icon-preview.cpp	2012-09-11 16:42:02.000000000 -0400
@@ -16,7 +16,7 @@
 #endif
 
 #include <gtk/gtk.h>
-#include <glib/gmem.h>
+#include <glib.h>
 #include <glibmm/i18n.h>
 #include <gtkmm/alignment.h>
 #include <gtkmm/buttonbox.h>
diff -urEw inkscape-0.48.2/src/ui/dialog/inkscape-preferences.cpp ./src/ui/dialog/inkscape-preferences.cpp
--- inkscape-0.48.2/src/ui/dialog/inkscape-preferences.cpp	2012-09-12 00:50:23.000000000 -0400
+++ ./src/ui/dialog/inkscape-preferences.cpp	2012-09-11 17:05:02.000000000 -0400
@@ -1222,7 +1222,7 @@
         gchar** splits = g_strsplit(choices.data(), ",", 0);
         gint numIems = g_strv_length(splits);
 
-        Glib::ustring labels[numIems];
+        Glib::ustring *labels= new Glib::ustring[numIems];
         int values[numIems];
         for ( gint i = 0; i < numIems; i++) {
             values[i] = i;
@@ -1230,6 +1230,7 @@
         }
         _misc_bitmap_editor.init("/options/bitmapeditor/value", labels, values, numIems, 0);
         _page_bitmaps.add_line( false, _("Bitmap editor:"), _misc_bitmap_editor, "", "", false);
+        delete []labels;
 
         g_strfreev(splits);
     }
diff -urEw inkscape-0.48.2/src/ui/dialog/input.cpp ./src/ui/dialog/input.cpp
--- inkscape-0.48.2/src/ui/dialog/input.cpp	2012-09-12 00:50:23.000000000 -0400
+++ ./src/ui/dialog/input.cpp	2012-09-11 16:42:02.000000000 -0400
@@ -11,7 +11,7 @@
 #include <map>
 #include <set>
 #include <list>
-#include <glib/gprintf.h>
+#include <glib.h>
 #include <glibmm/i18n.h>
 #include <gtkmm/alignment.h>
 #include <gtkmm/cellrenderercombo.h>
diff -urEw inkscape-0.48.2/src/ui/dialog/ocaldialogs.h ./src/ui/dialog/ocaldialogs.h
--- inkscape-0.48.2/src/ui/dialog/ocaldialogs.h	2012-09-12 00:50:23.000000000 -0400
+++ ./src/ui/dialog/ocaldialogs.h	2012-09-11 16:14:14.000000000 -0400
@@ -28,7 +28,7 @@
 
 //Gtk includes
 #include <glibmm/i18n.h>
-#include <glib/gstdio.h>
+#include <glib.h>
 
 //Temporary ugly hack
 //Remove this after the get_filter() calls in
diff -urEw inkscape-0.48.2/src/ui/widget/icon-widget.cpp ./src/ui/widget/icon-widget.cpp
--- inkscape-0.48.2/src/ui/widget/icon-widget.cpp	2012-09-12 00:50:23.000000000 -0400
+++ ./src/ui/widget/icon-widget.cpp	2012-09-11 16:42:03.000000000 -0400
@@ -14,7 +14,7 @@
 # include <config.h>
 #endif
 
-#include <glib/gmem.h>
+#include <glib.h>
 #include "icon-widget.h"
 
 namespace Inkscape {
diff -urEw inkscape-0.48.2/src/ui/widget/registered-widget.h ./src/ui/widget/registered-widget.h
--- inkscape-0.48.2/src/ui/widget/registered-widget.h	2012-09-12 00:50:23.000000000 -0400
+++ ./src/ui/widget/registered-widget.h	2012-09-11 16:16:39.000000000 -0400
@@ -62,7 +62,7 @@
     bool is_updating() {if (_wr) return _wr->isUpdating(); else return false;}
 
     // provide automatic 'upcast' for ease of use. (do it 'dynamic_cast' instead of 'static' because who knows what W is)
-    operator const Gtk::Widget () { return dynamic_cast<Gtk::Widget*>(this); }
+    operator const Gtk::Widget () { return *dynamic_cast<Gtk::Widget*>(this); }
 
 protected:
     RegisteredWidget() : W() { construct(); }
diff -urEw inkscape-0.48.2/src/ui/widget/spin-slider.cpp ./src/ui/widget/spin-slider.cpp
--- inkscape-0.48.2/src/ui/widget/spin-slider.cpp	2012-09-12 00:50:23.000000000 -0400
+++ ./src/ui/widget/spin-slider.cpp	2012-09-11 17:06:16.000000000 -0400
@@ -10,7 +10,7 @@
  * Released under GNU GPL.  Read the file 'COPYING' for more information.
  */
 
-#include "glib/gstrfuncs.h"
+#include <glib.h>
 #include "glibmm/i18n.h"
 
 #include "spin-slider.h"
diff -urEw inkscape-0.48.2/src/unclump.h ./src/unclump.h
--- inkscape-0.48.2/src/unclump.h	2012-09-12 00:50:23.000000000 -0400
+++ ./src/unclump.h	2012-09-11 16:14:14.000000000 -0400
@@ -11,7 +11,7 @@
 #ifndef SEEN_DIALOGS_UNCLUMP_H
 #define SEEN_DIALOGS_UNCLUMP_H
 
-#include <glib/gslist.h>
+#include <glib.h>
 
 void unclump(GSList *items);
 
diff -urEw inkscape-0.48.2/src/uri.h ./src/uri.h
--- inkscape-0.48.2/src/uri.h	2012-09-12 00:50:23.000000000 -0400
+++ ./src/uri.h	2012-09-11 16:14:14.000000000 -0400
@@ -14,7 +14,7 @@
 #ifndef INKSCAPE_URI_H
 #define INKSCAPE_URI_H
 
-#include <glib/gtypes.h>
+#include <glib.h>
 #include <exception>
 #include <libxml/uri.h>
 #include "bad-uri-exception.h"
diff -urEw inkscape-0.48.2/src/util/glib-list-iterators.h ./src/util/glib-list-iterators.h
--- inkscape-0.48.2/src/util/glib-list-iterators.h	2012-09-12 00:50:23.000000000 -0400
+++ ./src/util/glib-list-iterators.h	2012-09-11 16:23:47.000000000 -0400
@@ -17,8 +17,7 @@
 
 #include <cstddef>
 #include <iterator>
-#include "glib/gslist.h"
-#include "glib/glist.h"
+#include <glib.h>
 
 namespace Inkscape {
 
diff -urEw inkscape-0.48.2/src/util/share.cpp ./src/util/share.cpp
--- inkscape-0.48.2/src/util/share.cpp	2012-09-12 00:50:23.000000000 -0400
+++ ./src/util/share.cpp	2012-09-11 16:42:03.000000000 -0400
@@ -10,7 +10,7 @@
  */
 
 #include "util/share.h"
-#include <glib/gmessages.h>
+#include <glib.h>
 
 namespace Inkscape {
 namespace Util {
diff -urEw inkscape-0.48.2/src/version.cpp ./src/version.cpp
--- inkscape-0.48.2/src/version.cpp	2012-09-12 00:50:23.000000000 -0400
+++ ./src/version.cpp	2012-09-11 16:42:03.000000000 -0400
@@ -12,7 +12,7 @@
  */
 
 #include <stdio.h>
-#include <glib/gstrfuncs.h>
+#include <glib.h>
 #include "version.h"
 
 gboolean sp_version_from_string(const gchar *string, Inkscape::Version *version)
diff -urEw inkscape-0.48.2/src/version.h ./src/version.h
--- inkscape-0.48.2/src/version.h	2012-09-12 00:50:23.000000000 -0400
+++ ./src/version.h	2012-09-11 16:14:14.000000000 -0400
@@ -10,7 +10,7 @@
 #ifndef SEEN_INKSCAPE_VERSION_H
 #define SEEN_INKSCAPE_VERSION_H
 
-#include <glib/gtypes.h>
+#include <glib.h>
 
 #define SVG_VERSION "1.1"
 
diff -urEw inkscape-0.48.2/src/widgets/desktop-widget.h ./src/widgets/desktop-widget.h
--- inkscape-0.48.2/src/widgets/desktop-widget.h	2012-09-12 00:50:23.000000000 -0400
+++ ./src/widgets/desktop-widget.h	2012-09-11 16:17:09.000000000 -0400
@@ -239,7 +239,7 @@
 private:
     GtkWidget *tool_toolbox;
     GtkWidget *aux_toolbox;
-    GtkWidget *commands_toolbox,;
+    GtkWidget *commands_toolbox;
     GtkWidget *snap_toolbox;
 
     static void init(SPDesktopWidget *widget);
diff -urEw inkscape-0.48.2/src/widgets/icon.cpp ./src/widgets/icon.cpp
--- inkscape-0.48.2/src/widgets/icon.cpp	2012-09-12 00:50:23.000000000 -0400
+++ ./src/widgets/icon.cpp	2012-09-11 16:42:03.000000000 -0400
@@ -16,7 +16,7 @@
 #endif
 
 #include <cstring>
-#include <glib/gmem.h>
+#include <glib.h>
 #include <gtk/gtk.h>
 #include <gtkmm.h>
 
diff -urEw inkscape-0.48.2/src/widgets/sp-color-icc-selector.h ./src/widgets/sp-color-icc-selector.h
--- inkscape-0.48.2/src/widgets/sp-color-icc-selector.h	2012-09-12 00:50:23.000000000 -0400
+++ ./src/widgets/sp-color-icc-selector.h	2012-09-11 16:14:14.000000000 -0400
@@ -1,7 +1,7 @@
 #ifndef SEEN_SP_COLOR_ICC_SELECTOR_H
 #define SEEN_SP_COLOR_ICC_SELECTOR_H
 
-#include <glib/gtypes.h>
+#include <glib.h>
 #include <gtk/gtk.h>
 
 #include "../color.h"
diff -urEw inkscape-0.48.2/src/widgets/sp-color-scales.h ./src/widgets/sp-color-scales.h
--- inkscape-0.48.2/src/widgets/sp-color-scales.h	2012-09-12 00:50:23.000000000 -0400
+++ ./src/widgets/sp-color-scales.h	2012-09-11 16:14:14.000000000 -0400
@@ -1,7 +1,7 @@
 #ifndef SEEN_SP_COLOR_SCALES_H
 #define SEEN_SP_COLOR_SCALES_H
 
-#include <glib/gtypes.h>
+#include <glib.h>
 #include <gtk/gtk.h>
 
 #include <color.h>
diff -urEw inkscape-0.48.2/src/widgets/sp-color-wheel-selector.h ./src/widgets/sp-color-wheel-selector.h
--- inkscape-0.48.2/src/widgets/sp-color-wheel-selector.h	2012-09-12 00:50:23.000000000 -0400
+++ ./src/widgets/sp-color-wheel-selector.h	2012-09-11 16:14:14.000000000 -0400
@@ -1,7 +1,7 @@
 #ifndef SEEN_SP_COLOR_WHEEL_SELECTOR_H
 #define SEEN_SP_COLOR_WHEEL_SELECTOR_H
 
-#include <glib/gtypes.h>
+#include <glib.h>
 #include <gtk/gtk.h>
 
 #include "../color.h"
diff -urEw inkscape-0.48.2/src/widgets/spinbutton-events.h ./src/widgets/spinbutton-events.h
--- inkscape-0.48.2/src/widgets/spinbutton-events.h	2012-09-12 00:50:23.000000000 -0400
+++ ./src/widgets/spinbutton-events.h	2012-09-11 16:14:14.000000000 -0400
@@ -9,7 +9,7 @@
  * Released under GNU GPL, read the file 'COPYING' for more information
  */
 
-#include <glib/gtypes.h>
+#include <glib.h>
 #include <gtk/gtk.h>      /* GtkWidget */
 
 gboolean spinbutton_focus_in (GtkWidget *w, GdkEventKey *event, gpointer data);
diff -urEw inkscape-0.48.2/src/widgets/spw-utilities.h ./src/widgets/spw-utilities.h
--- inkscape-0.48.2/src/widgets/spw-utilities.h	2012-09-12 00:50:23.000000000 -0400
+++ ./src/widgets/spw-utilities.h	2012-09-11 16:14:14.000000000 -0400
@@ -18,7 +18,7 @@
    SPObject, that reacts to modification.
 */
 
-#include <glib/gtypes.h>
+#include <glib.h>
 
 typedef struct _GtkWidget GtkWidget;
 
diff -urEw inkscape-0.48.2/src/widgets/stroke-style.cpp ./src/widgets/stroke-style.cpp
--- inkscape-0.48.2/src/widgets/stroke-style.cpp	2012-09-12 00:50:23.000000000 -0400
+++ ./src/widgets/stroke-style.cpp	2012-09-11 16:42:03.000000000 -0400
@@ -18,7 +18,7 @@
 
 #define noSP_SS_VERBOSE
 
-#include <glib/gmem.h>
+#include <glib.h>
 #include <gtk/gtk.h>
 #include <glibmm/i18n.h>
 
diff -urEw inkscape-0.48.2/src/xml/attribute-record.h ./src/xml/attribute-record.h
--- inkscape-0.48.2/src/xml/attribute-record.h	2012-09-12 00:50:23.000000000 -0400
+++ ./src/xml/attribute-record.h	2012-09-11 16:14:15.000000000 -0400
@@ -5,8 +5,8 @@
 #ifndef SEEN_XML_SP_REPR_ATTR_H
 #define SEEN_XML_SP_REPR_ATTR_H
 
-#include <glib/gquark.h>
-#include <glib/gtypes.h>
+#include <glib.h>
+#include <glib.h>
 #include "gc-managed.h"
 #include "util/share.h"
 
diff -urEw inkscape-0.48.2/src/xml/comment-node.h ./src/xml/comment-node.h
--- inkscape-0.48.2/src/xml/comment-node.h	2012-09-12 00:50:23.000000000 -0400
+++ ./src/xml/comment-node.h	2012-09-11 16:14:15.000000000 -0400
@@ -15,7 +15,7 @@
 #ifndef SEEN_INKSCAPE_XML_COMMENT_NODE_H
 #define SEEN_INKSCAPE_XML_COMMENT_NODE_H
 
-#include <glib/gquark.h>
+#include <glib.h>
 #include "xml/simple-node.h"
 
 namespace Inkscape {
diff -urEw inkscape-0.48.2/src/xml/croco-node-iface.cpp ./src/xml/croco-node-iface.cpp
--- inkscape-0.48.2/src/xml/croco-node-iface.cpp	2012-09-12 00:50:23.000000000 -0400
+++ ./src/xml/croco-node-iface.cpp	2012-09-11 16:42:03.000000000 -0400
@@ -1,7 +1,7 @@
 
 #include <cstring>
 #include <string>
-#include <glib/gstrfuncs.h>
+#include <glib.h>
 
 #include "xml/croco-node-iface.h"
 #include "xml/node.h"
diff -urEw inkscape-0.48.2/src/xml/event.h ./src/xml/event.h
--- inkscape-0.48.2/src/xml/event.h	2012-09-12 00:50:23.000000000 -0400
+++ ./src/xml/event.h	2012-09-11 16:14:15.000000000 -0400
@@ -18,8 +18,8 @@
 #ifndef SEEN_INKSCAPE_XML_SP_REPR_ACTION_H
 #define SEEN_INKSCAPE_XML_SP_REPR_ACTION_H
 
-#include <glib/gtypes.h>
-#include <glib/gquark.h>
+#include <glib.h>
+#include <glib.h>
 #include <glibmm/ustring.h>
 
 #include <iterator>
diff -urEw inkscape-0.48.2/src/xml/node-event-vector.h ./src/xml/node-event-vector.h
--- inkscape-0.48.2/src/xml/node-event-vector.h	2012-09-12 00:50:23.000000000 -0400
+++ ./src/xml/node-event-vector.h	2012-09-11 16:14:15.000000000 -0400
@@ -14,7 +14,7 @@
 #ifndef SEEN_INKSCAPE_XML_SP_REPR_EVENT_VECTOR
 #define SEEN_INKSCAPE_XML_SP_REPR_EVENT_VECTOR
 
-#include <glib/gtypes.h>
+#include <glib.h>
 
 #include "xml/node.h"
 
diff -urEw inkscape-0.48.2/src/xml/node-observer.h ./src/xml/node-observer.h
--- inkscape-0.48.2/src/xml/node-observer.h	2012-09-12 00:50:23.000000000 -0400
+++ ./src/xml/node-observer.h	2012-09-11 16:14:15.000000000 -0400
@@ -18,7 +18,7 @@
 #ifndef SEEN_INKSCAPE_XML_NODE_OBSERVER_H
 #define SEEN_INKSCAPE_XML_NODE_OBSERVER_H
 
-#include <glib/gquark.h>
+#include <glib.h>
 #include "util/share.h"
 #include "xml/xml-forward.h"
 
diff -urEw inkscape-0.48.2/src/xml/node.h ./src/xml/node.h
--- inkscape-0.48.2/src/xml/node.h	2012-09-12 00:50:23.000000000 -0400
+++ ./src/xml/node.h	2012-09-11 16:14:15.000000000 -0400
@@ -18,7 +18,7 @@
 #ifndef SEEN_INKSCAPE_XML_NODE_H
 #define SEEN_INKSCAPE_XML_NODE_H
 
-#include <glib/gtypes.h>
+#include <glib.h>
 #include "gc-anchored.h"
 #include "util/list.h"
 #include "xml/xml-forward.h"
diff -urEw inkscape-0.48.2/src/xml/pi-node.h ./src/xml/pi-node.h
--- inkscape-0.48.2/src/xml/pi-node.h	2012-09-12 00:50:23.000000000 -0400
+++ ./src/xml/pi-node.h	2012-09-11 16:14:15.000000000 -0400
@@ -14,7 +14,7 @@
 #ifndef SEEN_INKSCAPE_XML_PI_NODE_H
 #define SEEN_INKSCAPE_XML_PI_NODE_H
 
-#include <glib/gquark.h>
+#include <glib.h>
 #include "xml/simple-node.h"
 
 namespace Inkscape {
diff -urEw inkscape-0.48.2/src/xml/quote.cpp ./src/xml/quote.cpp
--- inkscape-0.48.2/src/xml/quote.cpp	2012-09-12 00:50:23.000000000 -0400
+++ ./src/xml/quote.cpp	2012-09-11 16:42:03.000000000 -0400
@@ -12,7 +12,7 @@
  */
 
 #include <cstring>
-#include <glib/gmem.h>
+#include <glib.h>
 
 
 /** \return strlen(xml_quote_strdup(\a val)) (without doing the malloc).
diff -urEw inkscape-0.48.2/src/xml/rebase-hrefs.cpp ./src/xml/rebase-hrefs.cpp
--- inkscape-0.48.2/src/xml/rebase-hrefs.cpp	2012-09-12 00:50:23.000000000 -0400
+++ ./src/xml/rebase-hrefs.cpp	2012-09-11 16:42:03.000000000 -0400
@@ -7,9 +7,9 @@
 #include "util/share.h"
 #include "xml/attribute-record.h"
 #include "xml/node.h"
-#include <glib/gmem.h>
-#include <glib/gurifuncs.h>
-#include <glib/gutils.h>
+#include <glib.h>
+#include <glib.h>
+#include <glib.h>
 using Inkscape::XML::AttributeRecord;
 
 
diff -urEw inkscape-0.48.2/src/xml/rebase-hrefs.h ./src/xml/rebase-hrefs.h
--- inkscape-0.48.2/src/xml/rebase-hrefs.h	2012-09-12 00:50:23.000000000 -0400
+++ ./src/xml/rebase-hrefs.h	2012-09-11 16:14:15.000000000 -0400
@@ -1,7 +1,7 @@
 #ifndef REBASE_HREFS_H_SEEN
 #define REBASE_HREFS_H_SEEN
 
-#include <glib/gtypes.h>
+#include <glib.h>
 #include "util/list.h"
 #include "xml/attribute-record.h"
 struct SPDocument;
diff -urEw inkscape-0.48.2/src/xml/repr.h ./src/xml/repr.h
--- inkscape-0.48.2/src/xml/repr.h	2012-09-12 00:50:23.000000000 -0400
+++ ./src/xml/repr.h	2012-09-11 16:14:15.000000000 -0400
@@ -14,7 +14,8 @@
 #define __SP_REPR_H__
 
 #include <stdio.h>
-#include <glib/gtypes.h>
+#include "config.h"
+#include <glib.h>
 #include "gc-anchored.h"
 
 #include "xml/node.h"
diff -urEw inkscape-0.48.2/src/xml/simple-node.cpp ./src/xml/simple-node.cpp
--- inkscape-0.48.2/src/xml/simple-node.cpp	2012-09-12 00:50:23.000000000 -0400
+++ ./src/xml/simple-node.cpp	2012-09-11 16:42:03.000000000 -0400
@@ -16,7 +16,7 @@
 
 #include <cstring>
 #include <string>
-#include <glib/gstrfuncs.h>
+#include <glib.h>
 
 #include "xml/node.h"
 #include "xml/simple-node.h"
diff -urEw inkscape-0.48.2/src/xml/text-node.h ./src/xml/text-node.h
--- inkscape-0.48.2/src/xml/text-node.h	2012-09-12 00:50:23.000000000 -0400
+++ ./src/xml/text-node.h	2012-09-11 16:14:15.000000000 -0400
@@ -15,7 +15,7 @@
 #ifndef SEEN_INKSCAPE_XML_TEXT_NODE_H
 #define SEEN_INKSCAPE_XML_TEXT_NODE_H
 
-#include <glib/gquark.h>
+#include <glib.h>
 #include "xml/simple-node.h"
 
 namespace Inkscape {
