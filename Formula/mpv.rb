require 'formula'

class JackOSX < Requirement
  fatal true

  env do
    ENV.append 'CFLAGS',  '-I/usr/local/include'
    ENV.append 'LDFLAGS', '-L/usr/local/lib -ljack -framework CoreAudio -framework CoreServices -framework AudioUnit'
  end

  def satisfied?
    which('jackd')
  end
end

class Mpv < Formula
  url 'https://github.com/mpv-player/mpv/archive/v0.7.2.tar.gz'
  sha1 '756cbc08f7770e2b3b2236f1907cb85ea1543155'
  head 'https://github.com/mpv-player/mpv.git',
    :branch => ENV['MPV_BRANCH'] || "master"
  homepage 'https://github.com/mpv-player/mpv'

  depends_on 'pkg-config' => :build
  depends_on :python

  option 'with-official-libass', 'Use official version of libass (instead of experimental CoreText based branch)'
  option 'with-libmpv',          'Build shared library.'
  option 'without-optimization', 'Disable compiler optimization.'
  option 'without-bundle',       'Disable compilation of a Mac OS X Application bundle.'
  option 'with-jackosx',         'Build with jackosx support.'
  option 'without-zsh-comp',     'Install without zsh completion'

  if build.with? 'official-libass'
    depends_on 'libass' => 'with-harfbuzz'
  else
    depends_on 'mpv-player/mpv/libass-ct' => 'with-harfbuzz'
  end

  depends_on 'ffmpeg'

  depends_on 'mpg123'      => :recommended
  depends_on 'jpeg'        => :recommended

  depends_on 'libcaca'     => :optional
  depends_on 'libbs2b'     => :optional
  depends_on 'libdvdread'  => :optional
  depends_on 'libdvdnav'   => :optional
  depends_on 'little-cms2' => :recommended
  depends_on 'lua'         => :recommended
  depends_on 'libbluray'   => :optional
  depends_on 'libaacs'     => :optional
  depends_on :x11          => :optional
  depends_on 'vapoursynth' => :optional

  depends_on 'python3' if build.with? 'vapoursynth'
  depends_on JackOSX.new if build.with? 'jackosx'

  if build.head?
    WAF_VERSION = "waf-1.8.4".freeze
    WAF_SHA1    = "42b36fabac41ab6f14ccb4808bd9ec87149a37a9".freeze
  else
    WAF_VERSION = "waf-1.8.1".freeze
    WAF_SHA1    = "1d0a1cc1e0b490deae5b500201c1b0e44a908a45".freeze
  end

  resource 'waf' do
    url "http://ftp.waf.io/pub/release/#{WAF_VERSION}"
    sha1 WAF_SHA1
  end

  resource 'docutils' do
    url 'https://pypi.python.org/packages/source/d/docutils/docutils-0.11.tar.gz'
    sha1 '3894ebcbcbf8aa54ce7c3d2c8f05460544912d67'
  end

  def caveats
    bundle_caveats if build.with? 'bundle'
  end

  def install
    ENV.prepend_create_path 'PYTHONPATH', libexec/'lib/python2.7/site-packages'
    ENV.prepend_create_path 'PATH', libexec/'bin'
    ENV.append 'LC_ALL', 'en_US.UTF-8'
    resource('docutils').stage { system "python", "setup.py", "install", "--prefix=#{libexec}" }
    bin.env_script_all_files(libexec/'bin', :PYTHONPATH => ENV['PYTHONPATH'])

    if build.with? 'vapoursynth'
      pyver = Language::Python.major_minor_version Formula['python3'].bin/'python3'
      ENV.append_path 'PKG_CONFIG_PATH', Formula['python3'].frameworks/'Python.framework/Versions'/pyver/'lib/pkgconfig'
    end

    args = [ "--prefix=#{prefix}" ]
    args << "--enable-jack" if build.with? 'jackosx'
    args << "--enable-libmpv-shared" << "--disable-client-api-examples" if build.with? "libmpv"
    args << "--disable-optimize" if build.without? "optimization" and build.head?
    args << "--enable-zsh-comp" if build.with? "zsh-comp"

    # For running version.sh correctly
    buildpath.install_symlink cached_download/".git" if build.head?
    buildpath.install resource('waf').files(WAF_VERSION => "waf")
    system "python", "waf", "configure", *args
    system "python", "waf", "install"

    if build.with? 'bundle'
      ohai "creating a OS X Application bundle"
      system "python", "TOOLS/osxbundle.py", "build/mpv"
      prefix.install "build/mpv.app"
    end
  end

  private
  def bundle_caveats; <<-EOS.undent
    mpv.app installed to:
      #{prefix}

    To link the application to a normal Mac OS X location:
        brew linkapps
    or:
        ln -s #{prefix}/mpv.app /Applications
    EOS
  end
end
