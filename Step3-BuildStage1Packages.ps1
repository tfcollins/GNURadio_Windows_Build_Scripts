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

# setup helper functions
$mypath =  Split-Path $script:MyInvocation.MyCommand.Path
Import-Module $mypath\Functions.psm1

# setup paths
$root = $env:grwinbuildroot 
if (!$root) {$root = "C:/gr-build"}
cd $root
set-alias sz "$root\bin\7za.exe"  

# Check for binary dependencies
if (-not (test-path "$root\bin\7za.exe")) {throw "7-zip (7za.exe) needed in bin folder"} 

# CMake (to build gnuradio)
# ActivePerl (to build OpenSSL)

#set VS 2015 environment
pushd 'c:\Program Files (x86)\Microsoft Visual Studio 14.0\VC'
cmd /c "vcvarsall.bat amd64&set" |
foreach {
  if ($_ -match "=") {
    $v = $_.split("="); set-item -force -path "ENV:\$($v[0])"  -value "$($v[1])"
  }
}
popd
write-host "Visual Studio 2015 Command Prompt variables set." -ForegroundColor Yellow
$oldpath = $env:Path

# EVERYTHING ABOVE THIS LINE NEEDS TO BE RUN ONCE BEFORE BUILDING ANY PACKAGES
break

# Build packages needed for Stage 1
cd src-stage1-dependencies

# libpng 
# uses zlib but incorporates the source directly so doesn't need to be built after zlib
cd $root\src-stage1-dependencies\libpng-1.6.21\projects\vstudio-vs2015
msbuild vstudio.sln /p:"configuration=Debug;platform=x64"
msbuild vstudio.sln /p:"configuration=Debug Library;platform=x64"
msbuild vstudio.sln /p:"configuration=Release;platform=x64"
msbuild vstudio.sln /p:"configuration=Release Library;platform=x64"
msbuild vstudio.sln /p:"configuration=Release-AVX2;platform=x64"
msbuild vstudio.sln /p:"configuration=Release Library-AVX2;platform=x64"

# zlib
cd $root\src-stage1-dependencies\zlib-1.2.8/contrib/vstudio/vc14
msbuild zlibvc.sln /maxcpucount /p:"configuration=Release;platform=x64" 
msbuild zlibvc.sln /maxcpucount /p:"configuration=Debug;platform=x64" 
msbuild zlibvc.sln /maxcpucount /p:"configuration=Release-AVX2;platform=x64" 
msbuild zlibvc.sln /maxcpucount /p:"configuration=ReleaseWithoutAsm;platform=x64" 
msbuild zlibvc.sln /maxcpucount /p:"configuration=ReleaseWithoutAsm;platform=Win32" 
msbuild zlibvc.sln /maxcpucount /p:"configuration=Release;platform=Win32" 
msbuild zlibvc.sln /maxcpucount /p:"configuration=Debug;platform=Win32" 
msbuild zlibvc.sln /maxcpucount /p:"configuration=Release-AVX2;platform=Win32" 

# SDL
cd $root\src-stage1-dependencies\sdl-1.2.15\VisualC
msbuild .\sdl.sln /p:"configuration=Debug;platform=x64"
msbuild .\sdl.sln /p:"configuration=Release-AVX2;platform=x64"
msbuild .\sdl.sln /p:"configuration=Release;platform=x64"

# portaudio
cd $root\src-stage1-dependencies\portaudio\build\msvc
msbuild .\portaudio.vcxproj /p:"configuration=Debug;platform=x64"
msbuild .\portaudio.vcxproj /p:"configuration=Debug-Static;platform=x64"
msbuild .\portaudio.vcxproj /p:"configuration=Release;platform=x64"
msbuild .\portaudio.vcxproj /p:"configuration=Release-Static;platform=x64"
msbuild .\portaudio.vcxproj /p:"configuration=Release-AVX2;platform=x64"
msbuild .\portaudio.vcxproj /p:"configuration=Release-Static-AVX2;platform=x64"

# cppunit
cd $root\src-stage1-dependencies\cppunit-1.12.1\src
msbuild .\CppUnitLibraries.sln /p:"configuration=Debug;platform=x64"
msbuild .\CppUnitLibraries.sln /p:"configuration=Release;platform=x64"

