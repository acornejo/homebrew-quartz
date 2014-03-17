require 'formula'

class InkscapeQuartz < Formula
  homepage 'http://www.inkscape.org'
  url "http://bazaar.launchpad.net/~inkscape.dev/inkscape/trunk/", :revision => '12219', :using => :bzr
  version 'trunk-r12219'

  # Inkscape is a meaty bastard.
  depends_on 'pkg-config' => :build
  depends_on 'intltool' => :build
  depends_on 'boost-build' => :build
  depends_on :autoconf
  depends_on :automake
  depends_on :x11
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
  
  # fails_with :clang

  def install
    ENV.x11
    # ENV.prepend 'CXXFLAGS', '-std=c++11'
    args = ["--disable-debug", "--disable-dependency-tracking", "--prefix=#{prefix}"]
    system "./autogen.sh"
    system "./configure", *args
    system "make install"
  end
end
