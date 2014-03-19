require 'formula'

class InkscapeQuartz < Formula
  homepage 'http://www.inkscape.org'
  url "http://bazaar.launchpad.net/~inkscape.dev/inkscape/trunk/", :revision => '13165', :using => :bzr
  version 'trunk-r13165'

  # Inkscape is a meaty bastard.
  depends_on 'pkg-config' => :build
  depends_on 'intltool' => :build
  depends_on 'boost-build' => :build
  depends_on :autoconf
  depends_on :automake
  depends_on 'bdw-gc'
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
  
  def install
    ENV.prepend 'CXXFLAGS', '-std=c++11'
    ENV.prepend 'LIBS', '-liconv'
    args = ["--enable-osxapp", "--disable-dependency-tracking", "--prefix=#{prefix}"]
    system "./autogen.sh && ./configure", *args
    system "make install"
  end
end
