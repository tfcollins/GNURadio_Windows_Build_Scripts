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
# can't run when we "run selection" in VS2015 since we aren't in a directory
if ($script -ne $null) {
	$mypath =  Split-Path $script:MyInvocation.MyCommand.Path
	Import-Module $mypath\Functions.psm1 -Force
}

Setup

# EVERYTHING ABOVE THIS LINE NEEDS TO BE RUN ONCE BEFORE BUILDING ANY PACKAGES
#break

# Build packages needed for Stage 1
cd src-stage1-dependencies

# ____________________________________________________________________________________________________________
# libpng 
# uses zlib but incorporates the source directly so doesn't need to be built after zlib
SetLog "03-libpng"
Write-Host -NoNewline "building libpng..."
cd $root\src-stage1-dependencies\libpng\projects\vstudio-vs2015
msbuild vstudio.sln /p:"configuration=Debug;platform=x64" >> $Log 
msbuild vstudio.sln /p:"configuration=Debug Library;platform=x64" >> $Log
msbuild vstudio.sln /p:"configuration=Release;platform=x64" >> $Log
msbuild vstudio.sln /p:"configuration=Release Library;platform=x64" >> $Log
msbuild vstudio.sln /p:"configuration=Release-AVX2;platform=x64" >> $Log
msbuild vstudio.sln /p:"configuration=Release Library-AVX2;platform=x64" >> $Log
"complete"

# ____________________________________________________________________________________________________________
# zlib
SetLog "04-zlib"
Write-Host -NoNewline "Building zlib..."
cd $root\src-stage1-dependencies\zlib-1.2.8/contrib/vstudio/vc14
msbuild zlibvc.sln /maxcpucount /p:"configuration=Release;platform=x64" >> $Log
msbuild zlibvc.sln /maxcpucount /p:"configuration=Debug;platform=x64" >> $Log
msbuild zlibvc.sln /maxcpucount /p:"configuration=Release-AVX2;platform=x64" >> $Log
msbuild zlibvc.sln /maxcpucount /p:"configuration=ReleaseWithoutAsm;platform=x64" >> $Log
msbuild zlibvc.sln /maxcpucount /p:"configuration=ReleaseWithoutAsm;platform=Win32" >> $Log
msbuild zlibvc.sln /maxcpucount /p:"configuration=Release;platform=Win32" >> $Log
msbuild zlibvc.sln /maxcpucount /p:"configuration=Debug;platform=Win32" >> $Log
msbuild zlibvc.sln /maxcpucount /p:"configuration=Release-AVX2;platform=Win32" >> $Log
"complete"