# fftw3
cd $root\src-stage1-dependencies\fftw-3.3.5\msvc
msbuild .\fftw-3.3-libs.sln /p:"configuration=Debug;platform=x64"
msbuild .\fftw-3.3-libs.sln /p:"configuration=Debug DLL;platform=x64"
msbuild .\fftw-3.3-libs.sln /p:"configuration=Release;platform=x64"
msbuild .\fftw-3.3-libs.sln /p:"configuration=Release DLL;platform=x64"
msbuild .\fftw-3.3-libs.sln /p:"configuration=Release-AVX2;platform=x64"
msbuild .\fftw-3.3-libs.sln /p:"configuration=Release DLL-AVX2;platform=x64"

# openssl (python depends on this)
cd $root/src-stage1-dependencies/openssl
# The TEST target will not only build but also test
# Note, it appears the static libs are still linked to the /MT runtime
# don't change config names because they are linked to python's config names below
msbuild openssl.vcxproj /t:"Build" /p:"configuration=Debug;platform=x64"
msbuild openssl.vcxproj /t:"Build" /p:"configuration=DebugDLL;platform=x64"
msbuild openssl.vcxproj /t:"Build" /p:"configuration=Release;platform=x64"
msbuild openssl.vcxproj /t:"Build" /p:"configuration=Release-AVX2;platform=x64"
msbuild openssl.vcxproj /t:"Build" /p:"configuration=ReleaseDLL;platform=x64"
msbuild openssl.vcxproj /t:"Build" /p:"configuration=ReleaseDLL-AVX2;platform=x64"

# python (boost depends on this)
cd $root/src-stage1-dependencies/python27/Python-2.7.10/PCbuild.vc14
msbuild pcbuild.sln /p:"configuration=Debug;platform=x64"
msbuild pcbuild.sln /p:"configuration=Release;platform=x64"
msbuild pcbuild.sln /p:"configuration=Release-AVX2;platform=x64"

# now place the binaries where we need them
# install the main python
$pythonroot = "$root\src-stage2-python\gr-python27"

New-Item -ItemType Directory -Force -Path $pythonroot
New-Item -ItemType Directory -Force -Path $pythonroot/DLLs
New-Item -ItemType Directory -Force -Path $pythonroot/Libs
New-Item -ItemType Directory -Force -Path $pythonroot/Docs
New-Item -ItemType Directory -Force -Path $pythonroot/lib
New-Item -ItemType Directory -Force -Path $pythonroot/lib/site-packages
New-Item -ItemType Directory -Force -Path $pythonroot/tcl
cd $root/src-stage1-dependencies/python27/Python-2.7.10/PCbuild.vc14
$env:Path = $pythonroot+ ";$OLD_PATH"

# no DOCs dir
# copy the files
# amd64 for regular build (release and debug combined), amd64-avx for release AVX2 build
cd amd64
cp python_d.exe $pythonroot
cp pythonw_d.exe $pythonroot
cp python27_d.dll $pythonroot
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
cd $root/src-stage1-dependencies/python27/setuptools-18.0.1
& $pythonroot\python.exe setup.py install
cd $root/src-stage1-dependencies/python27/pip-7.1.0
& $pythonroot\python.exe setup.py install
cd $root/src-stage1-dependencies/python27/virtualenv-13.1.0
& $pythonroot\python.exe setup.py install
$ErrorActionPreference = "Stop"

