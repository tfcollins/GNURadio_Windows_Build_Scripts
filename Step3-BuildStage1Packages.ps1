# GNURadio Windows Build System
# Geof Nieboer

#setup

# base directory
$root = $env:grwinbuildroot 
if (!$root) {$root = "C:\gr-build"}
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


# Build packages needed for Stage 1
cd src-stage1-dependencies

# libpng (uses zlib but incorporates the source directly)
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
msbuild openssl.vcxproj /p:"configuration=Debug;platform=x64"
msbuild openssl.vcxproj /p:"configuration=DebugDLL;platform=x64"
msbuild openssl.vcxproj /p:"configuration=Release;platform=x64"
msbuild openssl.vcxproj /p:"configuration=Release-AVX2;platform=x64"
msbuild openssl.vcxproj /p:"configuration=ReleaseDLL;platform=x64"
msbuild openssl.vcxproj /p:"configuration=ReleaseDLL-AVX2;platform=x64"

#python (boost depends on this)
cd $root/src-stage1-dependencies/python27/Python-2.7.10/PCbuild.vc14
# The TEST target will not only build but also test
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
cd amd64
cp python.exe $pythonroot
cp pythonw.exe $pythonroot
cp *.pyd $pythonroot/DLLs
cp *.dll $pythonroot/DLLs
cp python27.dll $pythonroot
cp *.lib $pythonroot/libs
cp ../../PC/py.ico $pythonroot/DLLs
cp ../../PC/pyc.ico $pythonroot/DLLs
cp -r ../../Tools $pythonroot
cp -r ../../../tcltk64/lib/*.* $pythonroot/tcl
cp -r ../../Include $pythonroot
cp ../PC/pyconfig.h $pythonroot/Include
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
cd $root/src-stage1-dependencies/python27/setuptools-18.0.1
& $pythonroot\python.exe setup.py install
cd $root/src-stage1-dependencies/python27/pip-7.1.0
& $pythonroot\python.exe setup.py install
cd $root/src-stage1-dependencies/python27/virtualenv-13.1.0
& $pythonroot\python.exe setup.py install

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

#libsodium
cd $root/src-stage1-dependencies/libsodium
#msbuild libsodium.sln /maxcpucount /p:"configuration=Release;platform=x64" 
#msbuild libsodium.sln /maxcpucount /p:"configuration=Debug;platform=x64" 
#msbuild libsodium.sln /maxcpucount /p:"configuration=ReleaseDll;platform=x64" 
#msbuild libsodium.sln /maxcpucount /p:"configuration=Debug;platform=Win32" 
#msbuild libsodium.sln /maxcpucount /p:"configuration=ReleaseDll;platform=Win32" 
#msbuild libsodium.sln /maxcpucount /p:"configuration=Release;platform=Win32" 
cd builds\msvc\build
& .\buildbase.bat ..\vs2015\libsodium.sln 14

#libzmq

#gsl
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

$env:Path = $OLD_PATH

