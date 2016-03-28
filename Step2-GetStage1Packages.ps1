# GNURadio Windows Build System
# Geof Nieboer

# script setup
$ErrorActionPreference = "Stop"

# setup helper functions
$mypath =  Split-Path $script:MyInvocation.MyCommand.Path
. $mypath\Setup.ps1 -Force

# Retrieve packages needed for Stage 1
cd $root/src-stage1-dependencies
SetLog "GetPackages"

break
# libzmq
getPackage https://github.com/zeromq/libzmq.git

# pyzmq
getPackage https://github.com/zeromq/pyzmq/archive/v14.7.0.zip 

if ($Config.BuildGTKFromSource) {

	# libpng
	getPackage ftp://ftp.simplesystems.org/pub/libpng/png/src/libpng16/libpng-1.6.21.tar.xz libpng
	getPatch libpng-1.6.21-vs2015.7z libpng\projects\vstudio-vs2015

	# libepoxy
	GetPackage https://github.com/anholt/libepoxy/archive/v1.3.1.tar.gz libepoxy

	# freetype
	GetPackage http://download.savannah.gnu.org/releases/freetype/freetype-2.6.3.tar.gz freetype
	GetPatch freetype-vc2015.7z freetype/builds/windows

	# Cairo
	GetPackage http://cairographics.org/releases/cairo-1.14.6.tar.xz cairo
	GetPatch cairo-vs2015.7z cairo/build

	# pixman
	GetPackage http://cairographics.org/releases/pixman-0.34.0.tar.gz pixman
	GetPatch pixman_vs2015.7z pixman/build

	# libffi
	GetPackage https://github.com/winlibs/libffi.git

	# libxml2 
	GetPackage https://git.gnome.org/browse/libxml2.git

	# JasPer 1900
	GetPackage http://www.ece.uvic.ca/~frodo/jasper/software/jasper-1.900.1.zip
	GetPatch jasper_vs2015.7z .\jasper-1.900.1\src

	# gettext
	GetPackage https://github.com/gnieboer/gettext-msvc.git
	GetPackage http://ftp.gnu.org/gnu/gettext/gettext-0.19.4.tar.gz
	GetPackage http://ftp.gnu.org/gnu/libiconv/libiconv-1.14.tar.gz
	cp gettext-0.19.4\* .\gettext-msvc\gettext-0.19.4 -Force -Recurse
	cp libiconv-1.14\* .\gettext-msvc\libiconv-1.14 -Force -Recurse
	del .\libiconv-1.14 -Force -Recurse
	del .\gettext-0.19.4 -Force -Recurse

	# glib
	GetPackage http://ftp.gnome.org/pub/GNOME/sources/glib/2.47/glib-2.47.6.tar.xz glib

	# atk
	GetPackage http://ftp.gnome.org/pub/GNOME/sources/atk/2.19/atk-2.19.90.tar.xz atk

	# pango
	GetPackage http://ftp.gnome.org/pub/GNOME/sources/pango/1.39/pango-1.39.0.tar.xz pango

	# gdk-pixbuf
	GetPackage http://ftp.gnome.org/pub/GNOME/sources/gdk-pixbuf/2.33/gdk-pixbuf-2.33.2.tar.xz gdk-pixbuf

} else {
	"NOT building GTK from source, retrieving GTK VS2015 binaries"
	GetPackage https://dl.hexchat.net/gtk-win32/vc14/x64/gtk-x64.7z
}
# SDL 1.2.15
getPackage  https://libsdl.org/release/SDL-1.2.15.zip
getPatch sdl-1.2.15-vs2015.7z SDL-1.2.15\VisualC