# boost
cd $root/src-stage1-dependencies/boost
cmd /c "bootstrap.bat"
# point boost build to our custom python libraries
$doubleroot = $root -replace "\\", "\\"
Add-Content .\project-config.jam "`nusing python : 2.7 : $doubleroot\\src-stage2-python\\gr-python27\\python.exe : $doubleroot\\src-stage2-python\\gr-python27\\Include : $doubleroot\\src-stage2-python\\gr-python27\\Libs ;"
# always rebuild all because boost will reuse objects from a previous build with different command line options
# Optimized static+shared release libraries
cmd /c 'b2.exe -a --build-type=minimal --prefix=build\avx2\Release --libdir=build\avx2\Release\lib --includedir=build\avx2\Release\include --stagedir=build\avx2\Release --layout=versioned address-model=64 threading=multi link=static,shared variant=release cxxflags="/arch:AVX2 /Ox /Zi" cflags="/arch:AVX2 /Ox /Zi" install'
# Regular  static+shared release libraries
cmd /c 'b2.exe -a --build-type=minimal --prefix=build\x64\Release --libdir=build\x64\Release\lib --includedir=build\x64\Release\include --stagedir=build\x64\Release --layout=versioned address-model=64 threading=multi link=static,shared variant=release cxxflags="-Zi" cflags="-Zi" install'
# Regular  static+shared debug libraries
cmd /c 'b2.exe -a --build-type=minimal --prefix=build\x64\Debug --libdir=build\x64\Debug\lib --includedir=build\x64\Debug\include --stagedir=build\x64\Debug --layout=versioned address-model=64 threading=multi link=static,shared variant=debug cxxflags="-Zi" cflags="-Zi" install'

# libsodium
# must be before libzmq
cd $root/src-stage1-dependencies/libsodium
cd builds\msvc\build
& .\buildbase.bat ..\vs2015\libsodium.sln 14

# libzmq
# must be after libsodium
cd $root/src-stage1-dependencies/libzmq/builds/msvc/build
& .\buildbase.bat ..\vs2015\libzmq.sln 14

# gsl
cd $root/src-stage1-dependencies/gsl-1.16/build.vc14
#prep headers
msbuild gsl.lib.sln /t:gslhdrs
#static
msbuild gsl.lib.sln /t:cblaslib /t:gsllib /maxcpucount /p:"configuration=Release;platform=x64" 
msbuild gsl.lib.sln /t:cblaslib /t:gsllib /maxcpucount /p:"configuration=Debug;platform=x64" 
msbuild gsl.lib.sln /t:cblaslib /t:gsllib /maxcpucount /p:"configuration=Release-AVX2;platform=x64" 
msbuild gsl.lib.sln /t:cblaslib /t:gsllib /maxcpucount /p:"configuration=Release;platform=Win32" 
msbuild gsl.lib.sln /t:cblaslib /t:gsllib /maxcpucount /p:"configuration=Debug;platform=Win32" 
msbuild gsl.lib.sln /t:cblaslib /t:gsllib /maxcpucount /p:"configuration=Release-AVX2;platform=Win32" 
#dll
msbuild gsl.dll.sln /t:gslhdrs /p:Configuration="Debug" /p:Platform="Win32"
msbuild gsl.dll.sln /t:cblasdll /t:gsldll /maxcpucount /p:"configuration=Release;platform=x64" 
msbuild gsl.dll.sln /t:cblasdll /t:gsldll /maxcpucount /p:"configuration=Debug;platform=x64" 
msbuild gsl.dll.sln /t:cblasdll /t:gsldll /maxcpucount /p:"configuration=Release-AVX2;platform=x64" 
msbuild gsl.dll.sln /t:cblasdll /t:gsldll /maxcpucount /p:"configuration=Release;platform=Win32" 
msbuild gsl.dll.sln /t:cblasdll /t:gsldll /maxcpucount /p:"configuration=Debug;platform=Win32" 
msbuild gsl.dll.sln /t:cblasdll /t:gsldll /maxcpucount /p:"configuration=Release-AVX2;platform=Win32" 

# qt4
# must be after openssl
# TODO find/copy over vc140.pdb
cd $root/src-stage1-dependencies/Qt4
# Various things in Qt4 build are intepreted as errors so 
$ErrorActionPreference = "Continue"
$env:QMAKESPEC = win32-msvc2015
# Qt doesn't do a great job of allowing reconfiguring, so we go a little overkill
# with the "extra strong" cleaning routines.
if (!(Test-Path $root/src-stage1-dependencies/Qt4/Makefile)) {
	nmake clean
	nmake confclean
	nmake distclean
	}
