require "formula"

class Vapoursynth < Formula
  url  'https://github.com/vapoursynth/vapoursynth/archive/R26.tar.gz'
  sha1 '8c170c44179f1c8f42332ec3ec446f87a8694ec5'
  homepage "http://www.vapoursynth.com"
  head "https://github.com/vapoursynth/vapoursynth.git"

  needs :cxx11
  depends_on 'pkg-config' => :build
  depends_on 'autoconf' => :build
  depends_on 'automake' => :build
  depends_on 'libtool' => :build
  depends_on 'yasm' => :build
  depends_on :python3

  depends_on 'ffmpeg'
  depends_on 'tesseract'

  option 'with-official-libass', 'Use official version of libass'

  if build.with? 'official-libass'
    depends_on 'libass' => 'with-harfbuzz'
  else
    depends_on 'elsie--/homebrew-mpvhq/libass-ct'
  end

  resource 'cython' do
    url 'https://pypi.python.org/packages/source/C/Cython/Cython-0.21.2.tar.gz'
    md5 'd21adb870c75680dc857cd05d41046a4'
    sha1 'c3fe3dd5693aa09719ee4a3bcec898068c82592d'
  end

  def install
    add_python_paths
    ohai "installing Cython to: #{libexec}"
    resource('cython').stage { system "python3", "setup.py", "install", "--prefix=#{libexec}" }
    args = [ "--prefix=#{prefix}" ]
    system "./autogen.sh"
    system "./configure", *args
    system "make install"
  end

  private
  def add_python_paths
    ENV.prepend_create_path 'PYTHONPATH', libexec/"lib/python#{pyver}/site-packages"
    ENV.prepend_create_path 'PATH', libexec/'bin'
    python_prefix = Pathname.new(`python3-config --prefix`.chomp)
    ENV.append_path "PKG_CONFIG_PATH", python_prefix / 'lib' / 'pkgconfig'
  end

  def pyver
    Language::Python.major_minor_version Formula['python3'].bin/'python3'
  end
end