# portaudio v19
GetPackage http://portaudio.com/archives/pa_stable_v19_20140130.tgz
GetPatch portaudio_vs2015.7z portaudio/build/msvc
# asio SDK for portaudio
GetPatch asiosdk2.3.7z portaudio/src/hostapi/asio
# folder will already exist
if (!(Test-Path $root/packages/portaudio/asiosdk2.3.zip)) {
	Write-Host -NoNewLine "Retrieving ASIO SDK..."
	cd $root/packages/portaudio
	wget http://www.steinberg.net/sdk_downloads/asiosdk2.3.zip -OutFile asiosdk2.3.zip >> $Log 
	Write-Host -NoNewLine "download complete..."
} else {
	Write-Host -NoNewLine "ASIO SDK already present..."
}
if (!(Test-Path $root/src-stage1-dependencies/portaudio/src/hostapi/asio/asiosdk)) {
	$archive = "$root/packages/portaudio/asiosdk2.3.zip"
	$destination = "$root/src-stage1-dependencies/portaudio/src/hostapi/asio"
	[io.compression.zipfile]::ExtractToDirectory($archive, $destination) >> $Log 
	cd $destination
	ren asiosdk2.3 asiosdk
	"extracted"
}

# cppunit 1.12.1
GetPackage http://www.gcndevelopment.com/gnuradio/downloads/sources/cppunit-1.12.1.7z

# fftw3.3.5
GetPackage http://www.gcndevelopment.com/gnuradio/downloads/sources/fftw-3.3.5.7z

# python
GetPackage http://www.gcndevelopment.com/gnuradio/downloads/libraries/python27/python2710-x64-Source.7z
GetPatch python-pcbuild.vc14.zip python27/Python-2.7.10
GetPackage https://www.python.org/ftp/python/2.7.11/Python-2.7.11.tar.xz
# patch distutils because it doesn't correctly detect MSVC 14.0 / 2015
GetPatch python27_msvccompiler.7z python27\Python-2.7.10\Lib\distutils
GetPatch python27_msvccompiler.7z Python-2.7.11\Lib\distutils
GetPackage https://pypi.python.org/packages/source/s/setuptools/setuptools-20.1.1.zip
GetPackage https://pypi.python.org/packages/source/p/pip/pip-8.0.2.tar.gz
GetPackage https://pypi.python.org/packages/source/w/wheel/wheel-0.29.0.tar.gz

# zlib
# note: libpng is expecting zlib to be in a folder with the -1.2.8 version of the name
GetPackage https://github.com/gnieboer/zlib.git zlib-1.2.8

# libsodium
GetPackage https://github.com/gnieboer/libsodium.git 

# GSL
GetPackage http://www.gcndevelopment.com/gnuradio/downloads/sources/gsl-1.16.7z
GetPatch gsl-1.16.build.vc14.zip gsl-1.16

# openssl
$openssl_version = $Config.VersionInfo.openssl
GetPackage ftp://ftp.openssl.org/source/openssl-$openssl_version.tar.gz openssl
GetPatch openssl-vs14.zip openssl
mkdir $root\src-stage1-dependencies\openssl\build\intermediate\x64\Debug -Force >> $Log 
mkdir $root\src-stage1-dependencies\openssl\build\intermediate\x64\Release -Force >> $Log 
mkdir $root\src-stage1-dependencies\openssl\build\intermediate\x64\DebugDLL -Force >> $Log 
mkdir $root\src-stage1-dependencies\openssl\build\intermediate\x64\ReleaseDLL -Force >> $Log 
mkdir $root\src-stage1-dependencies\openssl\build\intermediate\x64\Release-AVX2 -Force >> $Log 
mkdir $root\src-stage1-dependencies\openssl\build\intermediate\x64\ReleaseDLL-AVX2 -Force >> $Log 

# Qt
GetPackage http://download.qt.io/official_releases/qt/4.8/4.8.7/qt-everywhere-opensource-src-4.8.7.tar.gz Qt4

# Boost
GetPackage http://downloads.sourceforge.net/project/boost/boost/1.60.0/boost_1_60_0.zip boost