.\configure.exe -debug -prefix $root/src-stage1-dependencies/Qt4/build/DebugDll -platform win32-msvc2015 -opensource -confirm-license -qmake -ltcg -nomake examples -nomake network -nomake demos -nomake tools -nomake sql -no-script -no-scripttools -no-qt3support -sse2 -directwrite -mp -qt-libpng -qt-libjpeg -opengl desktop -graphicssystem opengl -no-webkit -qt-sql-sqlite -plugin-sql-sqlite -openssl -L "$root\src-stage1-dependencies\openssl\build\x64\Debug" -l ssleay32 -l libeay32 -l crypt32 -l kernel32 -l user32 -l gdi32 -l winspool -l comdlg32 -l advapi32 -l shell32 -l ole32 -l oleaut32 -l uuid -l odbc32 -l odbccp32 -l advapi32 OPENSSL_LIBS="-L$root\src-stage1-dependencies\openssl\build\x64\Debug -lssleay32 -llibeay32" -I "$root\src-stage1-dependencies\openssl\build\x64\Debug\Include" -make nmake  
nmake
nmake install 
nmake confclean
.\configure.exe -release  -prefix $root/src-stage1-dependencies/Qt4/build/ReleaseDll -platform win32-msvc2015 -opensource -confirm-license -qmake -ltcg -nomake examples -nomake network -nomake demos -nomake tools -nomake sql -no-script -no-scripttools -no-qt3support -sse2 -directwrite -mp -qt-libpng -qt-libjpeg -opengl desktop -graphicssystem opengl -no-webkit -qt-sql-sqlite -plugin-sql-sqlite -openssl -L "$root\src-stage1-dependencies\openssl\build\x64\Release" -l ssleay32 -l libeay32 -l crypt32 -l kernel32 -l user32 -l gdi32 -l winspool -l comdlg32 -l advapi32 -l shell32 -l ole32 -l oleaut32 -l uuid -l odbc32 -l odbccp32 -l advapi32 OPENSSL_LIBS="-L$root\src-stage1-dependencies\openssl\build\x64\Release -lssleay32 -llibeay32" -I "$root\src-stage1-dependencies\openssl\build\x64\Release\Include"  -make nmake  
nmake 
nmake install 
nmake confclean
.\configure.exe -debug -prefix $root/src-stage1-dependencies/Qt4/build/Debug -static -platform win32-msvc2015 -opensource -confirm-license -qmake -ltcg -nomake examples -nomake network -nomake demos -nomake tools -nomake sql -no-script -no-scripttools -no-qt3support -sse2 -directwrite -mp -qt-libpng -qt-libjpeg -opengl desktop -graphicssystem opengl -no-webkit -qt-sql-sqlite -plugin-sql-sqlite -openssl -L "$root\src-stage1-dependencies\openssl\build\x64\Debug" -l ssleay32 -l libeay32 -l crypt32 -l kernel32 -l user32 -l gdi32 -l winspool -l comdlg32 -l advapi32 -l shell32 -l ole32 -l oleaut32 -l uuid -l odbc32 -l odbccp32 -l advapi32 OPENSSL_LIBS="-L$root\src-stage1-dependencies\openssl\build\x64\Debug -lssleay32 -llibeay32" -I "$root\src-stage1-dependencies\openssl\build\x64\Debug\Include" -make nmake  
nmake
nmake install 
# switch to AVX2 mode
$oldCL = $env:CL
$env:CL = "/Ox /arch:AVX2 " + $env:CL
nmake confclean
.\configure.exe -release -prefix $root/src-stage1-dependencies/Qt4/build/Release-AVX2 -static -platform win32-msvc2015 -opensource -confirm-license -qmake -ltcg -nomake examples -nomake network -nomake demos -nomake tools -nomake sql -no-script -no-scripttools -no-qt3support -sse2 -directwrite -mp -qt-libpng -qt-libjpeg -opengl desktop -graphicssystem opengl -no-webkit -qt-sql-sqlite -plugin-sql-sqlite -openssl -L "$root\src-stage1-dependencies\openssl\build\x64\Release" -l ssleay32 -l libeay32 -l crypt32 -l kernel32 -l user32 -l gdi32 -l winspool -l comdlg32 -l advapi32 -l shell32 -l ole32 -l oleaut32 -l uuid -l odbc32 -l odbccp32 -l advapi32 OPENSSL_LIBS="-L$root\src-stage1-dependencies\openssl\build\x64\Release -lssleay32 -llibeay32" -I "$root\src-stage1-dependencies\openssl\build\x64\Release\Include" -make nmake  
nmake 
nmake install 
nmake confclean
.\configure.exe -release -prefix $root/src-stage1-dependencies/Qt4/build/ReleaseDLL-AVX2 -platform win32-msvc2015 -opensource -confirm-license -qmake -ltcg -nomake examples -nomake network -nomake demos -nomake tools -nomake sql -no-script -no-scripttools -no-qt3support -sse2 -directwrite -mp -qt-libpng -qt-libjpeg -opengl desktop -graphicssystem opengl -no-webkit -qt-sql-sqlite -plugin-sql-sqlite -openssl -L "$root\src-stage1-dependencies\openssl\build\x64\Release" -l ssleay32 -l libeay32 -l crypt32 -l kernel32 -l user32 -l gdi32 -l winspool -l comdlg32 -l advapi32 -l shell32 -l ole32 -l oleaut32 -l uuid -l odbc32 -l odbccp32 -l advapi32 OPENSSL_LIBS="-L$root\src-stage1-dependencies\openssl\build\x64\Release -lssleay32 -llibeay32" -I "$root\src-stage1-dependencies\openssl\build\x64\Release\Include" -make nmake  
nmake 
nmake install 
$env:CL = $oldCL
# do release last because that's the "default" config, and qmake does some strange things
# like save the last config persistently and globally.
nmake confclean
.\configure.exe -release -prefix $root/src-stage1-dependencies/Qt4/build/Release -static -platform win32-msvc2015 -opensource -confirm-license -qmake -ltcg -nomake examples -nomake network -nomake demos -nomake tools -nomake sql -no-script -no-scripttools -no-qt3support -sse2 -directwrite -mp -qt-libpng -qt-libjpeg -opengl desktop -graphicssystem opengl -no-webkit -qt-sql-sqlite -plugin-sql-sqlite -openssl -L "$root\src-stage1-dependencies\openssl\build\x64\Release" -l ssleay32 -l libeay32 -l crypt32 -l kernel32 -l user32 -l gdi32 -l winspool -l comdlg32 -l advapi32 -l shell32 -l ole32 -l oleaut32 -l uuid -l odbc32 -l odbccp32 -l advapi32 OPENSSL_LIBS="-L$root\src-stage1-dependencies\openssl\build\x64\Release -lssleay32 -llibeay32" -I "$root\src-stage1-dependencies\openssl\build\x64\Release\Include" -make nmake  
nmake 
nmake install 

