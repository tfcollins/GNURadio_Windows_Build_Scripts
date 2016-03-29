# GNURadio Windows Build System
#
# Geof Nieboer
#
# NOTES:
# Each module is designed to be run independently, so sometimes variables
# are set redundantly.  This is to enable easier debugging if one package needs to be re-run
#

# script setup
$ErrorActionPreference = "Stop"

# setup helper functions and variables
$mypath =  Split-Path $script:MyInvocation.MyCommand.Path
. $mypath\Setup.ps1 -Force

# EVERYTHING ABOVE THIS LINE NEEDS TO BE RUN ONCE BEFORE BUILDING ANY PACKAGES

$debug = {

# Build packages needed for Stage 1
cd src-stage1-dependencies

# ____________________________________________________________________________________________________________
# libpng 
# uses zlib but incorporates the source directly so doesn't need to be built after zlib
SetLog "libpng"
Write-Host -NoNewline "building libpng..."
cd $root\src-stage1-dependencies\libpng\projects\vstudio-vs2015
msbuild vstudio.sln /m /p:"configuration=Debug;platform=x64" >> $Log 
msbuild vstudio.sln /m /p:"configuration=Debug Library;platform=x64" >> $Log
msbuild vstudio.sln /m /p:"configuration=Release;platform=x64" >> $Log
msbuild vstudio.sln /m /p:"configuration=Release Library;platform=x64" >> $Log
msbuild vstudio.sln /m /p:"configuration=Release-AVX2;platform=x64" >> $Log
msbuild vstudio.sln /m /p:"configuration=Release Library-AVX2;platform=x64" >> $Log
Validate "x64/Debug/libpng16.dll" "x64/Debug Library/libpng16.lib" "x64/Release/libpng16.dll" "x64/Release Library/libpng16.lib" "x64/Release-AVX2/libpng16.dll" "x64/Release Library-AVX2/libpng16.lib"


# ____________________________________________________________________________________________________________
# zlib
SetLog "zlib"
Write-Host -NoNewline "Building zlib..."
cd $root\src-stage1-dependencies\zlib-1.2.8/contrib/vstudio/vc14
msbuild zlibvc.sln /m /p:"configuration=Release;platform=x64" >> $Log
msbuild zlibvc.sln /m /p:"configuration=Debug;platform=x64" >> $Log
msbuild zlibvc.sln /m /p:"configuration=Release-AVX2;platform=x64" >> $Log
msbuild zlibvc.sln /m /p:"configuration=ReleaseWithoutAsm;platform=x64" >> $Log
msbuild zlibvc.sln /m /p:"configuration=ReleaseWithoutAsm;platform=Win32" >> $Log
msbuild zlibvc.sln /m /p:"configuration=Release;platform=Win32" >> $Log
msbuild zlibvc.sln /m /p:"configuration=Debug;platform=Win32" >> $Log
msbuild zlibvc.sln /m /p:"configuration=Release-AVX2;platform=Win32" >> $Log
Validate "x64/ZlibDllDebug/zlibwapi.dll" "x64/ZlibDllRelease/zlibwapi.dll" "x64/ZlibDllRelease-AVX2/zlibwapi.dll" "x64/ZlibDllReleaseWithoutAsm/zlibwapi.dll" `
	"x64/ZlibStatDebug/zlib.dll" "x64/ZlibStatRelease/zlib.lib" "x64/ZlibStatRelease-AVX2/zlib.lib" "x64/ZlibStatReleaseWithoutAsm/zlib.lib"


if ($Config.BuildGTKFromSource) {

	# __________________________________________________________________
	# freetype
	# freetype is only ever used as a static library, no AVX2
	# ignore the multi/single threaded options as they build against static runtime libs
	SetLog "freetype"
	Write-Host -NoNewline "building freetype..."
	cd $root\src-stage1-dependencies\freetype\builds\windows\vc2015
	msbuild freetype.sln /p:"configuration=Release;platform=x64" >> $Log
	msbuild freetype.sln /p:"configuration=Debug;platform=x64" >> $Log
	"complete"

	# __________________________________________________________________
	# pixman
	SetLog "pixman"
	Write-Host -NoNewline "building pixman..."
	cd $root\src-stage1-dependencies\pixman\build
	msbuild .\pixman.sln /p:"configuration=Debug;platform=x64" >> $Log
	msbuild .\pixman.sln /p:"configuration=DebugDLL;platform=x64" >> $Log
	msbuild .\pixman.sln /p:"configuration=Release;platform=x64" >> $Log
	msbuild .\pixman.sln /p:"configuration=ReleaseDLL;platform=x64" >> $Log
	msbuild .\pixman.sln /p:"configuration=Release-AVX2;platform=x64" >> $Log
	msbuild .\pixman.sln /p:"configuration=ReleaseDLL-AVX2;platform=x64" >> $Log
	"complete"

	# __________________________________________________________________
	# cairo
	# must be after pixman, zlib, libpng, and freetype
	SetLog "cairo"
	Write-Host -NoNewline "building cairo..."
	cd $root\src-stage1-dependencies\cairo\build
	msbuild .\cairo.sln /p:"configuration=Debug;platform=x64" >> $Log
	msbuild .\cairo.sln /p:"configuration=DebugDLL;platform=x64" >> $Log
	msbuild .\cairo.sln /p:"configuration=Release;platform=x64" >> $Log
	msbuild .\cairo.sln /p:"configuration=ReleaseDLL;platform=x64" >> $Log
	msbuild .\cairo.sln /p:"configuration=Release-AVX2;platform=x64" >> $Log
	msbuild .\cairo.sln /p:"configuration=ReleaseDLL-AVX2;platform=x64" >> $Log
	"complete"

	# __________________________________________________________________
	# get-text / libiconv / libintl
	SetLog "gettext"
	Write-Host -NoNewline "building gettext..."
	cd $root\src-stage1-dependencies\gettext-msvc
	msbuild .\gettext.sln /p:"configuration=Debug;platform=x64" >> $Log
	msbuild .\gettext.sln /p:"configuration=DebugDLL;platform=x64" >> $Log
	msbuild .\gettext.sln /p:"configuration=Release;platform=x64" >> $Log
	msbuild .\gettext.sln /p:"configuration=ReleaseDLL;platform=x64" >> $Log
	msbuild .\gettext.sln /p:"configuration=Release-AVX2;platform=x64" >> $Log
	msbuild .\gettext.sln /p:"configuration=ReleaseDLL-AVX2;platform=x64" >> $Log
	 "complete"

	# __________________________________________________________________
	# libffi
	SetLog "libffi"
	Write-Host -NoNewline "building libffi..."
	cd $root\src-stage1-dependencies\libffi\win32\vc14_x64
	msbuild .\libffi-msvc.sln /p:"configuration=Debug;platform=x64" >> $Log
	msbuild .\libffi-msvc.sln /p:"configuration=Release;platform=x64" >> $Log
	 "complete"

	# __________________________________________________________________
	# libxml2
	# must be after libiconv
	SetLog "libxml2"
	Write-Host -NoNewline "building libxml2..."
	cd $root\src-stage1-dependencies\libxml2\win32
	# libxml is looking for slightly different filename than what is generated by default
	cp ..\..\gettext-msvc\x64\Debug\libiconv.lib ..\..\gettext-msvc\x64\Debug\iconv.lib
	cp ..\..\zlib-1.2.8\contrib\vstudio\vc14\x64\ZlibStatDebug\zlibstat.lib ..\..\zlib-1.2.8\contrib\vstudio\vc14\x64\ZlibStatDebug\zlib.lib
	cp ..\..\gettext-msvc\x64\Release\libiconv.lib ..\..\gettext-msvc\x64\Release\iconv.lib
	cp ..\..\zlib-1.2.8\contrib\vstudio\vc14\x64\ZlibStatRelease\zlibstat.lib ..\..\zlib-1.2.8\contrib\vstudio\vc14\x64\ZlibStatRelease\zlib.lib
	$ErrorActionPreference = "Continue"
	# the "static" option builds the test programs statically link, not relevant to the libraries
	& cscript.exe configure.js iconv=yes compiler=msvc zlib=yes python=yes cruntime=/MDd  debug=yes prefix="..\build\x64\Debug" static=no lib="..\..\gettext-msvc\x64\Debug;..\..\zlib-1.2.8\contrib\vstudio\vc14\x64\ZLibStatDebug" include="..\..\gettext-msvc\libiconv-1.14;..\..\zlib-1.2.8" >> $Log
	nmake Makefile.msvc libxml install >> $Log
	nmake clean >> $Log
	& cscript.exe configure.js iconv=yes compiler=msvc zlib=yes python=yes cruntime=/MD  debug=no prefix="..\build\x64\Release" static=no lib="..\..\gettext-msvc\x64\Release;..\..\zlib-1.2.8\contrib\vstudio\vc14\x64\ZLibStatRelease" include="..\..\gettext-msvc\libiconv-1.14;..\..\zlib-1.2.8" >> $Log
	nmake Makefile.msvc libxml install >> $Log
	nmake clean >> $Log
	& cscript.exe configure.js iconv=yes compiler=msvc zlib=yes python=yes cruntime="/MD /arch:AVX2"  debug=no prefix="..\build\x64\Release-AVX2" static=no lib="..\..\gettext-msvc\x64\Release;..\..\zlib-1.2.8\contrib\vstudio\vc14\x64\ZLibStatRelease" include="..\..\gettext-msvc\libiconv-1.14;..\..\zlib-1.2.8" >> $Log
	nmake Makefile.msvc libxml install >> $Log
	nmake clean >> $Log
	$ErrorActionPreference = "Stop"
	"complete"

	# __________________________________________________________________
	# JasPer
	# static only build
	SetLog "jasper"
	Write-Host -NoNewline "building jasper..."
	cd $root\src-stage1-dependencies\jasper-1.900.1\src\msvc14
	msbuild .\jasper.sln /p:"configuration=Debug;platform=x64" >> $Log
	msbuild .\jasper.sln /p:"configuration=Release;platform=x64" >> $Log
	msbuild .\jasper.sln /p:"configuration=Release-AVX2;platform=x64" >> $Log
	"complete"

	# __________________________________________________________________
	# glib
	# THIS IS NOT YET WORKING
	# Everything above does at least build, this is the point where
	# the result wasn't worth the squeeze since Hexchat has exactly what
	# we need (VS2015 binaries) for a stack that is non-trivial to build
	# someday will revisit in order to add AVX2 options but again, not 
	# work the effort since the priority is a native build of GNURadio 
	# first and foremost.
	SetLog "glib"
	Write-Host -NoNewline "building glib..."
	cd $root\src-stage1-dependencies\glib\build\win32\vs14
	$GlibEtcInstallRoot = "..\..\..\..\gtk-build\x64\Release"
	New-Item -ItemType Directory -Force -Path $GlibEtcInstallRoot  >> $Log
	New-Item -ItemType Directory -Force -Path $GlibEtcInstallRoot\include >> $Log
	New-Item -ItemType Directory -Force -Path $GlibEtcInstallRoot\lib >> $Log
	$ErrorActionPreference = "Continue"
	$env:_CL_ = "/I$root/src-stage1-dependencies/glib/glib/pcre /MD"
	$env:LIB = "$root\src-stage1-dependencies\x64\lib;" + $oldlib
	msbuild .\glib.vcxproj /p:"configuration=Release;platform=x64;glibetcinstallroot=$GlibEtcInstallRoot" >> $Log
	$ErrorActionPreference = "Stop"
	"complete"

} else {
	# no action needed here if we are using the binaries.
	# if we use the premade build environment from hexchat, that
	# would replace the above code.
}
# ____________________________________________________________________________________________________________
# SDL
SetLog "SDL"
Write-Host -NoNewline "building SDL..."
cd $root\src-stage1-dependencies\sdl-$sdl_version\VisualC
msbuild .\sdl.sln /m /p:"configuration=Debug;platform=x64" >> $Log
msbuild .\sdl.sln /m /p:"configuration=Release-AVX2;platform=x64" >> $Log
msbuild .\sdl.sln /m /p:"configuration=Release;platform=x64" >> $Log
Validate "x64/Debug/SDL.dll" "x64/Release/SDL.dll" "x64/Release-AVX2/SDL.dll"

# ____________________________________________________________________________________________________________
# portaudio
SetLog "portaudio"
Write-Host -NoNewline "building portaudio..."
cd $root\src-stage1-dependencies\portaudio\build\msvc
msbuild .\portaudio.vcxproj /m /p:"configuration=Debug;platform=x64" >> $Log
msbuild .\portaudio.vcxproj /m /p:"configuration=Debug-Static;platform=x64" >> $Log
msbuild .\portaudio.vcxproj /m /p:"configuration=Release;platform=x64" >> $Log
msbuild .\portaudio.vcxproj /m /p:"configuration=Release-Static;platform=x64" >> $Log
msbuild .\portaudio.vcxproj /m /p:"configuration=Release-AVX2;platform=x64" >> $Log
msbuild .\portaudio.vcxproj /m /p:"configuration=Release-Static-AVX2;platform=x64" >> $Log
Validate "x64/Debug/portaudio_x64.dll" "x64/Release/portaudio_x64.dll" "x64/Release-AVX2/portaudio_x64.dll" `
	"x64/Debug-Static/portaudio.lib" "x64/Release-Static/portaudio.lib" "x64/Release-Static-AVX2/portaudio.lib"

# ____________________________________________________________________________________________________________
# cppunit
SetLog "cppunit"
Write-Host -NoNewline "building cppunit..."
cd $root\src-stage1-dependencies\cppunit-$cppunit_version\src >> $Log
msbuild .\CppUnitLibraries.sln /m /p:"configuration=Debug;platform=x64" >> $Log
msbuild .\CppUnitLibraries.sln /m /p:"configuration=Release;platform=x64" >> $Log
Validate "x64/Debug/dll/cppunit.dll" "x64/Release/dll/cppunit.dll" "x64/Debug/lib/cppunit.lib" "x64/Release/lib/cppunit.lib"

# ____________________________________________________________________________________________________________
# fftw3
SetLog "fftw3"
Write-Host -NoNewline "building fftw3..."
cd $root\src-stage1-dependencies\fftw-$fftw_version\msvc
msbuild .\fftw-3.3-libs.sln /m /p:"configuration=Debug;platform=x64" >> $Log
msbuild .\fftw-3.3-libs.sln /m /p:"configuration=Debug DLL;platform=x64" >> $Log
msbuild .\fftw-3.3-libs.sln /m /p:"configuration=Release;platform=x64" >> $Log
msbuild .\fftw-3.3-libs.sln /m /p:"configuration=Release DLL;platform=x64" >> $Log
msbuild .\fftw-3.3-libs.sln /m /p:"configuration=Release-AVX2;platform=x64" >> $Log 
msbuild .\fftw-3.3-libs.sln /m /p:"configuration=Release DLL-AVX2;platform=x64" >> $Log
Validate "x64/Release/libfftwf-3.3.lib" "x64/Release-AVX2/libfftwf-3.3.lib" "x64/Debug/libfftwf-3.3.lib" `
	"x64/ReleaseDLL/libfftwf-3.3.DLL" "x64/ReleaseDLL-AVX2/libfftwf-3.3.DLL" "x64/DebugDLL/libfftwf-3.3.DLL" 

# ____________________________________________________________________________________________________________
# openssl (python depends on this)
SetLog "openssl"
Write-Host -NoNewline "building openssl..."
cd $root/src-stage1-dependencies/openssl
# The TEST target will not only build but also test
# Note, it appears the static libs are still linked to the /MT runtime
# don't change config names because they are linked to python's config names below
msbuild openssl.vcxproj /m /t:"Build" /p:"configuration=Debug;platform=x64" >> $Log
msbuild openssl.vcxproj /m /t:"Build" /p:"configuration=DebugDLL;platform=x64" >> $Log
msbuild openssl.vcxproj /m /t:"Build" /p:"configuration=Release;platform=x64" >> $Log
msbuild openssl.vcxproj /m /t:"Build" /p:"configuration=Release-AVX2;platform=x64" >> $Log
msbuild openssl.vcxproj /m /t:"Build" /p:"configuration=ReleaseDLL;platform=x64" >> $Log
msbuild openssl.vcxproj /m /t:"Build" /p:"configuration=ReleaseDLL-AVX2;platform=x64" >> $Log
Validate "build/x64/Release/ssleay32.lib" "build/x64/Release-AVX2/ssleay32.lib" "build/x64/Debug/ssleay32.lib" `
	"build/x64/ReleaseDLL/libeay32.DLL" "build/x64/ReleaseDLL-AVX2/libeay32.DLL" "build/x64/DebugDLL/libeay32.DLL" `
	"build/x64/Release/libeay32.lib" "build/x64/Release-AVX2/libeay32.lib" "build/x64/Debug/libeay32.lib" `
	"build/x64/ReleaseDLL/ssleay32.DLL" "build/x64/ReleaseDLL-AVX2/ssleay32.DLL" "build/x64/DebugDLL/ssleay32.DLL" 

# ____________________________________________________________________________________________________________
# python (boost depends on this)
# FIXME need to handle the detection in msvc9compiler.py since MS skipped a MSVC version
SetLog "python"
Write-Host -NoNewline "building core python..."
cd $root/src-stage1-dependencies/python27/Python-2.7.10/PCbuild.vc14
msbuild pcbuild.sln /m /p:"configuration=Debug;platform=x64" >> $Log
msbuild pcbuild.sln /m /p:"configuration=Release;platform=x64" >> $Log
msbuild pcbuild.sln /m /p:"configuration=Release-AVX2;platform=x64" >> $Log
Validate "amd64/_ssl.pyd" "amd64/_ctypes.pyd" "amd64/_tkinter.pyd" "amd64/python.exe" "amd64/python27.dll" `
	"amd64-avx2/_ssl.pyd" "amd64-avx2/_ctypes.pyd" "amd64-avx2/_tkinter.pyd" "amd64-avx2/python.exe" "amd64-avx2/python27.dll" `
	"amd64/_ssl_d.pyd" "amd64/_ctypes_d.pyd" "amd64/_tkinter_d.pyd" "amd64/python_d.exe" "amd64/python27_d.dll" 

# now place the binaries where we need them
# install the main python and minimal dependencies
Function gatherPython {

	New-Item -ItemType Directory -Force -Path $pythonroot >> $Log
	New-Item -ItemType Directory -Force -Path $pythonroot/DLLs >> $Log
	New-Item -ItemType Directory -Force -Path $pythonroot/Libs >> $Log
	New-Item -ItemType Directory -Force -Path $pythonroot/Docs >> $Log 
	New-Item -ItemType Directory -Force -Path $pythonroot/lib >> $Log
	New-Item -ItemType Directory -Force -Path $pythonroot/lib/site-packages >> $Log
	New-Item -ItemType Directory -Force -Path $pythonroot/tcl >> $Log
	$env:Path = $pythonroot+ ";$OLD_PATH"

	# no DOCs dir
	# copy the files
	# amd64 for regular build (release and debug combined), amd64-avx for release AVX2 build
	if (Test-Path .\python_d.exe) {cp python_d.exe $pythonroot} 
	if (Test-Path .\pythonw_d.exe) {cp pythonw_d.exe $pythonroot}
	if (Test-Path .\python27_d.dll) {cp python27_d.dll $pythonroot}
	cp python.exe $pythonroot
	cp pythonw.exe $pythonroot
	cp python27.dll $pythonroot
	cp *.pyd $pythonroot/DLLs
	cp *.dll $pythonroot/DLLs
	cp *.lib $pythonroot/libs
	cp *.pdb $pythonroot/libs
	cp ../../PC/py.ico $pythonroot/DLLs
	cp ../../PC/pyc.ico $pythonroot/DLLs
	cp -r -fo ../../Tools $pythonroot
	cp -r -fo ../../../tcltk64/lib/*.* $pythonroot/tcl
	cp -r -fo ../../Include $pythonroot
	cp ../../PC/pyconfig.h $pythonroot/Include
	cp ../../README $pythonroot/README.txt
	cp ../../LICENSE $pythonroot/LICENSE.txt
	cp -r -fo ../../Lib/bsddb $pythonroot/Lib
	cp -r -fo ../../Lib/compiler $pythonroot/Lib
	cp -r -fo ../../Lib/ctypes $pythonroot/Lib
	cp -r -fo ../../Lib/curses $pythonroot/Lib
	cp -r -fo ../../Lib/distutils $pythonroot/Lib
	cp -fo $pythonroot/lib/distutils/command/wininst-9.0-amd64.exe $pythonroot/lib/distutils/command/wininst-14.0-amd64.exe
	cp -r -fo ../../Lib/email $pythonroot/Lib
	cp -r -fo ../../Lib/encodings $pythonroot/Lib
	cp -r -fo ../../Lib/hotshot $pythonroot/Lib
	cp -r -fo ../../Lib/idlelib $pythonroot/Lib
	cp -r -fo ../../Lib/importlib $pythonroot/Lib
	cp -r -fo ../../Lib/json $pythonroot/Lib
	cp -r -fo ../../Lib/lib2to3 $pythonroot/Lib
	cp -r -fo ../../Lib/lib-tk $pythonroot/Lib
	cp -r -fo ../../Lib/logging $pythonroot/Lib
	cp -r -fo ../../Lib/msilib $pythonroot/Lib
	cp -r -fo ../../Lib/multiprocessing $pythonroot/Lib
	cp -r -fo ../../Lib/pydoc_data $pythonroot/Lib
	cp -r -fo ../../Lib/sqlite3 $pythonroot/Lib
	cp -r -fo ../../Lib/test $pythonroot/Lib
	cp -r -fo ../../Lib/unittest $pythonroot/Lib
	cp -r -fo ../../Lib/wsgiref $pythonroot/Lib
	cp -r -fo ../../Lib/xml $pythonroot/Lib
	cp ../../Lib/*.* $pythonroot/Lib

	# then install key packages
	$env:Path = $pythonroot+ ";$oldpath"
	# these packages will give warnings about files not found that will be errors on powershell if set to "Stop"
	$ErrorActionPreference = "Continue"
	cd $root/src-stage1-dependencies/setuptools-20.1.1
	& $pythonroot\$pythonexe setup.py install --single-version-externally-managed --root=/ 2>&1  >> $Log
	cd $root/src-stage1-dependencies/pip-8.0.2
	& $pythonroot\$pythonexe setup.py install 2>&1 >> $Log
	cd $root\src-stage1-dependencies/wheel-0.29.0
	& $pythonroot\$pythonexe setup.py install 2>&1 >> $Log
	# TODO do we really need virtualenv since this will be a standalone distro?  Probably not
	# cd $root/src-stage1-dependencies/python27/virtualenv-13.1.0
	# & $pythonroot\python.exe setup.py install
	$ErrorActionPreference = "Stop"
}

Write-Host -NoNewline "staging core python..." 
$pythonexe = "python.exe"
$pythonroot = "$root\src-stage2-python\gr-python27"
cd $root/src-stage1-dependencies/python27/Python-2.7.10/PCbuild.vc14/amd64
GatherPython
$pythonroot = "$root\src-stage2-python\gr-python27-avx2"
cd $root/src-stage1-dependencies/python27/Python-2.7.10/PCbuild.vc14/amd64-avx2
GatherPython
$pythonexe = "python_d.exe"
$pythonroot = "$root\src-stage2-python\gr-python27-debug"
cd $root/src-stage1-dependencies/python27/Python-2.7.10/PCbuild.vc14/amd64
GatherPython
"complete"


# ____________________________________________________________________________________________________________
# boost
SetLog "boost"
Write-Host -NoNewline "building boost..."
cd $root/src-stage1-dependencies/boost
cmd /c "bootstrap.bat" >> $Log
# point boost build to our custom python libraries
$doubleroot = $root -replace "\\", "\\"
Add-Content .\project-config.jam "`nusing python : 2.7 : $doubleroot\\src-stage2-python\\gr-python27\\python.exe : $doubleroot\\src-stage2-python\\gr-python27\\Include : $doubleroot\\src-stage2-python\\gr-python27\\Libs ;"
# always rebuild all because boost will reuse objects from a previous build with different command line options
# Optimized static+shared release libraries
cmd /c 'b2.exe -a --build-type=minimal --prefix=build\avx2\Release --libdir=build\avx2\Release\lib --includedir=build\avx2\Release\include --stagedir=build\avx2\Release --layout=versioned address-model=64 threading=multi link=static,shared variant=release cxxflags="/arch:AVX2 /Ox /Zi" cflags="/arch:AVX2 /Ox /Zi" install' >> $Log
# Regular  static+shared release libraries
cmd /c 'b2.exe -a --build-type=minimal --prefix=build\x64\Release --libdir=build\x64\Release\lib --includedir=build\x64\Release\include --stagedir=build\x64\Release --layout=versioned address-model=64 threading=multi link=static,shared variant=release cxxflags="-Zi" cflags="-Zi" install' >> $Log
# Regular  static+shared debug libraries
cmd /c 'b2.exe -a --build-type=minimal --prefix=build\x64\Debug --libdir=build\x64\Debug\lib --includedir=build\x64\Debug\include --stagedir=build\x64\Debug --layout=versioned address-model=64 threading=multi link=static,shared variant=debug cxxflags="-Zi" cflags="-Zi" install' >> $Log
Validate "build/x64/Debug/lib/boost_python-vc140-mt-gd-1_60.dll" "build/x64/Debug/lib/boost_system-vc140-mt-gd-1_60.dll" `
	"build/x64/Release/lib/boost_python-vc140-mt-1_60.dll" "build/x64/Release/lib/boost_system-vc140-mt-1_60.dll" `
	"build/avx2/Release/lib/boost_python-vc140-mt-1_60.dll" "build/avx2/Release/lib/boost_system-vc140-mt-1_60.dll"

# ____________________________________________________________________________________________________________
# libsodium
# must be before libzmq
SetLog "libsodium"
Write-Host -NoNewline "building libsodium..."
cd $root/src-stage1-dependencies/libsodium
cd builds\msvc\build
& .\buildbase.bat ..\vs2015\libsodium.sln 14 >> $Log
cd ../../../bin/x64
Validate "Release/v140/dynamic/libsodium.dll" "Release/v140/static/libsodium.lib" "Release/v140/ltcg/libsodium.lib" `
	"Debug/v140/dynamic/libsodium.dll" "Debug/v140/static/libsodium.lib" "Debug/v140/ltcg/libsodium.lib"

# ____________________________________________________________________________________________________________
# libzmq
# must be after libsodium
SetLog "libzmq"
Write-Host -NoNewline "building libzmq..."
cd $root/src-stage1-dependencies/libzmq/builds/msvc
& .\configure.bat
cd build
& .\buildbase.bat ..\vs2015\libzmq.sln 14 >> $Log
cd ../../../bin/x64
Validate "Release/v140/dynamic/libzmq.dll" "Release/v140/static/libzmq.lib" "Release/v140/ltcg/libzmq.lib" `
	"Debug/v140/dynamic/libzmq.dll" "Debug/v140/static/libzmq.lib" "Debug/v140/ltcg/libzmq.lib"

# ____________________________________________________________________________________________________________
# gsl
SetLog "gsl"
Write-Host -NoNewline "building gsl..."
cd $root/src-stage1-dependencies/gsl-$gsl_version/build.vc14
#prep headers
msbuild gsl.lib.sln /t:gslhdrs >> $Log
#static
msbuild gsl.lib.sln /m /t:cblaslib /t:gsllib /maxcpucount /p:"configuration=Release;platform=x64"  >> $Log
msbuild gsl.lib.sln /m /t:cblaslib /t:gsllib /maxcpucount /p:"configuration=Debug;platform=x64"  >> $Log
msbuild gsl.lib.sln /m /t:cblaslib /t:gsllib /maxcpucount /p:"configuration=Release-AVX2;platform=x64"  >> $Log
msbuild gsl.lib.sln /m /t:cblaslib /t:gsllib /maxcpucount /p:"configuration=Release;platform=Win32"  >> $Log
msbuild gsl.lib.sln /m /t:cblaslib /t:gsllib /maxcpucount /p:"configuration=Debug;platform=Win32"  >> $Log
msbuild gsl.lib.sln /m /t:cblaslib /t:gsllib /maxcpucount /p:"configuration=Release-AVX2;platform=Win32"  >> $Log
#dll
msbuild gsl.dll.sln /m /t:gslhdrs /p:Configuration="Debug" /p:Platform="Win32" >> $Log
msbuild gsl.dll.sln /m /t:cblasdll /t:gsldll /maxcpucount /p:"configuration=Release;platform=x64"  >> $Log
msbuild gsl.dll.sln /m /t:cblasdll /t:gsldll /maxcpucount /p:"configuration=Debug;platform=x64"  >> $Log
msbuild gsl.dll.sln /m /t:cblasdll /t:gsldll /maxcpucount /p:"configuration=Release-AVX2;platform=x64"  >> $Log
msbuild gsl.dll.sln /m /t:cblasdll /t:gsldll /maxcpucount /p:"configuration=Release;platform=Win32"  >> $Log
msbuild gsl.dll.sln /m /t:cblasdll /t:gsldll /maxcpucount /p:"configuration=Debug;platform=Win32"  >> $Log
msbuild gsl.dll.sln /m /t:cblasdll /t:gsldll /maxcpucount /p:"configuration=Release-AVX2;platform=Win32"  >> $Log
Validate "x64/Debug/dll/gsl.dll" "x64/Debug/dll/cblas.dll" "x64/Debug/lib/gsl.lib" "x64/Debug/lib/cblas.lib" `
	"x64/Release/dll/gsl.dll" "x64/Release/dll/cblas.dll" "x64/Release/lib/gsl.lib" "x64/Release/lib/cblas.lib" `
	"x64/Release-AVX2/dll/gsl.dll" "x64/Release-AVX2/dll/cblas.dll" "x64/Release-AVX2/lib/gsl.lib" "x64/Release-AVX2/lib/cblas.lib" 

# ____________________________________________________________________________________________________________
# qt4
# must be after openssl
SetLog "Qt4"
Write-Host "building Qt4..."
Function MakeQt 
{
	$type = $args[0]
	Write-Host -NoNewline "$type...configuring..."
	$ssltype = ($type -replace "Dll", "") -replace "-AVX2", ""
	$flags = if ($type -match "Debug") {"-debug"} else {"-release"}
	$staticflag = if ($type -match "Dll") {""} else {"-static"}
	if ($type -match "AVX2") {$env:CL = "/Ox /arch:AVX2 " + $oldcl} else {$env:CL = $oldCL}
	New-Item -ItemType Directory -Force -Path $root/src-stage1-dependencies/Qt4/build/$type/bin >> $Log
	cp -Force $root\src-stage1-dependencies/Qt4/bin/qmake.exe $root/src-stage1-dependencies/Qt4/build/$type/bin
	.\configure.exe $flags $staticflag -prefix $root/src-stage1-dependencies/Qt4/build/$type -platform win32-msvc2015 -opensource -confirm-license -qmake -ltcg -nomake examples -nomake network -nomake demos -nomake tools -nomake sql -no-script -no-scripttools -no-qt3support -sse2 -directwrite -mp -qt-libpng -qt-libjpeg -opengl desktop -graphicssystem opengl -no-webkit -qt-sql-sqlite -plugin-sql-sqlite -openssl -L "$root\src-stage1-dependencies\openssl\build\x64\Debug" -l ssleay32 -l libeay32 -l crypt32 -l kernel32 -l user32 -l gdi32 -l winspool -l comdlg32 -l advapi32 -l shell32 -l ole32 -l oleaut32 -l uuid -l odbc32 -l odbccp32 -l advapi32 OPENSSL_LIBS="-L$root\src-stage1-dependencies\openssl\build\x64\$ssltype -lssleay32 -llibeay32" -I "$root\src-stage1-dependencies\openssl\build\x64\$ssltype\Include" -make nmake  2>&1 >> $Log
	Write-Host -NoNewline "building..."
	nmake 2>&1 >> $Log
	Write-Host -NoNewline "installing..."
	nmake install 2>&1 >> $Log 
	nmake confclean 2>&1 >> $Log
	Write-Host "done"
}
# TODO find/copy over vc140.pdb
cd $root/src-stage1-dependencies/Qt4
# Various things in Qt4 build are intepreted as errors so 
$ErrorActionPreference = "Continue"
$env:QMAKESPEC = "$root/src-stage1-dependencies/Qt4/mkspecs/win32-msvc2015"
$env:QTDIR = "$root/src-stage1-dependencies/Qt4"
$env:Path = "$root\src-stage1-dependencies\Qt4\bin;" + $oldPath
# Qt doesn't do a great job of allowing reconfiguring, so we go a little overkill
# with the "extra strong" cleaning routines.
# even this doesn't always work (50%??) so your best bet really is to wipe the Qt4 folder every time you rebuild.
# more experimentation needed.
if (Test-Path $root/src-stage1-dependencies/Qt4/Makefile) 
{
	nmake clean 2>&1 >> $Log
	nmake confclean 2>&1 >> $Log
	nmake distclean 2>&1 >> $Log
}
# The below configure builds the base qmake.exe in the "root" directory and will point the environment to the main source tree.  Then the following build commands will convince Qt to build in a different directory
# while still using the original as the source base.  THIS IS A HACK.  Qt4 does not like there to be more than one build on the same machine and is very troublesome in that regard.
# if there are build fails, wipe the whole Qt4 directory and start over.  confclean doesn't do everything it promises.
.\configure.exe -opensource -confirm-license -platform win32-msvc2015 -qmake -make nmake -prefix .  -nomake examples -nomake network -nomake demos -nomake tools -nomake sql -no-script -no-scripttools -no-qt3support -sse2 -directwrite -mp 2>&1 >> $Log
nmake confclean 2>&1 >> $Log
# debugDLL build
MakeQT "DebugDLL"
# releaseDLL build
MakeQT "ReleaseDLL"
# debug static build
MakeQT "Debug"
# switch to AVX2 mode
# release AVX2 static build
MakeQT "Release-AVX2"
# release AVX2 DLL build
MakeQT "ReleaseDLL-AVX2"
# do release last because that's the "default" config, and qmake does some strange things
# like save the last config persistently and globally.
MakeQT "Release"

#clean up enormous amount of temp files
nmake clean  2>&1>> $Log
nmake distclean 2>&1 >> $Log
Validate "build/DebugDLL/bin/qmake.exe" "build/DebugDLL/lib/QtCored.dll" "build/DebugDLL/lib/QtOpenGLd.dll" "build/DebugDLL/lib/QtSvgd.dll" "build/DebugDLL/lib/QtGuid.dll" `
	"build/Releasedll/bin/qmake.exe" "build/Releasedll/lib/QtCore.dll" "build/Releasedll/lib/QtOpenGL.dll" "build/Releasedll/lib/QtSvg.dll" "build/Releasedll/lib/QtGui.dll" `
	"build/Releasedll-AVX2/bin/qmake.exe" "build/Releasedll-AVX2/lib/QtCore.dll" "build/Releasedll-AVX2/lib/QtOpenGL.dll" "build/Releasedll-AVX2/lib/QtSvg.dll" "build/Releasedll-AVX2/lib/QtGui.dll" 

# ____________________________________________________________________________________________________________
# QWT 5.2.3
# must be after Qt
# all those cleans are important because like Qt, QMAKE does a terrible job of cleaning up makefiles and configs
# when building in more than one configuration
# Also note that 4 builds go into a single folder... because debug and release libraries have different names
# and the static/dll libs have different names, so no conflict...
# Note that even the static builds are linking against the DLL builds of Qt.  This is important, PyQwt will
# fail with 10 linker errors otherwise.
SetLog "Qwt"
Write-Host -NoNewline "building qwt..."
Function MakeQwt {
	nmake /NOLOGO clean 2>&1 >> $Log
	nmake /NOLOGO distclean 2>&1 >> $Log
	Invoke-Expression $command 2>&1 >> $Log
	nmake /NOLOGO 2>&1 >>  $Log
	nmake /NOLOGO install 2>&1 >> $Log
}
$ErrorActionPreference = "Continue"
$env:QMAKESPEC = "win32-msvc2015"
cd $root\src-stage1-dependencies\qwt-5.2.3 
$command = "$root\src-stage1-dependencies\Qt4\build\DebugDLL\bin\qmake.exe qwt.pro ""CONFIG-=release_with_debuginfo"" ""CONFIG+=debug"" ""PREFIX=$root/src-stage1-dependencies/qwt-5.2.3/build/x64/Debug-Release"" ""MAKEDLL=NO"" ""AVX2=NO"""
MakeQwt
$command = "$root\src-stage1-dependencies\Qt4\build\DebugDLL\bin\qmake.exe qwt.pro ""CONFIG+=debug"" ""PREFIX=$root/src-stage1-dependencies/qwt-5.2.3/build/x64/Debug-Release"" ""MAKEDLL=YES"" ""AVX2=NO"""
MakeQwt
$command = "$root\src-stage1-dependencies\Qt4\build\ReleaseDLL\bin\qmake.exe qwt.pro ""CONFIG-=debug"" ""CONFIG+=release_with_debuginfo"" ""PREFIX=$root/src-stage1-dependencies/qwt-5.2.3/build/x64/Debug-Release"" ""MAKEDLL=NO"" ""AVX2=NO"""
MakeQwt
$command = "$root\src-stage1-dependencies\Qt4\build\ReleaseDLL\bin\qmake.exe qwt.pro ""CONFIG+=release_with_debuginfo"" ""PREFIX=$root/src-stage1-dependencies/qwt-5.2.3/build/x64/Debug-Release"" ""MAKEDLL=YES"" ""AVX2=NO"""
MakeQwt

$env:CL = "/Ox /arch:AVX2 /Zi /Gs- " + $oldCL
$command = "$root\src-stage1-dependencies\Qt4\build\ReleaseDLL-AVX2\bin\qmake.exe qwt.pro ""CONFIG+=release_with_debuginfo"" ""PREFIX=$root/src-stage1-dependencies/qwt-5.2.3/build/x64/Release-AVX2"" ""MAKEDLL=NO"" ""AVX2=YES"""
MakeQwt
$command = "$root\src-stage1-dependencies\Qt4\build\ReleaseDLL-AVX2\bin\qmake.exe qwt.pro ""CONFIG+=release_with_debuginfo"" ""PREFIX=$root/src-stage1-dependencies/qwt-5.2.3/build/x64/Release-AVX2"" ""MAKEDLL=YES"" ""AVX2=YES"""
MakeQwt

$env:CL = $oldCL
$ErrorActionPreference = "Stop"
Validate "build/x64/Debug-Release/lib/qwtd.lib" "build/x64/Debug-Release/lib/qwtd5.dll" "build/x64/Debug-Release/lib/qwt5.dll" "build/x64/Debug-Release/lib/qwt.lib" `
	"build/x64/Release-AVX2/lib/qwt5.dll" "build/x64/Release-AVX2/lib/qwt.lib"

# ____________________________________________________________________________________________________________
# Mako
# Mako is a python-only package can be installed automatically
# used by UHD drivers
#
SetLog "Mako"
Write-Host -NoNewline "installing Mako using pip..."
$ErrorActionPreference = "Continue" # pip will "error" if there is a new version available
$pythonroot = "$root\src-stage2-python\gr-python27"
& $pythonroot/Scripts/pip.exe install mako 2>&1 >> $log
$pythonroot = "$root\src-stage2-python\gr-python27-debug"
& $pythonroot/Scripts/pip.exe install mako 2>&1 >> $log
$pythonroot = "$root\src-stage2-python\gr-python27-avx2"
& $pythonroot/Scripts/pip.exe install mako 2>&1 >> $log
$ErrorActionPreference = "Stop"
"complete"

# ____________________________________________________________________________________________________________
# libusb
#
# 
#
SetLog "libusb"
Write-Host -NoNewline "building libusb..."
cd $root\src-stage1-dependencies\libusb\msvc
Write-Host -NoNewline "Debug..."
msbuild .\libusb_2015.sln /m /p:"configuration=Debug;platform=x64" >> $Log
Write-Host -NoNewline "Release..."
msbuild .\libusb_2015.sln /m /p:"configuration=Release;platform=x64" >> $Log
Write-Host -NoNewline "Release-AVX2..."
msbuild .\libusb_2015.sln /m /p:"configuration=Release-AVX2;platform=x64" >> $Log 
Validate "../x64/Debug/dll/libusb-1.0.dll" "../x64/Debug/lib/libusb-1.0.lib" `
	"../x64/Release/dll/libusb-1.0.dll" "../x64/Release/lib/libusb-1.0.lib" `
	"../x64/Release-AVX2/dll/libusb-1.0.dll" "../x64/Release-AVX2/lib/libusb-1.0.lib"

# ____________________________________________________________________________________________________________
# UHD 3.9.2
#
# requires libsub, boost, python, mako
#

SetLog "UHD"
Write-Host "building uhd..."
$ErrorActionPreference = "Continue"
cd $root\src-stage1-dependencies\uhd\host
New-Item -ItemType Directory -Force -Path .\build  2>&1 >> $Log
cd build 

Function makeUHD {
	$configuration = $args[0]
	Write-Host -NoNewline "Configuring $configuration..."
	if ($configuration -match "AVX2") {$platform = "avx2"; $env:_CL_ = "/arch:AVX2"} else {$platform = "x64"; $env:_CL_ = ""}
	if ($configuration -match "Release") {$boostconfig = "Release"; $pythonexe = "python.exe"} else {$boostconfig = "Debug"; $pythonexe = "python_d.exe"}

	& cmake .. `
		-G "Visual Studio 14 2015 Win64" `
		-DPYTHON_EXECUTABLE="$pythonroot\$pythonexe" `
		-DBoost_INCLUDE_DIR="$root/src-stage1-dependencies/boost/build/$platform/$boostconfig/include/boost-1_60" `
		-DBoost_LIBRARY_DIR="$root/src-stage1-dependencies/boost/build/$platform/$boostconfig/lib" `
		-DLIBUSB_INCLUDE_DIRS="$root/src-stage1-dependencies/libusb/libusb" `
		-DLIBUSB_LIBRARIES="$root/src-stage1-dependencies/libusb/x64/$configuration/lib/libusb-1.0.lib" 2>&1 >> $Log 
	Write-Host -NoNewline "building..."
	msbuild .\UHD.sln /m /p:"configuration=$configuration;platform=x64" 2>&1 >> $Log 
	Write-Host -NoNewline "installing..."
	& cmake -DCMAKE_INSTALL_PREFIX="$root/src-stage1-dependencies/uhd\dist\$configuration" -DBUILD_TYPE="$boostconfig" -P cmake_install.cmake 2>&1 >> $Log
	New-Item -ItemType Directory -Path $root/src-stage1-dependencies/uhd\dist\$configuration\share\uhd\examples\ -Force
	cp -Recurse -Force $root/src-stage1-dependencies/uhd/host/build/examples/$configuration/* $root/src-stage1-dependencies/uhd\dist\$configuration\share\uhd\examples\
	Validate "..\..\dist\$configuration\bin\uhd.dll" "..\..\dist\$configuration\lib\uhd.lib" "..\..\dist\$configuration\include\uhd.h"
}

# AVX2 build
$pythonroot = "$root\src-stage2-python\gr-python27-avx2"
makeUHD "Release-AVX2"

# Release build
$pythonroot = "$root\src-stage2-python\gr-python27"
makeUHD "Release"

# Debug build
$pythonroot = "$root\src-stage2-python\gr-python27-debug"
makeUHD "Debug"


# ____________________________________________________________________________________________________________
# libxslt 1.1.28 w/ CVE-2015-7995 patch
#
# uses libxml, zlib, and iconv
SetLog "libxslt"
Write-Host "building libxslt..."
$ErrorActionPreference = "Continue"
cd $root\src-stage1-dependencies\libxslt\win32
function MakeXSLT {
	$configuration = $args[0]
	Write-Host -NoNewline "$configuration..."
	if ($configuration -match "Debug") {$de="yes"} else {$de="no"}
	& nmake /NOLOGO clean 2>&1 >> $Log 
	Write-Host -NoNewline "configuring..."
	& cscript configure.js zlib=yes compiler=msvc cruntime="/MD" static=yes prefix=..\build\$configuration include="../../libxml2/include;../../gettext-msvc/libiconv-1.14" lib="../../libxml2/build/x64/$configuration/lib;../../gettext-msvc/x64/$configuration;../../zlib-1.2.8/contrib/vstudio/vc14/x64/ZlibStat$configuration" debug=$de 2>&1 >> $Log 
	Write-Host -NoNewline "building..." 
	& nmake /NOLOGO 2>&1 >> $Log 
	Write-Host -NoNewline "installing..."
	& nmake /NOLOGO install 2>&1 >> $Log 
	Move-Item -Path ..\build\$configuration\bin\libexslt.pdb ..\build\$configuration\lib
	Move-Item -Path ..\build\$configuration\bin\libxslt.pdb ..\build\$configuration\lib
	Validate "..\build\$configuration\lib\libxslt.dll" "..\build\$configuration\lib\libxslt_a.lib"
}
MakeXSLT "Release"
MakeXSLT "Release-AVX2"
MakeXSLT "Debug"
$ErrorActionPreference = "Stop"

# ____________________________________________________________________________________________________________
# pthreads
#
SetLog "pthreads"
Write-Host "building pthreads..."
$ErrorActionPreference = "Continue"
cd $root\src-stage1-dependencies\pthreads\pthreads.2
Write-Host -NoNewline "Debug..."
msbuild .\pthread.sln /m /p:"configuration=Debug;platform=x64" >> $Log
Write-Host -NoNewline "DLL..."
msbuild .\pthread.sln /m /p:"configuration=DebugDLL;platform=x64" >> $Log
Write-Host -NoNewline "Release..."
msbuild .\pthread.sln /m /p:"configuration=Release;platform=x64" >> $Log
Write-Host -NoNewline "DLL..."
msbuild .\pthread.sln /m /p:"configuration=ReleaseDLL;platform=x64" >> $Log
Write-Host -NoNewline "Release-AVX2..."
msbuild .\pthread.sln /m /p:"configuration=Release-AVX2;platform=x64" >> $Log 
Write-Host -NoNewline "DLL..."
msbuild .\pthread.sln /m /p:"configuration=ReleaseDLL-AVX2;platform=x64" >> $Log 
Validate "x64\Debug\pthreadVC2.lib" "x64\Release\pthreadVC2.lib" "x64\Release-AVX2\pthreadVC2.lib" `
	"x64\DebugDLL\pthreadVC2.dll" "x64\ReleaseDLL\pthreadVC2.dll" "x64\ReleaseDLL-AVX2\pthreadVC2.dll"

# ____________________________________________________________________________________________________________
# openblas
#
# for the moment this only generates a DLL.  The CMAKE code is too immature to support anything else at this point
# TODO make a static lib
# Also note that openblas will be slow as the assembly code is not used because it's not in MSVC format
# TODO upgrade openblas asm format
# openblas lapack and lapacke have a ton of external errors during build
# TODO build patch for modified CMAKE
if (!$BuildNumpyWithMKL) {
	SetLog "openblas"
	Write-Host "starting openblas..."
	function MakeOpenBLAS {
		$ErrorActionPreference = "Continue"
		$configuration = $args[0]
		if ($configuration -match "Debug") {$cmakebuildtype = "Debug"; $debug="ON"} else {$cmakebuildtype = "Release"; $debug="OFF"}
		if ($configuration -match "AVX2") {$env:_CL_ = " -D__64BIT__ /arch:AVX2 "} else {$env:_CL_ = " -D__64BIT__ "}
		Write-Host -NoNewline "configuring $configuration..."
		New-Item -ItemType Directory -Force $root\src-stage1-dependencies\OpenBLAS\build\$configuration 2>&1 >> $Log 
		cd $root\src-stage1-dependencies\openblas\build\$configuration
		cmake ..\..\ `
			-Wno-dev `
			-G "Visual Studio 14 Win64" `
			-DTARGET="HASWELL" `
			-DBUILD_DEBUG="$debug" `
			-DF_COMPILER="INTEL" `
			-DCMAKE_Fortran_COMPILER="ifort" `
			-DCMAKE_Fortran_FLAGS=" /assume:underscore /names:lowercase " `
			-DNO_LAPACKE="1" `
			-DNO_LAPACK="1"  2>&1 >> $Log 
		$env:__INTEL_POST_FFLAGS = " /assume:underscore /names:lowercase "
		Write-Host -NoNewline "building..."
		msbuild .\OpenBLAS.sln /m /p:"configuration=$cmakebuildtype;platform=x64" 2>&1 >> $Log 
		cp $root\src-stage1-dependencies\OpenBLAS\build\$configuration\lib\$cmakebuildtype\libopenblas.lib $root\src-stage1-dependencies\OpenBLAS\build\$configuration\lib\libopenblas_static.lib 2>&1 >> $Log 
		$env:_CL_ = ""
		$env:__INTEL_POST_FFLAGS = ""
		Validate "lib\libopenblas.lib" "lib\libopenblas.dll" "lib\libopenblas_static.lib"
		$ErrorActionPreference = "Stop"
	}
	MakeOpenBlas "Debug"
	MakeOpenBlas "Release"
	MakeOpenBlas "Release-AVX2"
}

# ____________________________________________________________________________________________________________
# lapack
#
# like scipy, this requires a fortran compiler to be installed, and gfortran doesn't work well with MSVC
# so there isn't a free option, we look for Intel Fortran Compiler during setup.
# Don't despair though, if not fort then we'll just download binary wheels later.
# There is a bug in 3.6.0 where a library is misspelled and will give an error (zerbla vs xerbla in zgetrf2.f @ line 147, it is fixed in the SVN
if (!$BuildNumpyWithMKL -and $hasIFORT) {
	SetLog "lapack"
	Write-Host -NoNewline "starting lapack..."
	function MakeLapack {
		$ErrorActionPreference = "Continue"
		$configuration = $args[0]
		if ($configuration -match "Debug") {$cmakebuildtype = "Debug"} else {$cmakebuildtype = "Release"}
		if ($configuration -match "AVX2") {$env:_CL_ = " /arch:AVX2 "} else {$env:_CL_ = ""}
		Write-Host -NoNewline "configuring $configuration..."
		New-Item -ItemType Directory -Force $root\src-stage1-dependencies\lapack\build\$configuration 2>&1 >> $Log 
		cd $root\src-stage1-dependencies\lapack\build\$configuration
		cmake ..\..\ `
			-Wno-dev `
			-G "Visual Studio 14 Win64" `
			-DCMAKE_BUILD_TYPE="$cmakebuildtype" `
			-DPYTHON_EXECUTABLE="$pythonroot\$pythonexe" `
			-DCMAKE_INSTALL_PREFIX="$root/src-stage1-dependencies/lapack/dist/$configuration/" `
			-DCMAKE_Fortran_FLAGS=" /assume:underscore /names:lowercase " 2>&1 >> $Log 
		$env:__INTEL_POST_FFLAGS = " /assume:underscore /names:lowercase "
		Write-Host -NoNewline "building..."
		# use devenv instead of msbuild because of vfproj files unsupported by msbuild
		devenv .\lapack.sln /project lapack /rebuild "$cmakebuildtype|x64"  2>&1 >> $Log 
		devenv .\lapack.sln /project blas /rebuild "$cmakebuildtype|x64"  2>&1 >> $Log 
		Write-Host -NoNewline "packaging..."
		# don't run the INSTALL vcproj because it will fail because the dependencies won't link
		cmake -DBUILD_TYPE="$cmakebuildtype" -P cmake_install.cmake 2>&1 >> $Log 
		$env:_CL_ = ""
		$env:__INTEL_POST_FFLAGS = ""
		Validate "../../dist/$configuration/lib/blas.lib" "../../dist/$configuration/lib/lapack.lib"
	}
	MakeLapack "Debug"
	MakeLapack "Release"
	MakeLapack "Release-AVX2"
}