#
# GNURadio Windows Build System
# Step4_BuildPythonPackages.ps1
#
# Geof Nieboer
#
# NOTES:
# Each module is designed to be run independently, so sometimes variables
# are set redundantly.  This is to enable easier debugging if one package needs to be re-run
#
# This module builds the various python packages above the essentials included
# in the build originally.  We are building two versions, one for AVX2 only
# and one for release.
# TODO build one for the debug binaries.

# script setup
$ErrorActionPreference = "Stop"

# setup helper functions
$mypath =  Split-Path $script:MyInvocation.MyCommand.Path
. $mypath\Setup.ps1 -Force

$pythonexe = "python.exe"
$pythondebugexe = "python_d.exe"

break

Function SetupPython
{
	$ErrorActionPreference = "Continue"
	cd $root\src-stage1-dependencies\PyQt4
	$env:Path = "$root\src-stage1-dependencies\Qt4\build\$configuration\bin;" + $oldpath
	$env:QMAKESPEC = "win32-msvc2015"
	& $pythonroot\$pythonexe configure.py --confirm-license --verbose --no-designer-plugin --enable QtOpenGL --enable QtGui 
	# BUG FIX
	"all: ;" > .\pylupdate\Makefile
	"install : ;" >> .\pylupdate\Makefile
	"clean : ;" >> .\pylupdate\Makefile 
	nmake
	nmake install
	$env:Path = $oldpath
	$ErrorActionPreference = "Stop"

	# PyQwt5
	# requires Python, Qwt, Qt, PyQt, and Numpy
	$env:Path = "$root\src-stage1-dependencies\Qt4\build\$configuration\bin;" + $oldpath
	cd $root\src-stage1-dependencies\PyQwt5-master
	cd configure
	if ($configuration -eq "DebugDLL") {
		& $pythonroot/$pythonexe configure.py --debug --extra-cflags="-Zi" -I ..\Qwt-5.2.3\build\x64\Debug-Release\include -L ..\Qwt-5.2.3\build\x64\Debug-Release\lib -j4 --sip-include-dirs ..\sip-4.17\build\x64\Debug-Release
	} elseif ($configuration -eq "ReleaseDLL") {
		& $pythonroot/$pythonexe configure.py --extra-cflags="-Zi" -I ..\Qwt-5.2.3\build\x64\Debug-Release\include -L ..\Qwt-5.2.3\build\x64\Debug-Release\lib -j4 --sip-include-dirs ..\sip-4.17\build\x64\Debug-Release
	} else {
		& $pythonroot/$pythonexe configure.py --extra-cflags="-Zi -Ox -arch:AVX2" -I ..\Qwt-5.2.3\build\x64\Release-AVX2\include -L ..\Qwt-5.2.3\build\x64\Release-AVX2\lib -j4 --sip-include-dirs ..\sip-4.17\build\x64\Release-AVX2
	}
	nmake
	nmake install
	$env:Path = $oldpath

	# Cython
	cd $root\src-stage1-dependencies\Cython-0.23.4
	& $pythonroot/$pythonexe setup.py bdist_wheel  
	& $pythonroot/$pythonexe setup.py install 

	# Nose
	# Nose is a python-only package can be installed automatically
	# used for testing numpy/scipy etc only, not in gnuradio directly
	& $pythonroot/Scripts/pip.exe install nose

	# mkl_libs line generated with the assistance of:
	# https://software.intel.com/en-us/articles/intel-mkl-link-line-advisor

	# numpy
	$ErrorActionPreference = "Continue"
	cd $root\src-stage1-dependencies\numpy-1.10.4
	$static = $true
	if ($Config.BuildNumpyWithMKL) {
		if ($static) {
			"[mkl]" | Out-File -filepath site.cfg -Encoding ascii
			"search_static_first=true" | Out-File -filepath site.cfg -Encoding ascii -Append
			"include_dirs = ${env:ProgramFiles(x86)}\IntelSWTools\compilers_and_libraries\windows\mkl\include" | Out-File -filepath site.cfg -Encoding ascii -Append
			"library_dirs = ${env:ProgramFiles(x86)}\IntelSWTools\compilers_and_libraries\windows\mkl\lib\intel64_win" | Out-File -filepath site.cfg -Encoding ascii -Append 
			"mkl_libs = mkl_rt" | Out-File -filepath site.cfg -Encoding ascii -Append
			"lapack_libs = " | Out-File -filepath site.cfg -Encoding ascii -Append
			if ($configuration -eq "ReleaseDLL-AVX2") {
				"extra_compile_args=/MD /Zi /Oy /Ox /Oi /arch:AVX2" | Out-File -filepath site.cfg -Encoding ascii -Append
			} elseif ($configuration -eq "DebugDLL") {
				"extra_compile_args=/MD /Zi" | Out-File -filepath site.cfg -Encoding ascii -Append
			} else {
				"extra_compile_args=/MD /Zi /Oy /Ox /Oi" | Out-File -filepath site.cfg -Encoding ascii -Append
			}
		} else {
			"[mkl]" | Out-File -filepath site.cfg -Encoding ascii
			"search_static_first=false" | Out-File -filepath site.cfg -Encoding ascii -Append
			"include_dirs = ${env:ProgramFiles(x86)}\IntelSWTools\compilers_and_libraries\windows\mkl\include" | Out-File -filepath site.cfg -Encoding ascii -Append
			"library_dirs = ${env:ProgramFiles(x86)}\IntelSWTools\compilers_and_libraries\windows\mkl\lib\intel64_win" | Out-File -filepath site.cfg -Encoding ascii -Append 
			"mkl_libs = mkl_intel_lp64, mkl_core, mkl_sequential" | Out-File -filepath site.cfg -Encoding ascii -Append
			"lapack_libs = " | Out-File -filepath site.cfg -Encoding ascii -Append
			if ($configuration -eq "ReleaseDLL-AVX2") {
				"extra_compile_args=/MD /Zi /Oy /Ox /Oi /arch:AVX2" | Out-File -filepath site.cfg -Encoding ascii -Append
			} elseif ($configuration -eq "DebugDLL") {
				"extra_compile_args=/MD /Zi" | Out-File -filepath site.cfg -Encoding ascii -Append
			} else {
				"extra_compile_args=/MD /Zi /Oy /Ox /Oi" | Out-File -filepath site.cfg -Encoding ascii -Append
			}
		}
		
	}
	$env:VS90COMNTOOLS = $env:VS140COMNTOOLS
	& $pythonroot/$pythonexe setup.py config --compiler=msvc2015 2>&1 | write-host
	& $pythonroot/$pythonexe setup.py build
	& $pythonroot/$pythonexe setup.py install
	& $pythonroot/$pythonexe setup.py bdist_wheel

	# scipy
	if ($hasIFORT) {
		cd $root\src-stage1-dependencies\scipy
		$env:Path = "${env:ProgramFiles(x86)}\IntelSWTools\compilers_and_libraries\windows\bin\intel64;" + $oldPath 
		$env:LIB = "${env:IFORT_COMPILER16}compiler\lib\intel64_win;" + $oldLib
	
		if ($Config.BuildNumpyWithMKL) {
			if ($static) {
				"[mkl]" | Out-File -filepath site.cfg -Encoding ascii
				"search_static_first=true" | Out-File -filepath site.cfg -Encoding ascii -Append
				"include_dirs = ${env:ProgramFiles(x86)}\IntelSWTools\compilers_and_libraries\windows\mkl\include" | Out-File -filepath site.cfg -Encoding ascii -Append
				"library_dirs = ${env:IFORT_COMPILER16}compiler\lib\intel64_win;${env:IFORT_COMPILER16}mkl\lib\intel64_win" | Out-File -filepath site.cfg -Encoding ascii -Append 
				"mkl_libs = mkl_lapack95_lp64,mkl_blas95_lp64,mkl_intel_lp64,mkl_intel_thread,mkl_core" | Out-File -filepath site.cfg -Encoding ascii -Append
				"lapack_libs = mkl_lapack95_lp64,mkl_blas95_lp64,mkl_intel_lp64,mkl_intel_thread,mkl_core" | Out-File -filepath site.cfg -Encoding ascii -Append
				if ($configuration -eq "ReleaseDLL-AVX2") {
					"extra_compile_args=/MD /Zi /Oy /Ox /Oi /arch:AVX2" | Out-File -filepath site.cfg -Encoding ascii -Append
				} elseif ($configuration -eq "DebugDLL") {
					"extra_compile_args=/MD /Zi" | Out-File -filepath site.cfg -Encoding ascii -Append
				} else {
					"extra_compile_args=/MD /Zi /Oy /Ox /Oi" | Out-File -filepath site.cfg -Encoding ascii -Append
				}
			} else {
				"[mkl]" | Out-File -filepath site.cfg -Encoding ascii
				"search_static_first=false" | Out-File -filepath site.cfg -Encoding ascii -Append
				"include_dirs = ${env:ProgramFiles(x86)}\IntelSWTools\compilers_and_libraries\windows\mkl\include" | Out-File -filepath site.cfg -Encoding ascii -Append
				"library_dirs = $env:IFORT_COMPILER16\compiler\lib\intel64_win;$env:IFORT_COMPILER16\mkl\lib\intel64_win" | Out-File -filepath site.cfg -Encoding ascii -Append 
				"mkl_libs = mkl_rt" | Out-File -filepath site.cfg -Encoding ascii -Append
				"lapack_libs = mkl_lapack95_lp64,mkl_blas95_lp64" | Out-File -filepath site.cfg -Encoding ascii -Append
				if ($configuration -eq "ReleaseDLL-AVX2") {
					"extra_compile_args=/MD /Zi /Oy /Ox /Oi /arch:AVX2" | Out-File -filepath site.cfg -Encoding ascii -Append
				} elseif ($configuration -eq "DebugDLL") {
					"extra_compile_args=/MD /Zi" | Out-File -filepath site.cfg -Encoding ascii -Append
				} else {
					"extra_compile_args=/MD /Zi /Oy /Ox /Oi" | Out-File -filepath site.cfg -Encoding ascii -Append
				}
			}
		}
		$env:VS90COMNTOOLS = $env:VS140COMNTOOLS
		# clean doesn't really get it all...
		del build/*.* -Recurse
		& $pythonroot/$pythonexe setup.py clean 2>&1 | write-host
		& $pythonroot/$pythonexe setup.py config --fcompiler=intelvem --compiler=msvc 2>&1 | write-host
		& $pythonroot/$pythonexe setup.py build --compiler=msvc --fcompiler=intelvem
		& $pythonroot/$pythonexe setup.py install 
		& $pythonroot/$pythonexe setup.py bdist_wheel
	
		$ErrorActionPreference = "Stop"
	} else {
		# can't compile scipy without a fortran compiler, and gfortran won't work here
		# because we can't mix MSVC and gfortran libraries
		# So if 
	}
}

# sip six different ways
$ErrorActionPreference = "Continue"
$pythonroot = "$root\src-stage2-python\gr-python27-debug"
cd $root\src-stage1-dependencies\sip-4.17

& $pythonroot\$pythondebugexe configure.py -u -p win32-msvc2015 
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
nmake install
nmake clean

& $pythonroot\$pythondebugexe configure.py -u -k -p win32-msvc2015 
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

$pythonroot = "$root\src-stage2-python\gr-python27"
& $pythonroot\$pythonexe configure.py -p win32-msvc2015 
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
nmake install
nmake clean

& $pythonroot\$pythonexe configure.py -k -p win32-msvc2015 
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

# TODO the AVX2 version below are producing identical results to release
# so we need to figure out how to add the /arch:AVX2 flag
$pythonroot = "$root\src-stage2-python\gr-python27-avx2"
& $pythonroot\$pythonexe configure.py -p win32-msvc2015 
nmake -f Makefile CFLAGS="-arch:AVX2 -Ox" CXXFLAGS="-arch:AVX2 -Ox"
New-Item -ItemType Directory -Force -Path ./build/x64/ReleaseDLL-AVX2
cd siplib
copy sip.pyd ../build/x64/ReleaseDLL-AVX2/sip.pyd
copy sip.pdb ../build/x64/ReleaseDLL-AVX2/sip.pdb
copy sip.ilk ../build/x64/ReleaseDLL-AVX2/sip.ilk
copy sip.lib ../build/x64/ReleaseDLL-AVX2/sip.lib
copy sip.pyd ../build/x64/ReleaseDLL-AVX2/sip.exp
copy sip.h ../build/x64/ReleaseDLL-AVX2/sip.h
copy sipconfig.py ../build/x64/ReleaseDLL-AVX2/sipconfig.py
cd ../sipgen
copy sip.exe ../build/x64/ReleaseDLL-AVX2/sip.exe
cd ..
copy sipdistutils.py build/x64/ReleaseDLL-AVX2/sipdistutils.py
nmake install
nmake clean

& $pythonroot\$pythonexe configure.py -k -p win32-msvc2015 
nmake -f Makefile CFLAGS="-arch:AVX2 -Ox" CXXFLAGS="-arch:AVX2 -Ox"
New-Item -ItemType Directory -Force -Path ./build/x64/Release-AVX2
cd siplib
copy sip.lib ../build/x64/Release-AVX2/sip.lib
copy sip.h ../build/x64/Release-AVX2/sip.h
copy sipconfig.py ../build/x64/Release-AVX2/sipconfig.py
cd ../sipgen
copy sip.exe ../build/x64/Release-AVX2/sip.exe
cd ..
copy sipdistutils.py build/x64/Release-AVX2/sipdistutils.py
nmake clean
$env:CL = $oldcl
$ErrorActionPreference = "Stop"

# PyQt
$ErrorActionPreference = "Continue"
cd $root\src-stage1-dependencies\PyQt4
$pythonroot = "$root\src-stage2-python\gr-python27-debug"
$env:QMAKESPEC = "win32-msvc2015"
$env:Path = "$root\src-stage1-dependencies\Qt4\build\Debug\bin;" + $oldpath
# debug static
& $pythonroot\$pythondebugexe configure.py -u -k --destdir "build\x64\Debug" --confirm-license --verbose --no-designer-plugin --enable QtOpenGL --enable QtGui  -b build/x64/Debug/bin -d build/x64/Debug/package -p build/x64/Debug/plugins --sipdir build/x64/Debug/sip
# BUG FIX
"all: ;" > .\pylupdate\Makefile
"install : ;" >> .\pylupdate\Makefile
"clean : ;" >> .\pylupdate\Makefile
nmake
nmake install
nmake clean

$env:Path = "$root\src-stage1-dependencies\Qt4\build\DebugDLL\bin;" + $oldpath
& $pythonroot\$pythondebugexe configure.py -u --destdir "build\x64\DebugDLL" --confirm-license --verbose --no-designer-plugin --enable QtOpenGL --enable QtGui  -b build/x64/DebugDLL/bin -d build/x64/DebugDLL/package -p build/x64/DebugDLL/plugins --sipdir build/x64/DebugDLL/sip
# BUG FIX
"all: ;" > .\pylupdate\Makefile
"install : ;" >> .\pylupdate\Makefile
"clean : ;" >> .\pylupdate\Makefile
nmake
nmake install
nmake clean

$pythonroot = "$root\src-stage2-python\gr-python27"
$env:Path = "$root\src-stage1-dependencies\Qt4\build\ReleaseDLL\bin;" + $oldpath
& $pythonroot\$pythonexe configure.py --destdir "build\x64\ReleaseDLL" --confirm-license --verbose --no-designer-plugin --enable QtOpenGL --enable QtGui  -b build/x64/ReleaseDLL/bin -d build/x64/ReleaseDLL/package -p build/x64/ReleaseDLL/plugins --sipdir build/x64/ReleaseDLL/sip
# BUG FIX
"all: ;" > .\pylupdate\Makefile
"install : ;" >> .\pylupdate\Makefile
"clean : ;" >> .\pylupdate\Makefile
nmake
nmake install
nmake clean

$env:Path = "$root\src-stage1-dependencies\Qt4\build\Release\bin;" + $oldpath
& $pythonroot\$pythonexe configure.py -k --destdir "build\x64\Release" --confirm-license --verbose --no-designer-plugin --enable QtOpenGL --enable QtGui  -b build/x64/Release/bin -d build/x64/Release/package -p build/x64/Release/plugins --sipdir build/x64/Release/sip
# BUG FIX
"all: ;" > .\pylupdate\Makefile
"install : ;" >> .\pylupdate\Makefile
"clean : ;" >> .\pylupdate\Makefile 
nmake
nmake install
nmake clean
$env:Path = $oldpath
$ErrorActionPreference = "Stop"

$pythonroot = "$root\src-stage2-python\gr-python27-avx2"
$env:Path = "$root\src-stage1-dependencies\Qt4\build\ReleaseDLL-AVX2\bin;" + $oldpath
& $pythonroot\$pythonexe configure.py --destdir "build\x64\ReleaseDLL-AVX2" --confirm-license --verbose --no-designer-plugin --enable QtOpenGL --enable QtGui  -b build/x64/ReleaseDLL-AVX2/bin -d build/x64/ReleaseDLL-AVX2/package -p build/x64/ReleaseDLL-AVX2/plugins --sipdir build/x64/ReleaseDLL-AVX2/sip
# BUG FIX
"all: ;" > .\pylupdate\Makefile
"install : ;" >> .\pylupdate\Makefile
"clean : ;" >> .\pylupdate\Makefile
nmake
nmake install
nmake clean

$env:Path = "$root\src-stage1-dependencies\Qt4\build\Release-AVX2\bin;" + $oldpath
& $pythonroot\$pythonexe configure.py -k --destdir "build\x64\Release-AVX2" --confirm-license --verbose --no-designer-plugin --enable QtOpenGL --enable QtGui  -b build/x64/Release-AVX2/bin -d build/x64/Release-AVX2/package -p build/x64/Release-AVX2/plugins --sipdir build/x64/Release-AVX2/sip
# BUG FIX
"all: ;" > .\pylupdate\Makefile
"install : ;" >> .\pylupdate\Makefile
"clean : ;" >> .\pylupdate\Makefile 
nmake
nmake install
nmake clean
$env:Path = $oldpath
$ErrorActionPreference = "Stop"

$pythonroot = "$root\src-stage2-python\gr-python27"
$configuration = "ReleaseDLL"
SetupPython
$pythonroot = "$root\src-stage2-python\gr-python27-avx2"
$configuration = "ReleaseDLL-AVX2"
SetupPython
$pythonexe = $pythondebugexe
$pythonroot = "$root\src-stage2-python\gr-python27-debug"
$configuration = "DebugDLL"
SetupPython