require 'formula'

class PangoQuartz < Formula
  homepage 'http://www.pango.org/'
  url 'http://ftp.gnome.org/pub/GNOME/sources/pango/1.36/pango-1.36.2.tar.xz'
  sha256 'f07f9392c9cf20daf5c17a210b2c3f3823d517e1917b72f20bb19353b2bc2c63'

  depends_on :x11
  depends_on 'pkg-config' => :build
  depends_on 'glib'
  depends_on 'harfbuzz'
  depends_on 'fontconfig'
  depends_on 'acornejo/quartz/cairo-quartz'

  fails_with :llvm do
    build 2326
    cause "Undefined symbols when linking"
  end

  def install
    args = %W[
      --disable-dependency-tracking
      --disable-silent-rules
      --prefix=#{prefix}
      --enable-man
      --with-html-dir=#{share}/doc
      --disable-introspection
      --without-x
      --without-xft
    ]

    system "./configure", *args
    system "make"
    system "make install"
  end
end