#clean up enormous amount of temp files
nmake clean
nmake confclean
nmake distclean


# QWT 5.2.3
# must be after Qt
# all those cleans are important because like Qt, QMAKE does a terrible job of cleaning up makefiles and configs
# when building in more than one configuration
# Also note that 4 builds go into a single folder... because debug and release libraries have different names
# and the static/dll libs have different names, so no conflict...
$ErrorActionPreference = "Continue"
$env:QMAKESPEC = win32-msvc2015
cd $root\src-stage1-dependencies\qwt-5.2.3 
$command = "$root\src-stage1-dependencies\Qt4\build\Debug\bin\qmake.exe qwt.pro ""CONFIG-=release_with_debuginfo"" ""CONFIG+=debug"" ""PREFIX=$root/src-stage1-dependencies/qwt-5.2.3/build/x64/Debug-Release"" ""MAKEDLL=NO"" ""AVX2=NO"""
nmake clean
nmake distclean
Invoke-Expression $command
nmake
nmake install
$command = "$root\src-stage1-dependencies\Qt4\build\DebugDLL\bin\qmake.exe qwt.pro ""CONFIG+=debug"" ""PREFIX=$root/src-stage1-dependencies/qwt-5.2.3/build/x64/Debug-Release"" ""MAKEDLL=YES"" ""AVX2=NO"""
nmake clean
nmake distclean
Invoke-Expression $command
nmake
nmake install
$command = "$root\src-stage1-dependencies\Qt4\build\Release\bin\qmake.exe qwt.pro ""CONFIG-=debug"" ""CONFIG+=release_with_debuginfo"" ""PREFIX=$root/src-stage1-dependencies/qwt-5.2.3/build/x64/Debug-Release"" ""MAKEDLL=NO"" ""AVX2=NO"""
nmake clean
nmake distclean
Invoke-Expression $command
nmake
nmake install
$command = "$root\src-stage1-dependencies\Qt4\build\ReleaseDLL\bin\qmake.exe qwt.pro ""CONFIG+=release_with_debuginfo"" ""PREFIX=$root/src-stage1-dependencies/qwt-5.2.3/build/x64/Debug-Release"" ""MAKEDLL=YES"" ""AVX2=NO"""
nmake clean
nmake distclean
Invoke-Expression $command
nmake
nmake install
$oldCL = $env:CL
$env:CL = "/Ox /arch:AVX2 /Zi /Gs- " + $env:CL
$command = "$root\src-stage1-dependencies\Qt4\build\Release-AVX2\bin\qmake.exe qwt.pro ""CONFIG+=release_with_debuginfo"" ""PREFIX=$root/src-stage1-dependencies/qwt-5.2.3/build/x64/Release-AVX2"" ""MAKEDLL=NO"" ""AVX2=YES"""
nmake clean
nmake distclean
Invoke-Expression $command
nmake
nmake install
$command = "$root\src-stage1-dependencies\Qt4\build\ReleaseDLL-AVX2\bin\qmake.exe qwt.pro ""CONFIG+=release_with_debuginfo"" ""PREFIX=$root/src-stage1-dependencies/qwt-5.2.3/build/x64/Release-AVX2"" ""MAKEDLL=YES"" ""AVX2=YES"""
nmake clean
nmake distclean
Invoke-Expression $command
nmake
nmake install
$env:CL = $oldCL
$ErrorActionPreference = "Stop"

