require 'formula'

class PopplerData < Formula
  url 'http://poppler.freedesktop.org/poppler-data-0.4.5.tar.gz'
  md5 '448dd7c5077570e340340706cef931aa'
end

class PopplerQuartz < Formula
  homepage 'http://poppler.freedesktop.org/'
  url 'http://poppler.freedesktop.org/poppler-0.24.5.tar.xz'
  sha1 '7b7cabee85bd81a7e55c939740d5d7ccd7c0dda5'

  depends_on 'pkg-config' => :build
  depends_on 'glib'
  depends_on 'acornejo/quartz/cairo-quartz'

  keg_only 'This formula builds Poppler for use with Quartz instead of X11, which is experimental.'

  def install
    args = ["--disable-dependency-tracking", "--prefix=#{prefix}", "--enable-xpdf-headers", '--enable-poppler-glib', '--disable-poppler-qt4']

    system "./configure", *args
    system "make install"

    # Install poppler font data.
    PopplerData.new.brew do
      system "make install prefix=#{prefix}"
    end
  end
end