if ($Config.BuildGTKFromSource) {

	# __________________________________________________________________
	# freetype
	# freetype is only ever used as a static library, no AVX2
	# ignore the multi/single threaded options as they build against static runtime libs
	SetLog "05-freetype"
	Write-Host -NoNewline "building freetype..."
	cd $root\src-stage1-dependencies\freetype\builds\windows\vc2015
	msbuild freetype.sln /p:"configuration=Release;platform=x64" >> $Log
	msbuild freetype.sln /p:"configuration=Debug;platform=x64" >> $Log
	"complete"

	# __________________________________________________________________
	# pixman
	SetLog "06-pixman"
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
	SetLog "07-cairo"
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
	SetLog "08-gettext"
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
	SetLog "09-libffi"
	Write-Host -NoNewline "building libffi..."
	cd $root\src-stage1-dependencies\libffi\win32\vc14_x64
	msbuild .\libffi-msvc.sln /p:"configuration=Debug;platform=x64" >> $Log
	msbuild .\libffi-msvc.sln /p:"configuration=Release;platform=x64" >> $Log
	 "complete"

	# __________________________________________________________________
	# libxml2
	# must be after libiconv
	SetLog "10-libxml2"
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
	SetLog "11-jasper"
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
	SetLog "12-glib"
	Write-Host -NoNewline "building glib..."
	$GlibEtcInstallRoot = "..\..\..\..\gtk-build\x64\Debug"
	New-Item -ItemType Directory -Force -Path $GlibEtcInstallRoot  >> $Log
	New-Item -ItemType Directory -Force -Path $GlibEtcInstallRoot\include >> $Log
	New-Item -ItemType Directory -Force -Path $GlibEtcInstallRoot\lib >> $Log
	cp 
	cd $root\src-stage1-dependencies\glib\build\win32\vs14
	$ErrorActionPreference = "Continue"
	msbuild .\glib.vcxproj /p:"configuration=Debug;platform=x64;glibetcinstallroot=$GlibEtcInstallRoot" >> $Log
	$ErrorActionPreference = "Stop"
	"complete"

} else {
	# no action needed here if we are using the binaries.
	# if we use the premade build environment from hexchat, that
	# would replace the above code.
}
# ____________________________________________________________________________________________________________
# SDL
SetLog "13-SDL"
Write-Host -NoNewline "building SDL..."
cd $root\src-stage1-dependencies\sdl-1.2.15\VisualC
msbuild .\sdl.sln /p:"configuration=Debug;platform=x64" >> $Log
msbuild .\sdl.sln /p:"configuration=Release-AVX2;platform=x64" >> $Log
msbuild .\sdl.sln /p:"configuration=Release;platform=x64" >> $Log
"complete"

# ____________________________________________________________________________________________________________
# portaudio
SetLog "14-portaudio"
Write-Host -NoNewline "building portaudio..."
cd $root\src-stage1-dependencies\portaudio\build\msvc
msbuild .\portaudio.vcxproj /p:"configuration=Debug;platform=x64" >> $Log
msbuild .\portaudio.vcxproj /p:"configuration=Debug-Static;platform=x64" >> $Log
msbuild .\portaudio.vcxproj /p:"configuration=Release;platform=x64" >> $Log
msbuild .\portaudio.vcxproj /p:"configuration=Release-Static;platform=x64" >> $Log
msbuild .\portaudio.vcxproj /p:"configuration=Release-AVX2;platform=x64" >> $Log
msbuild .\portaudio.vcxproj /p:"configuration=Release-Static-AVX2;platform=x64" >> $Log
"complete"

# ____________________________________________________________________________________________________________
# cppunit
SetLog "15-cppunit"
Write-Host -NoNewline "building cppunit..."
cd $root\src-stage1-dependencies\cppunit-1.12.1\src >> $Log
msbuild .\CppUnitLibraries.sln /p:"configuration=Debug;platform=x64" >> $Log
msbuild .\CppUnitLibraries.sln /p:"configuration=Release;platform=x64" >> $Log
"complete"

# ____________________________________________________________________________________________________________
# fftw3
SetLog "16-fftw3"
Write-Host -NoNewline "building fftw3..."
cd $root\src-stage1-dependencies\fftw-3.3.5\msvc
msbuild .\fftw-3.3-libs.sln /p:"configuration=Debug;platform=x64" >> $Log
msbuild .\fftw-3.3-libs.sln /p:"configuration=Debug DLL;platform=x64" >> $Log
msbuild .\fftw-3.3-libs.sln /p:"configuration=Release;platform=x64" >> $Log
msbuild .\fftw-3.3-libs.sln /p:"configuration=Release DLL;platform=x64" >> $Log
msbuild .\fftw-3.3-libs.sln /p:"configuration=Release-AVX2;platform=x64" >> $Log 
msbuild .\fftw-3.3-libs.sln /p:"configuration=Release DLL-AVX2;platform=x64" >> $Log
"complete"