#sip
cd $root\src-stage1-dependencies\sip-4.17
& $pythonroot\python.exe configure.py -u -p win32-msvc2015 
nmake
New-Item -ItemType Directory -Force -Path ./build/x64/DebugDLL
cd siplib
copy sip_d.pyd ../build/x64/DebugDLL/sip_d.pyd
copy sip_d.pdb ../build/x64/DebugDLL/sip_d.pdb
copy sip_d.ilk ../build/x64/DebugDLL/sip_d.ilk
copy sip_d.lib ../build/x64/DebugDLL/sip_d.lib
copy sip_d.pyd ../build/x64/DebugDLL/sip_d.exp
copy sip.h ../build/x64/DebugDLL/sip.h
copy sipconfig.py ../build/x64/DebugDLL/sipconfig.py
cd ../sipgen
copy sip.exe ../build/x64/DebugDLL/sip.exe
cd ..
copy sipdistutils.py build/x64/DebugDLL/sipdistutils.py
nmake clean

& $pythonroot\python.exe configure.py -u -k -p win32-msvc2015 
nmake
New-Item -ItemType Directory -Force -Path ./build/x64/Debug
cd siplib
copy sip_d.lib ../build/x64/Debug/sip_d.lib
copy sip.h ../build/x64/Debug/sip.h
copy sipconfig.py ../build/x64/Debug/sipconfig.py
cd ../sipgen
copy sip.exe ../build/x64/Debug/sip.exe
cd ..
copy sipdistutils.py build/x64/Debug/sipdistutils.py
nmake clean

& $pythonroot\python.exe configure.py -p win32-msvc2015 
nmake
New-Item -ItemType Directory -Force -Path ./build/x64/ReleaseDLL
cd siplib
copy sip.pyd ../build/x64/ReleaseDLL/sip.pyd
copy sip.pdb ../build/x64/ReleaseDLL/sip.pdb
copy sip.ilk ../build/x64/ReleaseDLL/sip.ilk
copy sip.lib ../build/x64/ReleaseDLL/sip.lib
copy sip.pyd ../build/x64/ReleaseDLL/sip.exp
copy sip.h ../build/x64/ReleaseDLL/sip.h
copy sipconfig.py ../build/x64/ReleaseDLL/sipconfig.py
cd ../sipgen
copy sip.exe ../build/x64/ReleaseDLL/sip.exe
cd ..
copy sipdistutils.py build/x64/ReleaseDLL/sipdistutils.py
nmake clean

& $pythonroot\python.exe configure.py -k -p win32-msvc2015 
nmake
New-Item -ItemType Directory -Force -Path ./build/x64/Release
cd siplib
copy sip.lib ../build/x64/Release/sip.lib
copy sip.h ../build/x64/Release/sip.h
copy sipconfig.py ../build/x64/Release/sipconfig.py
cd ../sipgen
copy sip.exe ../build/x64/Release/sip.exe
cd ..
copy sipdistutils.py build/x64/Release/sipdistutils.py
nmake clean