# Qwt
$url = "http://downloads.sourceforge.net/project/qwt/qwt/" + $Config.VersionInfo.qwt + "/qwt-" + $Config.VersionInfo.qwt + ".zip"
GetPackage $url 
$dest = "qwt-" + $Config.VersionInfo.qwt
GetPatch qwtconfig.7z $dest

# sip
GetPackage http://sourceforge.net/projects/pyqt/files/sip/sip-4.17/sip-4.17.zip

# PyQt
GetPackage http://downloads.sourceforge.net/project/pyqt/PyQt4/PyQt-4.11.4/PyQt-win-gpl-4.11.4.zip PyQt4

# PyQwt
GetPackage https://github.com/PyQwt/PyQwt5/archive/master.zip

# Cython
GetPackage http://cython.org/release/Cython-0.23.4.zip

# numpy 1.10.4
GetPackage https://github.com/numpy/numpy/archive/v1.10.4.zip

# scipy 0.17.0
GetPackage https://github.com/scipy/scipy/releases/download/v0.17.0/scipy-0.17.0.tar.xz scipy

# pyopengl 3.1.0
GetPackage https://pypi.python.org/packages/source/P/PyOpenGL/PyOpenGL-3.1.0.tar.gz

# pyopengl-accelerate 3.1.0
GetPackage https://pypi.python.org/packages/source/P/PyOpenGL-accelerate/PyOpenGL-accelerate-3.1.0.tar.gz

# pygobject
GetPackage http://ftp.gnome.org/pub/GNOME/sources/pygobject/2.28/pygobject-2.28.6.tar.xz
GetPatch gtk-pkgconfig.7z x64/lib
GetPatch runtests-windows.7z pygobject-2.28.6\tests

# PyGTK
GetPackage http://ftp.gnome.org/pub/GNOME/sources/pygtk/2.24/pygtk-2.24.0.tar.gz
GetPackage https://git.gnome.org/browse/pygtk/snapshot/PYGTK_2_22_0_WINDOWS.tar.xz

# py2cairo
GetPackage http://cairographics.org/releases/py2cairo-1.10.0.tar.bz2
GetPatch py2cairo-1.10.0.7z py2cairo-1.10.0

# pkgconfig
GetPackage https://pypi.python.org/packages/source/p/pkgconfig/pkgconfig-1.1.0.tar.gz
GetPackage http://downloads.sourceforge.net/project/pkgconfiglite/0.28-1/pkg-config-lite-0.28-1_bin-win32.zip

# wxpython
GetPackage http://downloads.sourceforge.net/wxpython/wxPython-src-3.0.2.0.tar.bz2 wxpython
GetPatch wxpython_vs2015_patch.7z wxpython

# cheetah 2.4.4
GetPackage https://pypi.python.org/packages/source/C/Cheetah/Cheetah-2.4.4.tar.gz

# libusb 1.0.20
GetPackage https://github.com/libusb/libusb/releases/download/v1.0.20/libusb-1.0.20.tar.bz2 libusb
GetPatch libusb_VS2015.7z libusb

# UHD
GetPackage git://github.com/EttusResearch/uhd.git

# libxslt
GetPackage https://git.gnome.org/browse/libxslt/snapshot/CVE-2015-7995.tar.xz libxslt

# lxml
GetPackage git://github.com/lxml/lxml.git 

# pthreads
GetPackage http://www.gcndevelopment.com/gnuradio/sources/pthreads-w32-2-9-1-release.7z pthreads
GetPatch pthreads.2.7z pthreads/pthreads.2

# openblas
if (!$Config.BuildNumpyWithMKL) {
	GetPackage https://github.com/xianyi/OpenBLAS.git 
}

# lapack reference build
if (!$Config.BuildNumpyWithMKL) {
	GetPackage http://www.netlib.org/lapack/lapack-3.6.0.tgz lapack
	GetPatch lapack_3.6.0.7z lapack/SRC
}

# cleanup

# return to original directory
cd $root/scripts