# ____________________________________________________________________________________________________________
# openssl (python depends on this)
SetLog "17-openssl"
Write-Host -NoNewline "building openssl..."
cd $root/src-stage1-dependencies/openssl
# The TEST target will not only build but also test
# Note, it appears the static libs are still linked to the /MT runtime
# don't change config names because they are linked to python's config names below
msbuild openssl.vcxproj /t:"Build" /p:"configuration=Debug;platform=x64" >> $Log
msbuild openssl.vcxproj /t:"Build" /p:"configuration=DebugDLL;platform=x64" >> $Log
msbuild openssl.vcxproj /t:"Build" /p:"configuration=Release;platform=x64" >> $Log
msbuild openssl.vcxproj /t:"Build" /p:"configuration=Release-AVX2;platform=x64" >> $Log
msbuild openssl.vcxproj /t:"Build" /p:"configuration=ReleaseDLL;platform=x64" >> $Log
msbuild openssl.vcxproj /t:"Build" /p:"configuration=ReleaseDLL-AVX2;platform=x64" >> $Log
"complete"


# ____________________________________________________________________________________________________________
# python (boost depends on this)
# FIXME need to handle the detection in msvc9compiler.py since MS skipped a MSVC version
SetLog "18-python"
Write-Host -NoNewline "building core python..."
cd $root/src-stage1-dependencies/python27/Python-2.7.10/PCbuild.vc14
msbuild pcbuild.sln /p:"configuration=Debug;platform=x64" >> $Log
msbuild pcbuild.sln /p:"configuration=Release;platform=x64" >> $Log
msbuild pcbuild.sln /p:"configuration=Release-AVX2;platform=x64" >> $Log
"complete"

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
	cp -r ../../Tools $pythonroot
	cp -r ../../../tcltk64/lib/*.* $pythonroot/tcl
	cp -r ../../Include $pythonroot
	cp ../../PC/pyconfig.h $pythonroot/Include
	cp ../../README $pythonroot/README.txt
	cp ../../LICENSE $pythonroot/LICENSE.txt
	cp -r ../../Lib/bsddb $pythonroot/Lib
	cp -r ../../Lib/compiler $pythonroot/Lib
	cp -r ../../Lib/ctypes $pythonroot/Lib
	cp -r ../../Lib/curses $pythonroot/Lib
	cp -r ../../Lib/distutils $pythonroot/Lib
	cp -r ../../Lib/email $pythonroot/Lib
	cp -r ../../Lib/encodings $pythonroot/Lib
	cp -r ../../Lib/hotshot $pythonroot/Lib
	cp -r ../../Lib/idlelib $pythonroot/Lib
	cp -r ../../Lib/importlib $pythonroot/Lib
	cp -r ../../Lib/json $pythonroot/Lib
	cp -r ../../Lib/lib2to3 $pythonroot/Lib
	cp -r ../../Lib/lib-tk $pythonroot/Lib
	cp -r ../../Lib/logging $pythonroot/Lib
	cp -r ../../Lib/msilib $pythonroot/Lib
	cp -r ../../Lib/multiprocessing $pythonroot/Lib
	cp -r ../../Lib/pydoc_data $pythonroot/Lib
	cp -r ../../Lib/sqlite3 $pythonroot/Lib
	cp -r ../../Lib/test $pythonroot/Lib
	cp -r ../../Lib/unittest $pythonroot/Lib
	cp -r ../../Lib/wsgiref $pythonroot/Lib
	cp -r ../../Lib/xml $pythonroot/Lib
	cp ../../Lib/*.* $pythonroot/Lib

	# then install key packages
	$env:Path = $pythonroot+ ";$OLD_PATH"
	# these packages will give warnings about files not found that will be errors on powershell if set to "Stop"
	$ErrorActionPreference = "Continue"
	cd $root/src-stage1-dependencies/setuptools-20.1.1
	& $pythonroot\$pythonexe setup.py install >> $Log
	cd $root/src-stage1-dependencies/pip-8.0.2
	& $pythonroot\$pythonexe setup.py install >> $Log
	cd $root\src-stage1-dependencies/wheel-0.29.0
	& $pythonroot\$pythonexe setup.py install >> $Log
	# TODO do we really need virtualenv since this will be a standalone distro?  Probably not
	# cd $root/src-stage1-dependencies/python27/virtualenv-13.1.0
	# & $pythonroot\python.exe setup.py install
	$ErrorActionPreference = "Stop"
	}

Write-Host -NoNewline "creating python core installs..." 
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
SetLog "19-boost"
Write-Host -NoNewline "building boost..."
cd $root/src-stage1-dependencies/boost
cmd /c "bootstrap.bat"
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
"complete"

# ____________________________________________________________________________________________________________
# libsodium
# must be before libzmq
SetLog "20-libsodium"
Write-Host -NoNewline "building libsodium..."
cd $root/src-stage1-dependencies/libsodium
cd builds\msvc\build
& .\buildbase.bat ..\vs2015\libsodium.sln 14 >> $Log
"complete"

# ____________________________________________________________________________________________________________
# libzmq
# must be after libsodium
SetLog "21-libzmq"
Write-Host -NoNewline "building libzmq..."
cd $root/src-stage1-dependencies/libzmq/builds/msvc/build
& .\buildbase.bat ..\vs2015\libzmq.sln 14 >> $Log
"complete"

# ____________________________________________________________________________________________________________
# gsl
SetLog "22-gsl"
Write-Host -NoNewline "building gsl..."
cd $root/src-stage1-dependencies/gsl-1.16/build.vc14
#prep headers
msbuild gsl.lib.sln /t:gslhdrs >> $Log
#static
msbuild gsl.lib.sln /t:cblaslib /t:gsllib /maxcpucount /p:"configuration=Release;platform=x64"  >> $Log
msbuild gsl.lib.sln /t:cblaslib /t:gsllib /maxcpucount /p:"configuration=Debug;platform=x64"  >> $Log
msbuild gsl.lib.sln /t:cblaslib /t:gsllib /maxcpucount /p:"configuration=Release-AVX2;platform=x64"  >> $Log
msbuild gsl.lib.sln /t:cblaslib /t:gsllib /maxcpucount /p:"configuration=Release;platform=Win32"  >> $Log
msbuild gsl.lib.sln /t:cblaslib /t:gsllib /maxcpucount /p:"configuration=Debug;platform=Win32"  >> $Log
msbuild gsl.lib.sln /t:cblaslib /t:gsllib /maxcpucount /p:"configuration=Release-AVX2;platform=Win32"  >> $Log
#dll
msbuild gsl.dll.sln /t:gslhdrs /p:Configuration="Debug" /p:Platform="Win32" >> $Log
msbuild gsl.dll.sln /t:cblasdll /t:gsldll /maxcpucount /p:"configuration=Release;platform=x64"  >> $Log
msbuild gsl.dll.sln /t:cblasdll /t:gsldll /maxcpucount /p:"configuration=Debug;platform=x64"  >> $Log
msbuild gsl.dll.sln /t:cblasdll /t:gsldll /maxcpucount /p:"configuration=Release-AVX2;platform=x64"  >> $Log
msbuild gsl.dll.sln /t:cblasdll /t:gsldll /maxcpucount /p:"configuration=Release;platform=Win32"  >> $Log
msbuild gsl.dll.sln /t:cblasdll /t:gsldll /maxcpucount /p:"configuration=Debug;platform=Win32"  >> $Log
msbuild gsl.dll.sln /t:cblasdll /t:gsldll /maxcpucount /p:"configuration=Release-AVX2;platform=Win32"  >> $Log
"complete"

# ____________________________________________________________________________________________________________
# qt4
# must be after openssl
SetLog "23-Qt4"
Write-Host -NoNewline "building Qt4..."
# TODO find/copy over vc140.pdb
cd $root/src-stage1-dependencies/Qt4
# Various things in Qt4 build are intepreted as errors so 
$ErrorActionPreference = "Continue"
$env:QMAKESPEC = win32-msvc2015
# Qt doesn't do a great job of allowing reconfiguring, so we go a little overkill
# with the "extra strong" cleaning routines.
if (!(Test-Path $root/src-stage1-dependencies/Qt4/Makefile)) {
	nmake clean >> $Log
	nmake confclean >> $Log
	nmake distclean >> $Log
	}
.\configure.exe -debug -prefix $root/src-stage1-dependencies/Qt4/build/DebugDll -platform win32-msvc2015 -opensource -confirm-license -qmake -ltcg -nomake examples -nomake network -nomake demos -nomake tools -nomake sql -no-script -no-scripttools -no-qt3support -sse2 -directwrite -mp -qt-libpng -qt-libjpeg -opengl desktop -graphicssystem opengl -no-webkit -qt-sql-sqlite -plugin-sql-sqlite -openssl -L "$root\src-stage1-dependencies\openssl\build\x64\Debug" -l ssleay32 -l libeay32 -l crypt32 -l kernel32 -l user32 -l gdi32 -l winspool -l comdlg32 -l advapi32 -l shell32 -l ole32 -l oleaut32 -l uuid -l odbc32 -l odbccp32 -l advapi32 OPENSSL_LIBS="-L$root\src-stage1-dependencies\openssl\build\x64\Debug -lssleay32 -llibeay32" -I "$root\src-stage1-dependencies\openssl\build\x64\Debug\Include" -make nmake   >> $Log
nmake >> $Log
nmake install >> $Log 
nmake confclean >> $Log
.\configure.exe -release  -prefix $root/src-stage1-dependencies/Qt4/build/ReleaseDll -platform win32-msvc2015 -opensource -confirm-license -qmake -ltcg -nomake examples -nomake network -nomake demos -nomake tools -nomake sql -no-script -no-scripttools -no-qt3support -sse2 -directwrite -mp -qt-libpng -qt-libjpeg -opengl desktop -graphicssystem opengl -no-webkit -qt-sql-sqlite -plugin-sql-sqlite -openssl -L "$root\src-stage1-dependencies\openssl\build\x64\Release" -l ssleay32 -l libeay32 -l crypt32 -l kernel32 -l user32 -l gdi32 -l winspool -l comdlg32 -l advapi32 -l shell32 -l ole32 -l oleaut32 -l uuid -l odbc32 -l odbccp32 -l advapi32 OPENSSL_LIBS="-L$root\src-stage1-dependencies\openssl\build\x64\Release -lssleay32 -llibeay32" -I "$root\src-stage1-dependencies\openssl\build\x64\Release\Include"  -make nmake   >> $Log
nmake  >> $Log
nmake install  >> $Log
nmake confclean >> $Log
.\configure.exe -debug -prefix $root/src-stage1-dependencies/Qt4/build/Debug -static -platform win32-msvc2015 -opensource -confirm-license -qmake -ltcg -nomake examples -nomake network -nomake demos -nomake tools -nomake sql -no-script -no-scripttools -no-qt3support -sse2 -directwrite -mp -qt-libpng -qt-libjpeg -opengl desktop -graphicssystem opengl -no-webkit -qt-sql-sqlite -plugin-sql-sqlite -openssl -L "$root\src-stage1-dependencies\openssl\build\x64\Debug" -l ssleay32 -l libeay32 -l crypt32 -l kernel32 -l user32 -l gdi32 -l winspool -l comdlg32 -l advapi32 -l shell32 -l ole32 -l oleaut32 -l uuid -l odbc32 -l odbccp32 -l advapi32 OPENSSL_LIBS="-L$root\src-stage1-dependencies\openssl\build\x64\Debug -lssleay32 -llibeay32" -I "$root\src-stage1-dependencies\openssl\build\x64\Debug\Include" -make nmake   >> $Log
nmake >> $Log
nmake install >> $Log 
# switch to AVX2 mode
$oldCL = $env:CL
$env:CL = "/Ox /arch:AVX2 " + $env:CL
nmake confclean >> $Log
.\configure.exe -release -prefix $root/src-stage1-dependencies/Qt4/build/Release-AVX2 -static -platform win32-msvc2015 -opensource -confirm-license -qmake -ltcg -nomake examples -nomake network -nomake demos -nomake tools -nomake sql -no-script -no-scripttools -no-qt3support -sse2 -directwrite -mp -qt-libpng -qt-libjpeg -opengl desktop -graphicssystem opengl -no-webkit -qt-sql-sqlite -plugin-sql-sqlite -openssl -L "$root\src-stage1-dependencies\openssl\build\x64\Release" -l ssleay32 -l libeay32 -l crypt32 -l kernel32 -l user32 -l gdi32 -l winspool -l comdlg32 -l advapi32 -l shell32 -l ole32 -l oleaut32 -l uuid -l odbc32 -l odbccp32 -l advapi32 OPENSSL_LIBS="-L$root\src-stage1-dependencies\openssl\build\x64\Release -lssleay32 -llibeay32" -I "$root\src-stage1-dependencies\openssl\build\x64\Release\Include" -make nmake   >> $Log
nmake  >> $Log
nmake install  >> $Log
nmake confclean >> $Log
.\configure.exe -release -prefix $root/src-stage1-dependencies/Qt4/build/ReleaseDLL-AVX2 -platform win32-msvc2015 -opensource -confirm-license -qmake -ltcg -nomake examples -nomake network -nomake demos -nomake tools -nomake sql -no-script -no-scripttools -no-qt3support -sse2 -directwrite -mp -qt-libpng -qt-libjpeg -opengl desktop -graphicssystem opengl -no-webkit -qt-sql-sqlite -plugin-sql-sqlite -openssl -L "$root\src-stage1-dependencies\openssl\build\x64\Release" -l ssleay32 -l libeay32 -l crypt32 -l kernel32 -l user32 -l gdi32 -l winspool -l comdlg32 -l advapi32 -l shell32 -l ole32 -l oleaut32 -l uuid -l odbc32 -l odbccp32 -l advapi32 OPENSSL_LIBS="-L$root\src-stage1-dependencies\openssl\build\x64\Release -lssleay32 -llibeay32" -I "$root\src-stage1-dependencies\openssl\build\x64\Release\Include" -make nmake   >> $Log
nmake  >> $Log
nmake install  >> $Log
$env:CL = $oldCL
# do release last because that's the "default" config, and qmake does some strange things
# like save the last config persistently and globally.
nmake confclean >> $Log
.\configure.exe -release -prefix $root/src-stage1-dependencies/Qt4/build/Release -static -platform win32-msvc2015 -opensource -confirm-license -qmake -ltcg -nomake examples -nomake network -nomake demos -nomake tools -nomake sql -no-script -no-scripttools -no-qt3support -sse2 -directwrite -mp -qt-libpng -qt-libjpeg -opengl desktop -graphicssystem opengl -no-webkit -qt-sql-sqlite -plugin-sql-sqlite -openssl -L "$root\src-stage1-dependencies\openssl\build\x64\Release" -l ssleay32 -l libeay32 -l crypt32 -l kernel32 -l user32 -l gdi32 -l winspool -l comdlg32 -l advapi32 -l shell32 -l ole32 -l oleaut32 -l uuid -l odbc32 -l odbccp32 -l advapi32 OPENSSL_LIBS="-L$root\src-stage1-dependencies\openssl\build\x64\Release -lssleay32 -llibeay32" -I "$root\src-stage1-dependencies\openssl\build\x64\Release\Include" -make nmake   >> $Log
nmake  >> $Log
nmake install  >> $Log

#clean up enormous amount of temp files
nmake clean >> $Log
nmake confclean >> $Log
nmake distclean >> $Log
"complete"

# ____________________________________________________________________________________________________________
# QWT 5.2.3
# must be after Qt
# all those cleans are important because like Qt, QMAKE does a terrible job of cleaning up makefiles and configs
# when building in more than one configuration
# Also note that 4 builds go into a single folder... because debug and release libraries have different names
# and the static/dll libs have different names, so no conflict...
SetLog "24-Qwt"
Write-Host -NoNewline "building qwt..."
$ErrorActionPreference = "Continue"
$env:QMAKESPEC = win32-msvc2015
cd $root\src-stage1-dependencies\qwt-5.2.3 
$command = "$root\src-stage1-dependencies\Qt4\build\Debug\bin\qmake.exe qwt.pro ""CONFIG-=release_with_debuginfo"" ""CONFIG+=debug"" ""PREFIX=$root/src-stage1-dependencies/qwt-5.2.3/build/x64/Debug-Release"" ""MAKEDLL=NO"" ""AVX2=NO"""
nmake clean >> $Log
nmake distclean >> $Log
Invoke-Expression $command >> $Log
nmake >> $Log
nmake install >> $Log
$command = "$root\src-stage1-dependencies\Qt4\build\DebugDLL\bin\qmake.exe qwt.pro ""CONFIG+=debug"" ""PREFIX=$root/src-stage1-dependencies/qwt-5.2.3/build/x64/Debug-Release"" ""MAKEDLL=YES"" ""AVX2=NO"""
nmake clean >> $Log
nmake distclean >> $Log
Invoke-Expression $command >> $Log
nmake >> $Log
nmake install >> $Log
$command = "$root\src-stage1-dependencies\Qt4\build\Release\bin\qmake.exe qwt.pro ""CONFIG-=debug"" ""CONFIG+=release_with_debuginfo"" ""PREFIX=$root/src-stage1-dependencies/qwt-5.2.3/build/x64/Debug-Release"" ""MAKEDLL=NO"" ""AVX2=NO"""
nmake clean >> $Log
nmake distclean >> $Log
Invoke-Expression $command >> $Log
nmake >> $Log
nmake install >> $Log
$command = "$root\src-stage1-dependencies\Qt4\build\ReleaseDLL\bin\qmake.exe qwt.pro ""CONFIG+=release_with_debuginfo"" ""PREFIX=$root/src-stage1-dependencies/qwt-5.2.3/build/x64/Debug-Release"" ""MAKEDLL=YES"" ""AVX2=NO"""
nmake clean >> $Log
nmake distclean >> $Log
Invoke-Expression $command >> $Log
nmake >> $Log
nmake install >> $Log
$oldCL = $env:CL
$env:CL = "/Ox /arch:AVX2 /Zi /Gs- " + $env:CL
$command = "$root\src-stage1-dependencies\Qt4\build\Release-AVX2\bin\qmake.exe qwt.pro ""CONFIG+=release_with_debuginfo"" ""PREFIX=$root/src-stage1-dependencies/qwt-5.2.3/build/x64/Release-AVX2"" ""MAKEDLL=NO"" ""AVX2=YES"""
nmake clean >> $Log
nmake distclean >> $Log
Invoke-Expression $command >> $Log
nmake >> $Log
nmake install >> $Log
$command = "$root\src-stage1-dependencies\Qt4\build\ReleaseDLL-AVX2\bin\qmake.exe qwt.pro ""CONFIG+=release_with_debuginfo"" ""PREFIX=$root/src-stage1-dependencies/qwt-5.2.3/build/x64/Release-AVX2"" ""MAKEDLL=YES"" ""AVX2=YES"""
nmake clean >> $Log
nmake distclean >> $Log
Invoke-Expression $command >> $Log
nmake >> $Log
nmake install >> $Log
$env:CL = $oldCL
$ErrorActionPreference = "Stop"
"complete"