#-------------- saving for the install part
# since we can only have a single type of SIP installed at once
#cd siplib
#copy /y sip_d.pyd $pythonroot\Lib\site-packages\sip_d.pyd
#copy /y sip.h $pythonroot\include\sip.h
#copy /y sipconfig.py $pythonroot\Lib\site-packages\sipconfig.py
#cd ..
#copy /y sipdistutils.py $pythonroot\Lib\site-packages\sipdistutils.py
#cd sipgen
#copy /y sip.exe $pythonroot\sip.exe

# PyQt
$ErrorActionPreference = "Continue"
cd $root\src-stage1-dependencies\PyQt4
$env:QMAKESPEC = "win32-msvc2015"
$env:Path = "$root\src-stage1-dependencies\Qt4\build\Debug\bin;" + $oldpath
# debug static
& $pythonroot\python.exe configure.py -u -k --destdir "build\x64\Debug" --confirm-license --verbose --no-designer-plugin --enable QtOpenGL --enable QtGui  --b build/x64/Debug/bin -d build/x64/Debug/package -p build/x64/Debug/plugins --sipdir build/x64/Debug/sip
# BUG FIX
"all: ;" > .\pylupdate\Makefile
"install : ;" >> .\pylupdate\Makefile
"clean : ;" >> .\pylupdate\Makefile
nmake
nmake install
nmake clean

$env:Path = "$root\src-stage1-dependencies\Qt4\build\DebugDLL\bin;" + $oldpath
& $pythonroot\python.exe configure.py -u --destdir "build\x64\DebugDLL" --confirm-license --verbose --no-designer-plugin --enable QtOpenGL --enable QtGui  --b build/x64/DebugDLL/bin -d build/x64/DebugDLL/package -p build/x64/DebugDLL/plugins --sipdir build/x64/DebugDLL/sip
# BUG FIX
"all: ;" > .\pylupdate\Makefile
"install : ;" >> .\pylupdate\Makefile
"clean : ;" >> .\pylupdate\Makefile
nmake
nmake install
nmake clean

$env:Path = "$root\src-stage1-dependencies\Qt4\build\ReleaseDLL\bin;" + $oldpath
& $pythonroot\python.exe configure.py --destdir "build\x64\ReleaseDLL" --confirm-license --verbose --no-designer-plugin --enable QtOpenGL --enable QtGui  --b build/x64/ReleaseDLL/bin -d build/x64/ReleaseDLL/package -p build/x64/ReleaseDLL/plugins --sipdir build/x64/ReleaseDLL/sip
# BUG FIX
"all: ;" > .\pylupdate\Makefile
"install : ;" >> .\pylupdate\Makefile
"clean : ;" >> .\pylupdate\Makefile
nmake
nmake install
nmake clean

$env:Path = "$root\src-stage1-dependencies\Qt4\build\Release\bin;" + $oldpath
& $pythonroot\python.exe configure.py -k --destdir "build\x64\Release" --confirm-license --verbose --no-designer-plugin --enable QtOpenGL --enable QtGui  --b build/x64/Release/bin -d build/x64/Release/package -p build/x64/Release/plugins --sipdir build/x64/Release/sip
# BUG FIX
"all: ;" > .\pylupdate\Makefile
"install : ;" >> .\pylupdate\Makefile
"clean : ;" >> .\pylupdate\Makefile 
nmake
nmake install
nmake clean
$env:Path = $oldpath
$ErrorActionPreference = "Stop"

# PyQwt5
# requires Python, Qwt, Qt, PyQt, and Numpy
cd $root\src-stage1-dependencies\PyQwt5-master
cd configure
& $pythonroot/python.exe configure.py --debug --extra-cflags="-Zi" -I ..\Qwt-5.2.3\build\x64\Debug\include -L ..\Qwt-5.2.3\build\x64\Debug\lib -j4 --sip-include-dirs ..\sip-4.17\build\x64\Debug
nmake
nmake install


$env:Path = $OLD_PATH

