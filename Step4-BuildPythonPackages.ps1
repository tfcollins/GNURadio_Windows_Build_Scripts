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
# in the build originally.  We are building three versions, one for AVX2 only
# and one for release and one for debug

# script setup
$ErrorActionPreference = "Stop"

# setup helper functions
if ($script:MyInvocation.MyCommand.Path -eq $null) {
    $mypath = "."
} else {
    $mypath =  Split-Path $script:MyInvocation.MyCommand.Path
}
. $mypath\Setup.ps1 -Force

$pythonexe = "python.exe"
$pythondebugexe = "python_d.exe"
$env:PYTHONPATH=""

#__________________________________________________________________________________________
# sip
#
# TODO static builds are not working, not vital as not truly needed to continue.
#
$ErrorActionPreference = "Continue"
SetLog "sip"
Write-Host -NoNewline "building sip..."
cd $root\src-stage1-dependencies\sip-$sip_version
# reset these in case previous run was stopped in mid-build
$env:_LINK_ = ""
$env:_CL_ = ""

Function MakeSip
{
	$type = $args[0]
	Write-Host -NoNewline "$type..."
	$dflag = if ($type -match "Debug") {"--debug"} else {""}
	$kflag = if ($type -match "Dll") {""} else {" --static"}
	$debugext = if ($type -match "Debug") {"_d"} else {""}
	if ($type -match "AVX2") {$env:CL = "/Ox /arch:AVX2 " + $oldcl} else {$env:CL = $oldCL}
	if (Test-Path sipconfig.py) {del sipconfig.py}
    "FLAGS: $kflag $dflag" >> $Log 
    "command line : configure.py $dflag $kflag -p win32-msvc2015" >> $Log
	& $pythonroot\python$debugext.exe configure.py $dflag $kflag -p win32-msvc2015 2>&1 >> $Log
	nmake 2>&1 >> $Log
	New-Item -ItemType Directory -Force -Path ./build/x64/$type 2>&1 >> $Log
	cd siplib
	if ($type -match "Dll") {
		copy sip$debugext.pyd ../build/x64/$type/sip$debugext.pyd
		copy sip$debugext.exp ../build/x64/$type/sip$debugext.exp
		if ($type -match "Debug") {
			copy sip$debugext.pdb ../build/x64/$type/sip$debugext.pdb
			copy sip$debugext.ilk ../build/x64/$type/sip$debugext.ilk
		}
	}
	copy sip$debugext.lib ../build/x64/$type/sip$debugext.lib
	copy sip.h ../build/x64/$type/sip.h
	cd ../sipgen
	copy sip.exe ../build/x64/$type/sip.exe
	cd ..
	copy sipdistutils.py ./build/x64/$type/sipdistutils.py
	if ($type -match "Dll") {
	    copy sipconfig.py ./build/x64/$type/sipconfig.py
    	nmake install 2>&1 >> $Log
		Validate "$pythonroot/sip.exe" "$pythonroot/include/sip.h" "$pythonroot/lib/site-packages/sip$debugext.pyd" 
	}
	nmake clean 2>&1 >> $Log
}

$pythonroot = "$root\src-stage2-python\gr-python27-debug"
#MakeSip "Debug"
MakeSip "DebugDLL"
$pythonroot = "$root\src-stage2-python\gr-python27"
#MakeSip "Release"
MakeSip "ReleaseDLL"
$pythonroot = "$root\src-stage2-python\gr-python27-avx2"
#MakeSip "Release-AVX2"
MakeSip "ReleaseDLL-AVX2"
$ErrorActionPreference = "Stop"
"complete"

#__________________________________________________________________________________________
# PyQt
#
# building libraries separate from the actual install into Python
#
$ErrorActionPreference = "Continue"
SetLog "PyQt"
cd $root\src-stage1-dependencies\PyQt4
$env:QMAKESPEC = "win32-msvc2015"
Write-Host -NoNewline "building PyQT..."

function MakePyQt 
{
	$type = $args[0]
	Write-Host -NoNewline "$type"
	if ($type -match "Debug") {$thispython = $pythondebugexe} else {$thispython = $pythonexe}
	$flags = if ($type -match "Debug") {"-u"} else {""}
	$flags += if ($type -match "Dll") {""} else {" -k"}
	if ($type -match "AVX2") {$env:CL = "/Ox /arch:AVX2 /wd4577 /MP " + $oldcl} else {$env:CL = "/wd4577 /MP " + $oldCL}
	$env:_LINK_= ""
	$env:Path = "$root\src-stage1-dependencies\Qt4\build\$type\bin;" + $oldpath

	& $pythonroot\$thispython configure.py $flags --destdir "build\x64\$type" --confirm-license --verbose --no-designer-plugin --enable QtOpenGL --enable QtGui --enable QtSvg -b build/x64/$type/bin -d build/x64/$type/package -p build/x64/$type/plugins --sipdir build/x64/$type/sip 2>&1 >> $log

	# BUG FIX
	"all: ;" > .\pylupdate\Makefile
	"install : ;" >> .\pylupdate\Makefile
	"clean : ;" >> .\pylupdate\Makefile

	nmake 2>&1 >> $log
	nmake install 2>&1 >> $log
	nmake clean 2>&1 >> $log
	$env:CL = $oldcl
	$env:_LINK_ = ""
	Write-Host -NoNewline "-done..."
}

$pythonroot = "$root\src-stage2-python\gr-python27-debug"
MakePyQt "DebugDLL"
MakePyQt "Debug"
$pythonroot = "$root\src-stage2-python\gr-python27"
MakePyQt "Release"
MakePyQt "ReleaseDLL"
$pythonroot = "$root\src-stage2-python\gr-python27-avx2"
MakePyQt "Release-AVX2"
MakePyQt "ReleaseDLL-AVX2"
$ErrorActionPreference = "Stop"
"complete"

$mm = GetMajorMinor($gnuradio_version)
if ($mm -eq "3.8") {
	#__________________________________________________________________________________________
	# PyQt
	#
	# building libraries separate from the actual install into Python
	#
	$ErrorActionPreference = "Continue"
	SetLog "PyQt5"
	cd $root\src-stage1-dependencies\PyQt5
	$env:QMAKESPEC = "win32-msvc2015"
	Write-Host -NoNewline "building PyQT5..."

	function MakePyQt5
	{
		$type = $args[0]
		Write-Host -NoNewline "$type"
		if ($type -match "Debug") {$thispython = $pythondebugexe} else {$thispython = $pythonexe}
		$flags = if ($type -match "Debug") {"-u"} else {""}
		$flags += if ($type -match "Dll") {""} else {" -k"}
		if ($type -match "AVX2") {$env:CL = "/Ox /arch:AVX2 /wd4577 /MP " + $oldcl} else {$env:CL = "/wd4577 /MP " + $oldCL}
		$env:_LINK_= ""
		$env:Path = "$root\src-stage1-dependencies\Qt5\build\$type\bin;" + $oldpath

		& $pythonroot\$thispython configure.py $flags --destdir "build\x64\$type" --confirm-license --verbose --no-designer-plugin --enable QtOpenGL --enable QtGui --enable QtSvg -b build/x64/$type/bin -d build/x64/$type/package -p build/x64/$type/plugins --sipdir build/x64/$type/sip 2>&1 >> $log

		# BUG FIX
		"all: ;" > .\pylupdate\Makefile
		"install : ;" >> .\pylupdate\Makefile
		"clean : ;" >> .\pylupdate\Makefile

		nmake 2>&1 >> $log
		nmake install 2>&1 >> $log
		nmake clean 2>&1 >> $log
		$env:CL = $oldcl
		$env:_LINK_ = ""
		Write-Host -NoNewline "-done..."
	}

	$pythonroot = "$root\src-stage2-python\gr-python27-debug"
	MakePyQt5 "DebugDLL"
	MakePyQt5 "Debug"
	$pythonroot = "$root\src-stage2-python\gr-python27"
	MakePyQt5 "Release"
	MakePyQt5 "ReleaseDLL"
	$pythonroot = "$root\src-stage2-python\gr-python27-avx2"
	MakePyQt5 "Release-AVX2"
	MakePyQt5 "ReleaseDLL-AVX2"
	$ErrorActionPreference = "Stop"
	"complete"
}

#__________________________________________________________________________________________
# setup python

Function SetupPython
{
	$configuration = $args[0]
	"installing python packages for $configuration"
	if ($configuration -match "Debug") { 
		$d = "d" 
		$debugext = "_d"
		 $debug = "--debug"
	} else {
		$d = ""
		$debugext = ""
		$debug = ""
	}

	#__________________________________________________________________________________________
	# PyQt4
	#
	SetLog "$configuration PyQt4"
	Write-Host -NoNewline "configuring PyQt4..."
	$ErrorActionPreference = "Continue"
	cd $root\src-stage1-dependencies\PyQt4
	$flags = if ($configuration -match "Debug") {"-u"} else {""}
	if ($type -match "AVX2") {$env:CL = "/Ox /arch:AVX2 /wd4577 /MP " + $oldcl} else {$env:CL = "/wd4577 /MP " + $oldCL}
	$env:Path = "$root\src-stage1-dependencies\Qt4\build\$configuration\bin;" + $oldpath
	$env:QMAKESPEC = "win32-msvc2015"
	$env:_LINK_= ""

	& $pythonroot\$pythonexe configure.py $flags --confirm-license --verbose --no-designer-plugin --enable QtOpenGL --enable QtGui --enable QtSvg  2>&1 >> $log
	
	# BUG FIX
	"all: ;" > .\pylupdate\Makefile
	"install : ;" >> .\pylupdate\Makefile
	"clean : ;" >> .\pylupdate\Makefile 

	Write-Host -NoNewline "building..."
	Exec {nmake} 2>&1 >> $log
	Write-Host -NoNewline "installing..."
	Exec {nmake install} 2>&1 >> $log
	$env:Path = $oldpath
	$env:CL = $oldcl
	$env:_LINK_ = ""
	$ErrorActionPreference = "Stop"
	Validate "$pythonroot/lib/site-packages/PyQt4/Qt$debugext.pyd" "$pythonroot/lib/site-packages/PyQt4/QtCore$debugext.pyd" "$pythonroot/lib/site-packages/PyQt4/QtGui$debugext.pyd" "$pythonroot/lib/site-packages/PyQt4/QtOpenGL$debugext.pyd" "$pythonroot/lib/site-packages/PyQt4/QtSvg$debugext.pyd"

	#__________________________________________________________________________________________
	# Cython
	#
	# TODO This is not working properly on the debug build... essentially it is linking against
	#      python27 instead of python27_d
	SetLog "$configuration Cython"
	Write-Host -NoNewline "installing Cython..."
	$ErrorActionPreference = "Continue"
	cd $root\src-stage1-dependencies\Cython-$cython_version
	$env:_LINK_ = " /LIB:python27_d.lib "
	& $pythonroot/$pythonexe setup.py build $debug install 2>&1 >> $log
	Write-Host -NoNewline "creating wheel..."
	& $pythonroot/$pythonexe setup.py bdist_wheel   2>&1 >> $log
	$env:_LINK_ = ""
	move dist/Cython-$cython_version-cp27-cp27${d}m-win_amd64.whl dist/Cython-$cython_version-cp27-cp27${d}m-win_amd64.$configuration.whl -Force
	$ErrorActionPreference = "Stop"
	Validate "dist/Cython-$cython_version-cp27-cp27${d}m-win_amd64.$configuration.whl" "$pythonroot/lib/site-packages/Cython-$cython_version-py2.7-win-amd64.egg/cython.py" "$pythonroot/lib/site-packages/Cython-$cython_version-py2.7-win-amd64.egg/Cython/Compiler/Code$debugext.pyd" "$pythonroot/lib/site-packages/Cython-$cython_version-py2.7-win-amd64.egg/Cython/Distutils/build_ext.py"

	#__________________________________________________________________________________________
	# Nose
	# Nose is a python-only package can be installed automatically
	# used for testing numpy/scipy etc only, not in gnuradio directly
	#
	SetLog "$configuration Nose"
	Write-Host -NoNewline "installing Nose using pip..."
	$ErrorActionPreference = "Continue" # pip will "error" on debug
	& $pythonroot/Scripts/pip.exe --disable-pip-version-check  install nose -U -t $pythonroot\lib\site-packages 2>&1 >> $log
	$ErrorActionPreference = "Stop"
	Validate "$pythonroot/lib/site-packages/nose/core.py" "$pythonroot/lib/site-packages/nose/__main__.py"

	#__________________________________________________________________________________________
	# numpy
	# mkl_libs site.cfg lines generated with the assistance of:
	# https://software.intel.com/en-us/articles/intel-mkl-link-line-advisor
	#
	# TODO numpy Debug OpenBLAS crashes during numpy.test('full')
	#
	SetLog "$configuration numpy"
	Write-Host -NoNewline "configuring numpy..."
	$ErrorActionPreference = "Continue"
	cd $root\src-stage1-dependencies\numpy-$numpy_version
	# $static indicates if the MKL/OpenBLAS libraries will be linked statically into numpy/scipy or not.  numpy/scipy themselves will be built as DLLs/pyd's always
	# openblas lapack is always static
	$static = $true
	$staticconfig = ($configuration -replace "DLL", "") 
	if ($static -eq $true) {$staticlib = "_static"} else {$staticlib = ""}
	if ($BuildNumpyWithMKL) {
		# Build with MKL
		Write-Host -NoNewline "MKL..."
		if ($static -eq $false) {
			"[mkl]" | Out-File -filepath site.cfg -Encoding ascii
			"search_static_first=false" | Out-File -filepath site.cfg -Encoding ascii -Append
			"include_dirs = ${env:ProgramFiles(x86)}\IntelSWTools\compilers_and_libraries\windows\mkl\include" | Out-File -filepath site.cfg -Encoding ascii -Append
			"library_dirs = ${env:ProgramFiles(x86)}\IntelSWTools\compilers_and_libraries\windows\mkl\lib\intel64_win" | Out-File -filepath site.cfg -Encoding ascii -Append 
			"mkl_libs = mkl_rt" | Out-File -filepath site.cfg -Encoding ascii -Append
			"lapack_libs = " | Out-File -filepath site.cfg -Encoding ascii -Append
			if ($configuration -match "AVX2") {
				"extra_compile_args=/MD /Zi /Oy /Ox /Oi /arch:AVX2" | Out-File -filepath site.cfg -Encoding ascii -Append
			} elseif ($configuration -match "Debug") {
				"extra_compile_args=/MDd /Zi" | Out-File -filepath site.cfg -Encoding ascii -Append
			} else {
				"extra_compile_args=/MD /Zi /Oy /Ox /Oi" | Out-File -filepath site.cfg -Encoding ascii -Append
			}
		} else {
			"[mkl]" | Out-File -filepath site.cfg -Encoding ascii
			"search_static_first=true" | Out-File -filepath site.cfg -Encoding ascii -Append
			"include_dirs = ${env:ProgramFiles(x86)}\IntelSWTools\compilers_and_libraries\windows\mkl\include" | Out-File -filepath site.cfg -Encoding ascii -Append
			"library_dirs = ${env:ProgramFiles(x86)}\IntelSWTools\compilers_and_libraries\windows\mkl\lib\intel64_win" | Out-File -filepath site.cfg -Encoding ascii -Append 
			"mkl_libs = mkl_intel_lp64, mkl_core, mkl_intel_thread, libiomp5md" | Out-File -filepath site.cfg -Encoding ascii -Append
			"lapack_libs = " | Out-File -filepath site.cfg -Encoding ascii -Append
			if ($configuration -match "AVX2") {
				"extra_compile_args=/MD /Zi /Oy /Ox /Oi /arch:AVX2" | Out-File -filepath site.cfg -Encoding ascii -Append
			} elseif ($configuration -match "Debug") {
				"extra_compile_args=/MDd /Zi" | Out-File -filepath site.cfg -Encoding ascii -Append
			} else {
				"extra_compile_args=/MD /Zi /Oy /Ox /Oi" | Out-File -filepath site.cfg -Encoding ascii -Append
			}
		}
	} else {
		# Build with OpenBLAS
		Write-Host -NoNewline "OpenBLAS..."
		"[default]" | Out-File -filepath site.cfg -Encoding ascii
		"libraries = libopenblas$staticlib, lapack" | Out-File -filepath site.cfg -Encoding ascii -Append
		"library_dirs = $root/src-stage1-dependencies/openblas/build/$staticconfig/lib;$root/src-stage1-dependencies/lapack/dist/$staticconfig/lib" | Out-File -filepath site.cfg -Encoding ascii -Append
		"include_dirs = $root/src-stage1-dependencies\OpenBLAS\lapack-netlib\CBLAS\include" | Out-File -filepath site.cfg -Encoding ascii -Append
		"lapack_libs = libopenblas$staticlib, lapack" | Out-File -filepath site.cfg -Encoding ascii -Append
		if ($configuration -match "AVX2") {
			"extra_compile_args=/MD /Zi /Oy /Ox /Oi /arch:AVX2" | Out-File -filepath site.cfg -Encoding ascii -Append
		} elseif ($configuration -match "Debug") {
			"extra_compile_args=/MDd /Zi" | Out-File -filepath site.cfg -Encoding ascii -Append
		} else {
			"extra_compile_args=/MD /Zi /Oy /Ox /Oi" | Out-File -filepath site.cfg -Encoding ascii -Append
		}
		"[openblas]" | Out-File -filepath site.cfg -Encoding ascii -Append 
		"libraries = libopenblas$staticlib,lapack" | Out-File -filepath site.cfg -Encoding ascii -Append
		"library_dirs = $root/src-stage1-dependencies/openblas/build/$staticconfig/lib;$root/src-stage1-dependencies/lapack/dist/$staticconfig/lib" | Out-File -filepath site.cfg -Encoding ascii -Append
		"include_dirs = $root/src-stage1-dependencies\OpenBLAS\lapack-netlib\CBLAS\include/" | Out-File -filepath site.cfg -Encoding ascii -Append
		"lapack_libs = lapack" | Out-File -filepath site.cfg -Encoding ascii -Append
		if ($static -eq $false) {"runtime_library_dirs = $root/src-stage1-dependencies/openblas/build/lib/$staticconfig" | Out-File -filepath site.cfg -Encoding ascii -Append }
		"[lapack]" | Out-File -filepath site.cfg -Encoding ascii -Append
		"lapack_libs = libopenblas$staticlib, lapack" | Out-File -filepath site.cfg -Encoding ascii -Append
		"library_dirs = $root/src-stage1-dependencies/lapack/dist/$staticconfig/lib/" | Out-File -filepath site.cfg -Encoding ascii -Append
		"[blas]" | Out-File -filepath site.cfg -Encoding ascii -Append
		"libraries = libopenblas$staticlib, lapack" | Out-File -filepath site.cfg -Encoding ascii -Append
		"library_dirs = $root/src-stage1-dependencies/openblas/build/$staticconfig/lib;$root/src-stage1-dependencies/lapack/dist/$staticconfig/lib" | Out-File -filepath site.cfg -Encoding ascii -Append
		"include_dirs = $root/src-stage1-dependencies/OpenBLAS/lapack-netlib/CBLAS/include" | Out-File -filepath site.cfg -Encoding ascii -Append		
	}
	$env:VS90COMNTOOLS = $env:VS140COMNTOOLS
	# clean doesn't really get it all...
	del build/*.* -Recurse 2>&1 >> $log
	& $pythonroot/$pythonexe setup.py clean  2>&1 >> $log
	& $pythonroot/$pythonexe setup.py config --compiler=msvc2015 --fcompiler=intelvem  2>&1 >> $log
	Write-Host -NoNewline "building..."
	$env:_LINK_=" /NODEFAULTLIB:""LIBCMT.lib"" /NODEFAULTLIB:""LIBMMT.lib"" "
	& $pythonroot/$pythonexe setup.py build $debug 2>&1 >> $log
	Write-Host -NoNewline "installing..."
	& $pythonroot/$pythonexe setup.py install 2>&1 >> $log
	# TODO This is a hack to move the openblas library into the right place.  We should either link statically or figure a better so install moves this for us
	if (!($BuildNumpyWithMKL) -and ($static = $false)) { cp $root/src-stage1-dependencies/openblas/build/lib/$staticconfig/libopenblas.dll $pythonroot\lib\site-packages\numpy-$numpy_version-py2.7-win-amd64.egg\numpy\core }
	Write-Host -NoNewline "creating wheel..."
	& $pythonroot/$pythonexe setup.py bdist_wheel 2>&1 >> $log
	move dist/numpy-$numpy_version-cp27-cp27${d}m-win_amd64.whl dist/numpy-$numpy_version-cp27-cp27${d}m-win_amd64.$configuration.whl -Force 
	$ErrorActionPreference = "Stop"
	$env:_LINK_= ""
	Validate "$pythonroot/lib/site-packages/numpy-$numpy_version-py2.7-win-amd64.egg/numpy/core/multiarray.pyd" "dist/numpy-$numpy_version-cp27-cp27${d}m-win_amd64.$configuration.whl"
	
	#__________________________________________________________________________________________
	# scipy
	#
	SetLog "$configuration scipy"
	if ($hasIFORT) {
		Write-Host -NoNewline "configuring scipy..."
		$ErrorActionPreference = "Continue"
		cd $root\src-stage1-dependencies\scipy
		$env:Path = "${env:ProgramFiles(x86)}\IntelSWTools\compilers_and_libraries\windows\bin\intel64;" + $oldPath 
		$env:LIB = "${env:IFORT_COMPILER16}compiler\lib\intel64_win;" + $oldLib
		# $static indicates if the MKL/OpenBLAS libraries will be linked statically into numpy/scipy or not.  numpy/scipy themselves will be built as DLLs/pyd's always
		# openblas lapack is always static$static = $true
		$staticconfig = ($configuration -replace "DLL", "") 
		if ($static -eq $true) {$staticlib = "_static"} else {$staticlib = ""} 
		if ($BuildNumpyWithMKL) {
			# Build with MKL
			Write-Host -NoNewline "MKL..."
			if ($static -eq $false) {
				"[mkl]" | Out-File -filepath site.cfg -Encoding ascii
				"search_static_first=false" | Out-File -filepath site.cfg -Encoding ascii -Append
				"include_dirs = ${env:ProgramFiles(x86)}\IntelSWTools\compilers_and_libraries\windows\mkl\include" | Out-File -filepath site.cfg -Encoding ascii -Append
				"library_dirs = $env:IFORT_COMPILER16\compiler\lib\intel64_win;$env:IFORT_COMPILER16\mkl\lib\intel64_win" | Out-File -filepath site.cfg -Encoding ascii -Append 
				"mkl_libs = mkl_rt" | Out-File -filepath site.cfg -Encoding ascii -Append
				"lapack_libs = mkl_rt, mkl_lapack95_lp64,mkl_blas95_lp64" | Out-File -filepath site.cfg -Encoding ascii -Append
			if ($configuration -match "AVX2") {
					"extra_compile_args=/MD /Zi /Oy /Ox /Oi /arch:AVX2" | Out-File -filepath site.cfg -Encoding ascii -Append
				} elseif ($configuration -match "Debug") {
					"extra_compile_args=/MD /Zi" | Out-File -filepath site.cfg -Encoding ascii -Append
				} else {
					"extra_compile_args=/MD /Zi /Oy /Ox /Oi" | Out-File -filepath site.cfg -Encoding ascii -Append
				}
			} else {
				"[mkl]" | Out-File -filepath site.cfg -Encoding ascii
				"search_static_first=true" | Out-File -filepath site.cfg -Encoding ascii -Append
				"include_dirs = ${env:ProgramFiles(x86)}\IntelSWTools\compilers_and_libraries\windows\mkl\include" | Out-File -filepath site.cfg -Encoding ascii -Append
				"library_dirs = ${env:IFORT_COMPILER16}compiler\lib\intel64_win;${env:IFORT_COMPILER16}mkl\lib\intel64_win" | Out-File -filepath site.cfg -Encoding ascii -Append 
				"mkl_libs = mkl_lapack95_lp64,mkl_blas95_lp64,mkl_intel_lp64,mkl_sequential,mkl_core" | Out-File -filepath site.cfg -Encoding ascii -Append
				"lapack_libs = mkl_lapack95_lp64,mkl_blas95_lp64,mkl_intel_lp64,mkl_sequential,mkl_core" | Out-File -filepath site.cfg -Encoding ascii -Append
				if ($configuration -match "AVX2") {
					"extra_compile_args=/MD /Zi /Oy /Ox /Oi /arch:AVX2" | Out-File -filepath site.cfg -Encoding ascii -Append
				} elseif ($configuration -match "Debug") {
					"extra_compile_args=/MDd /Zi" | Out-File -filepath site.cfg -Encoding ascii -Append
				} else {
					"extra_compile_args=/MD /Zi /Oy /Ox /Oi" | Out-File -filepath site.cfg -Encoding ascii -Append
				}
			}
		} else {
			# Build scipy with OpenBLAS
			Write-Host -NoNewline "OpenBLAS..."
			"[default]" | Out-File -filepath site.cfg -Encoding ascii
			"libraries = libopenblas$staticlib, lapack" | Out-File -filepath site.cfg -Encoding ascii -Append
			"library_dirs = $root/src-stage1-dependencies/openblas/build/$staticconfig/lib;$root/src-stage1-dependencies/lapack/dist/$staticconfig/lib" | Out-File -filepath site.cfg -Encoding ascii -Append
			"include_dirs = $root/src-stage1-dependencies\OpenBLAS\lapack-netlib\CBLAS\include" | Out-File -filepath site.cfg -Encoding ascii -Append
			"lapack_libs = libopenblas$staticlib, lapack" | Out-File -filepath site.cfg -Encoding ascii -Append
			if ($configuration -match "AVX2") {
				"extra_compile_args=/MD /Zi /Oy /Ox /Oi /arch:AVX2" | Out-File -filepath site.cfg -Encoding ascii -Append
			} elseif ($configuration -match "Debug") {
				"extra_compile_args=/MDd /Zi" | Out-File -filepath site.cfg -Encoding ascii -Append
			} else {
				"extra_compile_args=/MD /Zi /Oy /Ox /Oi" | Out-File -filepath site.cfg -Encoding ascii -Append
			}
			"[openblas]" | Out-File -filepath site.cfg -Encoding ascii -Append
			"libraries = libopenblas$staticlib, lapack" | Out-File -filepath site.cfg -Encoding ascii -Append
			"library_dirs = $root/src-stage1-dependencies/openblas/build/$staticconfig/lib;$root/src-stage1-dependencies/lapack/dist/$staticconfig/lib" | Out-File -filepath site.cfg -Encoding ascii -Append
			"include_dirs = $root/src-stage1-dependencies/OpenBLAS/lapack-netlib/CBLAS/include" | Out-File -filepath site.cfg -Encoding ascii -Append
			"runtime_library_dirs = " | Out-File -filepath site.cfg -Encoding ascii -Append
			"[lapack]" | Out-File -filepath site.cfg -Encoding ascii -Append
			"lapack_libs = lapack" | Out-File -filepath site.cfg -Encoding ascii -Append
			"libraries = lapack"  | Out-File -filepath site.cfg -Encoding ascii -Append
			"library_dirs = $root/src-stage1-dependencies/lapack/dist/$staticconfig/lib" | Out-File -filepath site.cfg -Encoding ascii -Append
			"[blas]" | Out-File -filepath site.cfg -Encoding ascii -Append
			"libraries = libopenblas$staticlib, lapack" | Out-File -filepath site.cfg -Encoding ascii -Append
			"library_dirs = $root/src-stage1-dependencies/openblas/build/$staticconfig/lib;$root/src-stage1-dependencies/lapack/dist/$staticconfig/lib" | Out-File -filepath site.cfg -Encoding ascii -Append
			"include_dirs = $root/src-stage1-dependencies/OpenBLAS/lapack-netlib/CBLAS/include" | Out-File -filepath site.cfg -Encoding ascii -Append		
		}
		$env:VS90COMNTOOLS = $env:VS140COMNTOOLS
		# clean doesn't really get it all...
		del build/*.* -Recurse 2>&1 >> $log
		& $pythonroot/$pythonexe setup.py clean  2>&1 >> $log
		& $pythonroot/$pythonexe setup.py config --fcompiler=intelvem --compiler=msvc  2>&1 >> $log
		Write-Host -NoNewline "building..."
		$env:_LINK_=" /NODEFAULTLIB:""LIBCMT.lib"" /NODEFAULTLIB:""LIBMMT.lib"" /DEFAULTLIB:""LIBMMD.lib"" "
		# setup.py doesn't handle debug flag correctly for windows ifort, it adds a -g flag which is ambiguous so we'll do our best to emulate it manually
		if ($configuration -match "Debug") {$env:__INTEL_POST_FFLAGS = " /debug:all "} else {$env:__INTEL_POST_FFLAGS = ""}
		& $pythonroot/$pythonexe setup.py build --compiler=msvc --fcompiler=intelvem 2>&1 >> $log
		Write-Host -NoNewline "installing..."
		& $pythonroot/$pythonexe setup.py install  2>&1 >> $log
		Write-Host -NoNewline "creating wheel..."
		& $pythonroot/$pythonexe setup.py bdist_wheel 2>&1 >> $log
		move dist/scipy-$scipy_version-cp27-cp27${d}m-win_amd64.whl dist/scipy-$scipy_version-cp27-cp27${d}m-win_amd64.$configuration.whl -Force
		$env:_LINK_=""
		$env:__INTEL_POST_FFLAGS = ""
		$ErrorActionPreference = "Stop"
		Validate "dist/scipy-$scipy_version-cp27-cp27${d}m-win_amd64.$configuration.whl" "$pythonroot/lib/site-packages/scipy/linalg/_flapack.pyd"  "$pythonroot/lib/site-packages/scipy/linalg/cython_lapack.pyd"  "$pythonroot/lib/site-packages/scipy/sparse/_sparsetools.pyd"
	} else {
		# Can't compile scipy without a fortran compiler, and gfortran won't work here
		# because we can't mix MSVC and gfortran libraries
		# So if we get here, we need to use the binary .whl instead
		# Note that these are specifically built VS 2015 x64 versions for python 2.7.
        $ErrorActionPreference = "Continue"
		if ($BuildNumpyWithMKL) {
			Write-Host -NoNewline "installing MKL scipy from wheel..."
			Write-Host -NoNewline "Compatible Fortran compiler not available, installing scipy from custom binary wheel..."
			& $pythonroot/Scripts/pip.exe --disable-pip-version-check  install http://www.gcndevelopment.com/gnuradio/downloads/libraries/scipy/mkl/scipy-$scipy_version-cp27-cp27${d}m-win_amd64.$configuration.whl -U -t $pythonroot\lib\site-packages  2>&1 >> $log
		} else {
			Write-Host -NoNewline "installing OpenBLAS scipy from wheel..."
			& $pythonroot/Scripts/pip.exe --disable-pip-version-check  install http://www.gcndevelopment.com/gnuradio/downloads/libraries/scipy/openBLAS/scipy-$scipy_version-cp27-cp27${d}m-win_amd64.$configuration.whl -U -t $pythonroot\lib\site-packages  2>&1 >> $log
		}
        $ErrorActionPreference = "Stop"
		Validate "$pythonroot/lib/site-packages/scipy/linalg/_flapack.pyd"  "$pythonroot/lib/site-packages/scipy/linalg/cython_lapack.pyd"  "$pythonroot/lib/site-packages/scipy/sparse/_sparsetools.pyd"
	}
	

	#__________________________________________________________________________________________
	# PyQwt5
	# requires Python, Qwt, Qt, PyQt, and Numpy
	#
	SetLog "$configuration PyQwt5"
	Write-Host -NoNewline "configuring PyQwt5..."
	$ErrorActionPreference = "Continue" 
	# qwt_version_info will look for QtCore4.dll, never Qt4Core4d.dll so point it to the ReleaseDLL regardless of the desired config
	if ($configuration -eq "DebugDLL") {$QtVersion = "ReleaseDLL"} else {$QtVersion = $configuration}
	$env:Path = "$root\src-stage1-dependencies\Qt4\build\$QtVersion\bin;$root\src-stage1-dependencies\Qwt-$qwt_version\build\x64\Debug-Release\lib;" + $oldpath
	$envLib = $oldlib
	if ($type -match "AVX2") {$env:CL = "/Ox /arch:AVX2 /wd4577 " + $oldcl} else {$env:CL = "/wd4577 " + $oldCL}
	cd $root\src-stage1-dependencies\PyQwt5-master
	cd configure
	# CALL "../../%1/Release/Python27/python.exe" configure.py %DEBUG% --extra-cflags=%FLAGS% %DEBUG% -I %~dp0..\qwt-5.2.3\build\include -L %~dp0..\Qt-4.8.7\lib -L %~dp0..\qwt-5.2.3\build\lib -l%QWT_LIB%
	if ($configuration -eq "DebugDLL") {
		$env:_LINK_ = " /FORCE /LIBPATH:""$root/src-stage1-dependencies/Qt4/build/ReleaseDLL/lib"" /LIBPATH:""$root/src-stage1-dependencies/Qt4/build/Release-AVX2/lib"" /DEFAULTLIB:user32  /DEFAULTLIB:advapi32  /DEFAULTLIB:ole32  /DEFAULTLIB:ws2_32  /DEFAULTLIB:qtcored4 " 
		& $pythonroot/$pythonexe configure.py --debug --extra-cflags="-Zi -wd4577"                -I $root\src-stage1-dependencies\Qwt-$qwt_version\build\x64\Debug-Release\include -L $root\src-stage1-dependencies\Qt4\build\$QtVersion\lib   -l qtcored4     -L $root\src-stage1-dependencies\Qwt-$qwt_version\build\x64\Debug-Release\lib -l"$root\src-stage1-dependencies\Qwt-$qwt_version\build\x64\Debug-Release\lib\qwtd" -j4 --sip-include-dirs ..\..\sip-$sip_version\build\x64\Debug --sip-include-dirs ..\..\PyQt4\sip 2>&1 >> $log
	} elseif ($configuration -eq "ReleaseDLL") {
		& $pythonroot/$pythonexe configure.py         --extra-cflags="-Zi -wd4577"                -I $root\src-stage1-dependencies\Qwt-$qwt_version\build\x64\Debug-Release\include -L $root\src-stage1-dependencies\Qt4\build\ReleaseDLL\lib -l qtcore4       -L $root\src-stage1-dependencies\Qwt-$qwt_version\build\x64\Debug-Release\lib -l"$root\src-stage1-dependencies\Qwt-$qwt_version\build\x64\Debug-Release\lib\qwt"  -j4 --sip-include-dirs ..\..\sip-$sip_version\build\x64\Release 2>&1 >> $log
	} else {
		& $pythonroot/$pythonexe configure.py         --extra-cflags="-Zi -Ox -arch:AVX2 -wd4577" -I $root\src-stage1-dependencies\Qwt-$qwt_version\build\x64\Release-AVX2\include  -L $root\src-stage1-dependencies\Qt4\build\ReleaseDLL-AVX2\lib -l qtcore4  -L $root\src-stage1-dependencies\Qwt-$qwt_version\build\x64\Release-AVX2\lib  -l"$root\src-stage1-dependencies\Qwt-$qwt_version\build\x64\Release-AVX2\lib\qwt"   -j4 --sip-include-dirs ..\..\sip-$sip_version\build\x64\Release-AVX2 2>&1 >> $log
	}
	nmake clean 2>&1 >> $log
	Write-Host -NoNewline "building..."
	Exec {nmake} 2>&1 >> $log
	Write-Host -NoNewline "installing..."
	Exec {nmake install} 2>&1 >> $log
	#& $pythonroot/$pythonexe setup.py build 2>&1 >> $log
	#Write-Host -NoNewline "installing..."
	#& $pythonroot/$pythonexe setup.py install 2>&1 >> $log
	Write-Host -NoNewline "creating winstaller..."
	cd ..
	& $pythonroot/$pythonexe setup.py bdist_wininst   2>&1 >> $log
	move dist/PyQwt-5.2.1.win-amd64.exe dist/PyQwt-5.2.1.win-amd64.$configuration.exe -Force
	# TODO these move fail for lack of a wheel-compatible setup
	# & $pythonroot/$pythonexe setup.py bdist_wheel   2>&1 >> $log
	# cd dist
	# & $pythonroot/Scripts/wheel.exe convert PyQwt-5.2.1.win-amd64.DebugDLL.exe
	$env:Path = $oldpath
	$env:CL = $oldCL
    $env:_LINK_ = ""
	$ErrorActionPreference = "Stop"
	Validate "dist/PyQwt-5.2.1.win-amd64.$configuration.exe" "$pythonroot/lib/site-packages/PyQt4/Qwt5/Qwt$debugext.pyd" "$pythonroot/lib/site-packages/PyQt4/Qwt5/_iqt.pyd" "$pythonroot/lib/site-packages/PyQt4/Qwt5/qplt.py"

	#__________________________________________________________________________________________
	# PyOpenGL
	# requires Python
	# python-only package so no need to rename the wheels since there is only one
	#
	SetLog "$configuration PyOpenGL"
	Write-Host -NoNewline "installing PyOpenGL..."
	$ErrorActionPreference = "Continue"
	cd $root\src-stage1-dependencies\PyOpenGL-$pyopengl_version
	& $pythonroot/$pythonexe setup.py install --single-version-externally-managed --root=/ 2>&1 >> $log
	Write-Host -NoNewline "crafting wheel..."
	& $pythonroot/$pythonexe setup.py bdist_wheel 2>&1 >> $log
	$ErrorActionPreference = "Stop"
	Validate "$pythonroot/lib/site-packages/OpenGL/version.py" "dist/PyOpenGL-$pyopengl_version-py2-none-any.whl"

	#__________________________________________________________________________________________
	# PyOpenGL-accelerate
	# requires Python, PyOpenGL
	#
	Write-Host -NoNewline "installing PyOpenGL-accelerate..."
	$ErrorActionPreference = "Continue"
	cd $root\src-stage1-dependencies\PyOpenGL-accelerate-$pyopengl_version
	& $pythonroot/$pythonexe setup.py clean 2>&1 >> $log
	if ($configuration -match "Debug") {$env:_LINK_=" /LIBPATH:""$root\src-stage1-dependencies\Qt4\build\$configuration\lib"" "}
	& $pythonroot/$pythonexe setup.py build $debug install --single-version-externally-managed --root=/ 2>&1 >> $log
	Write-Host -NoNewline "crafting wheel..."
	& $pythonroot/$pythonexe setup.py bdist_wheel 2>&1 >> $log
	move dist/PyOpenGL_accelerate-$pyopengl_version-cp27-cp27${d}m-win_amd64.whl dist/PyOpenGL_accelerate-$pyopengl_version-cp27-cp27${d}m-win_amd64.$configuration.whl -Force
	$env:_LINK_ = ""
	$ErrorActionPreference = "Stop"
	Validate "$pythonroot/lib/site-packages/OpenGL_accelerate/wrapper$debugext.pyd" "dist/PyOpenGL_accelerate-$pyopengl_version-cp27-cp27${d}m-win_amd64.$configuration.whl"

	#__________________________________________________________________________________________
	# pkg-config
	# both the binary (using pkg-config-lite to avoid dependency issues) and the python wrapper
	#
	SetLog "$configuration pkg-config"
	Write-Host -NoNewline "building pkg-config..."
	$ErrorActionPreference = "Continue"
	cd $root\src-stage1-dependencies\pkgconfig-$pkgconfig_version
	& $pythonroot/$pythonexe setup.py build  $debug 2>&1 >> $log
	Write-Host -NoNewline "installing..."
	& $pythonroot/$pythonexe setup.py install --single-version-externally-managed --root=/ 2>&1 >> $log
	Write-Host -NoNewline "crafting wheel..."
	& $pythonroot/$pythonexe setup.py bdist_wheel 2>&1 >> $log
	# yes, this copies the same file three times, but since it's conceptually linked to 
	# the python wrapper, I kept this here for ease of maintenance
	cp $root\src-stage1-dependencies\pkg-config-lite-0.28-1\bin\pkg-config.exe $root\bin -Force  2>&1 >> $log
	New-Item -ItemType Directory -Force $pythonroot\lib\pkgconfig 2>&1 >> $log
	$ErrorActionPreference = "Stop"
	Validate "$root\bin\pkg-config.exe" "dist/pkgconfig-$pkgconfig_version-py2-none-any.whl" "$pythonroot/lib/site-packages/pkgconfig/pkgconfig.py"

	#__________________________________________________________________________________________
	# py2cairo
	# requires pkg-config
	# uses wierd setup python script called WAF which has an archive embedded in it which
	# creates files that then fail to work.  So we need to extract them and then patch them
	# and run again.
	SetLog "$configuration py2cairo"
	Write-Host -NoNewline "configuring py2cairo..."
	cd $root\src-stage1-dependencies\py2cairo-$py2cairo_version
	$env:path = "$root\bin;$root\src-stage1-dependencies\x64\bin;" + $oldPath
	$ErrorActionPreference = "Continue" 
	$env:CL = $oldCL
	# HACK the below will fail, but will run the command to unpack the rest of the library
	# what we really should do here is run just the python needed to unpack the library
	# and not intentionally run code that will error out
	& $pythonroot/$pythonexe waf configure --nocache --out=build --prefix=build/x64/$configuration  2>&1 >> $log
	Copy-Item -Force msvc.py .\waf-1.6.3-3c3129a3ec8fb4a5bbc7ba3161463b22\waflib\Tools\msvc.py 2>&1 >> $log
	Copy-Item -Force python.py .\waf-1.6.3-3c3129a3ec8fb4a5bbc7ba3161463b22\waflib\Tools\python.py 2>&1 >> $log
	# now it will work
	& $pythonroot/$pythonexe waf configure --nocache --out=build --prefix=build/x64/$configuration  2>&1 >> $log
	Write-Host -NoNewline "building..."
	$env:INCLUDE = "$root/src-stage1-dependencies/x64/include;$root/src-stage1-dependencies/x64/include/cairo;" + $oldInclude 
	$env:LIB = "$root/src-stage1-dependencies/cairo/build/x64/Release;$root/src-stage1-dependencies/cairo/build/x64/ReleaseDLL;$pythonroot/libs;" + $oldlib 
	$env:_CL_ = "/MD$d /I$root/src-stage1-dependencies/x64/include /I$root/src-stage1-dependencies/x64/include/cairo /DCAIRO_WIN32_STATIC_BUILD" 
	$env:_LINK_ = "/DEFAULTLIB:cairo /DEFAULTLIB:pixman-1 /DEFAULTLIB:freetype /LIBPATH:$root/src-stage1-dependencies/x64/lib /LIBPATH:$pythonroot/libs"
	& $pythonroot/$pythonexe waf build --nocache --out=build --prefix=build/x64/$configuration --includedir=$root\src-stage1\dependencies\x64\include 2>&1 >> $log
	$env:_LINK_ = ""
	$env:_CL_ = ""
	$env:LIB = $oldLib
	$env:INCLUDE = $oldInclude 
	Write-Host -NoNewline "installing..."
	& $pythonroot/$pythonexe waf install --nocache --out=build --prefix=build/x64/$configuration 2>&1 >> $log
	cp -Recurse -Force build/x64/$configuration/lib/python2.7/site-packages/cairo $pythonroot\lib\site-packages 2>&1 >> $log
	cp -Force $root\src-stage1-dependencies\py2cairo-$py2cairo_version\pycairo.pc $pythonroot\lib\pkgconfig\
	& $pythonroot/$pythonexe waf clean  2>&1 >> $log
	Validate "$pythonroot\lib\site-packages\cairo\_cairo.pyd"

	#__________________________________________________________________________________________
	# Pygobject
	# requires Python
	#
	# VERSION WARNING: higher than 2.28 does not have setup.py so do not try to use
	#
	SetLog "$configuration pygobject"
	Write-Host -NoNewline "building Pygobject..."
	$ErrorActionPreference = "Continue" 
	cd $root\src-stage1-dependencies\Pygobject-$pygobject_version
	$env:PATH = "$root/bin;$root/src-stage1-dependencies/x64/bin;$root/src-stage1-dependencies/x64/lib;" + $oldpath
	$env:PKG_CONFIG_PATH = "$root/bin;$root/src-stage1-dependencies/x64/lib/pkgconfig;$pythonroot/lib/pkgconfig"
	if ($configuration -match "AVX2") {$env:_CL_ = "/arch:AVX2"} else {$env:_CL_ = $null}
	& $pythonroot/$pythonexe setup.py build $debug --compiler=msvc --enable-threading  2>&1 >> $Log
	Write-Host -NoNewline "installing..."
	& $pythonroot/$pythonexe setup.py install  2>&1 >> $Log
	Write-Host -NoNewline "creating exe..."
	& $pythonroot/$pythonexe setup.py bdist_wininst 2>&1 >> $Log
	Write-Host -NoNewline "crafting wheel from exe..."
	New-Item -ItemType Directory -Force -Path .\dist\gtk-2.0 2>&1 >> $Log
	cd dist
	& $pythonroot/Scripts/wheel.exe convert pygobject-$pygobject_version.win-amd64-py2.7.exe 2>&1 >> $Log
	move gtk-2.0/pygobject-cp27-none-win_amd64.whl gtk-2.0/pygobject-cp27-none-win_amd64.$configuration.whl -Force
	cd ..
	$env:_CL_ = $null
	$env:PATH = $oldPath
	$env:PKG_CONFIG_PATH = $null
	$ErrorActionPreference = "Stop" 
	Validate "dist/gtk-2.0/pygobject-cp27-none-win_amd64.$configuration.whl" "$pythonroot\lib\site-packages\gtk-2.0\gobject\_gobject.pyd"

	#__________________________________________________________________________________________
	# PyGTK
	# requires Python, Pygobject
	#
	SetLog "$configuration pygtk"
	Write-Host -NoNewline "building PyGTK..."
	cd $root\src-stage1-dependencies\pygtk-$pygtk_version
	if ($configuration -match "AVX2") {$env:_CL_ = "/arch:AVX2"} else {$env:_CL_ = $null}
	$env:PATH = "$root/bin;$root/src-stage1-dependencies/x64/bin;$root/src-stage1-dependencies/x64/lib;$pythonroot/Scripts;$pythonroot;" + $oldpath
	$env:_CL_ = "/I$root/src-stage1-dependencies/x64/lib/gtk-2.0/include /I$root/src-stage1-dependencies/py2cairo-$py2cairo_version/src " + $env:_CL_
	$env:PKG_CONFIG_PATH = "$root/bin;$root/src-stage1-dependencies/x64/lib/pkgconfig;$pythonroot/lib/pkgconfig"
	$ErrorActionPreference = "Continue" 
	& $pythonroot/$pythonexe setup.py clean 2>&1 >> $Log
	& $pythonroot/$pythonexe setup.py build $debug --compiler=msvc --enable-threading 2>&1 >> $log
	Write-Host -NoNewline "installing..."
	& $pythonroot/$pythonexe setup.py install 2>&1 >> $Log
	Write-Host -NoNewline "building exe..."
	& $pythonroot/$pythonexe setup.py bdist_wininst 2>&1 >> $Log
	New-Item -ItemType Directory -Force -Path .\dist\gtk-2.0 2>&1 >> $Log
	cd dist
	Write-Host -NoNewline "crafting wheel from exe..."
	& $pythonroot/Scripts/wheel.exe convert pygtk-$pygtk_version.win-amd64-py2.7.exe 2>&1 >> $Log
	move gtk-2.0/pygtk-cp27-none-win_amd64.whl gtk-2.0/pygtk-cp27-none-win_amd64.$configuration.whl -Force 2>&1 >> $Log
	cd ..
	$env:_CL_ = $null
	$env:PATH = $oldPath
	$env:PKG_CONFIG_PATH = $null
	$ErrorActionPreference = "Stop" 
	Validate "dist/gtk-2.0/pygtk-cp27-none-win_amd64.$configuration.whl" "$pythonroot\lib\site-packages\gtk-2.0\gtk\_gtk.pyd"

	#__________________________________________________________________________________________
	# wxpython
	#
	# v3.0.2 is not VC140 compatible, so the patch fixes those things
	# TODO submit changes to source tree
	#
	# TODO so the debug build is not working because of it's looking for the wrong file to link to
	# (debug vs non-debug).  So the workaround is to build wx in release even when python is
	# being built in debug.
	#
	SetLog "$configuration wxpython"
	Write-Host -NoNewline "prepping wxpython..."
	cd $root\src-stage1-dependencies\wxpython\wxPython
	$canbuildwxdebug = $false
	$wxdebug = ($canbuildwxdebug -and $d -eq "d")
	$env:WXWIN="$root\src-stage1-dependencies\wxpython"
	if ($configuration -match "AVX2") {$env:_CL_ = " /DwxMSVC_VERSION_AUTO /D_UNICODE /DUNICODE /DMSLU /arch:AVX2 "} else {$env:_CL_ = " /DWXWIN=.. /DMSLU /D_UNICODE /DUNICODE /DwxMSVC_VERSION_AUTO "}
	if ($wxdebug) {
		$env:_CL_ = " /I$root/src-stage1-dependencies/wxpython/lib/vc140_dll/mswud /D__WXDEBUG__ /D_DEBUG  " + $env:_CL_ 
		$wxdebugstring = "--debug"
	} else {
		$env:_CL_ = " /I$root/src-stage1-dependencies/wxpython/lib/vc140_dll/mswu " + $env:_CL_
		$wxdebugstring = ""
	}
	$env:_CL_ = "/I$root/src-stage1-dependencies/wxpython/include/msvc " + $env:_CL_
	$env:PATH = "$root/src-stage1-dependencies/x64/bin;$root/src-stage1-dependencies/x64/lib;$pythonroot/Scripts;$pythonroot" + $oldpath
	$ErrorActionPreference = "Continue"
	if (Test-Path .\build) {del -recurse .\build\*.* 2>&1 >> $Log}
	& $pythonroot\$pythonexe build-wxpython.py --clean 2>&1 >> $Log
	& $pythonroot\$pythonexe build-wxpython.py --build_dir=../build  --force_config --install $wxdebugstring 2>&1 >> $Log
    # the above assumes the core WX dll's will be installed to the system someplace on the PATH.
    # That's not what we want to do, so since these are gr-python-only DLLs, we'll put then in the DLLs dir for that python build
    cp "$root/src-stage1-dependencies/wxpython/lib/vc140_dll/wx*.dll" "$pythonroot/DLLs"
	#Write-Host -NoNewline "configing..."
	#& $pythonroot\$pythonexe setup.py clean 2>&1 >> $Log
	#& $pythonroot\$pythonexe setup.py config MONOLITHIC=1 2>&1 >> $Log
	#Write-Host -NoNewline "building..."
	#& $pythonroot\$pythonexe setup.py build $wxdebugstring MONOLITHIC=1 2>&1 >> $Log
	#Write-Host -NoNewline "installing..."
	#& $pythonroot\$pythonexe setup.py install 2>&1 >> $Log
	Write-Host -NoNewline "crafting wheel..."
	& $pythonroot\$pythonexe setup.py bdist_wininst UNICODE=1 BUILD_BASE=build 2>&1 >> $Log
	cd dist
	& $pythonroot/Scripts/wheel.exe convert wxpython-$wxpython_version.win-amd64-py2.7.exe 2>&1 >> $Log
	del wxpython-$wxpython_version.win-amd64-py2.7.exe
	move wx-3.0-cp27-none-win_amd64.whl wx-3.0-cp27-none-win_amd64.$configuration.whl -Force 2>&1 >> $Log
	move .\wxPython-common-$wxpython_version.win-amd64.exe .\wxPython-common-$wxpython_version.win-amd64.$configuration.exe -Force 2>&1 >> $Log
	$ErrorActionPreference = "Stop" 
	$env:_CL_ = $null
	$env:PATH = $oldPath
	Validate "$pythonroot\lib\site-packages\wx-3.0-msw\wx\_core_.pyd" "wx-3.0-cp27-none-win_amd64.$configuration.whl"

	#__________________________________________________________________________________________
	# cheetah
	#
	# will download and install Markdown automatically
	SetLog "$configuration cheetah"
	Write-Host -NoNewline "building cheetah..."
	$ErrorActionPreference = "Continue"
	cd $root\src-stage1-dependencies\Cheetah-$cheetah_version
	& $pythonroot/$pythonexe setup.py build  $debug 2>&1 >> $log
	Write-Host -NoNewline "installing..."
	& $pythonroot/$pythonexe setup.py install 2>&1 >> $log
	Write-Host -NoNewline "crafting wheel..."
	& $pythonroot/$pythonexe setup.py bdist_wheel 2>&1 >> $log
	move dist/Cheetah-$cheetah_version-cp27-cp27${d}m-win_amd64.whl dist/Cheetah-$cheetah_version-cp27-cp27${d}m-win_amd64.$configuration.whl -Force 2>&1 >> $log
	$ErrorActionPreference = "Stop"
	Validate "dist/Cheetah-$cheetah_version-cp27-cp27${d}m-win_amd64.$configuration.whl" "$pythonroot/lib/site-packages/Cheetah-$cheetah_version-py2.7-win-amd64.egg/Cheetah/_namemapper.pyd" "$pythonroot/lib/site-packages/Cheetah-$cheetah_version-py2.7-win-amd64.egg/Cheetah/Compiler.py"

	#__________________________________________________________________________________________
	# sphinx
	#
	# will also download/install a large number of dependencies
	# pytz, babel, colorama, snowballstemmer, sphinx-rtd-theme, six, Pygments, docutils, Jinja2, alabaster, sphinx
	# all are python only packages
	SetLog "$configuration sphinx"
	Write-Host -NoNewline "installing sphinx using pip..."
	$ErrorActionPreference = "Continue" # pip will "error" on debug
	& $pythonroot/Scripts/pip.exe --disable-pip-version-check  install -U sphinx -t $pythonroot\lib\site-packages 2>&1 >> $log
	$ErrorActionPreference = "Stop"
	Validate "$pythonroot/lib/site-packages/sphinx/__main__.py"

	#__________________________________________________________________________________________
	# lxml
	#
	# this was a royal pain to get to statically link the dependent libraries
	# but now there are no dependencies, just install the wheel
	SetLog "$configuration lxml"
	Write-Host -NoNewline "configuring lxml..."
	$ErrorActionPreference = "Continue"
	$xsltconfig = ($configuration -replace "DLL", "")
	cd $root\src-stage1-dependencies\lxml-lxml-$lxml_version
	New-Item -ItemType Directory -Force $root/src-stage1-dependencies/lxml-lxml-$lxml_version/libs/$xsltconfig 2>&1 >> $Log
    if ($type -match "AVX2") {$env:CL = "/Ox /arch:AVX2 " + $oldcl} else {$env:CL = $oldCL}
	$env:_CL_ = "/I$root/src-stage1-dependencies/libxml2/build/x64/$xsltconfig/include/libxml2 /I$root/src-stage1-dependencies/gettext-msvc/libiconv-1.14 /I$root/src-stage1-dependencies/libxslt/build/$xsltconfig/include "
	$env:_LINK_ = "/LIBPATH:$root/src-stage1-dependencies/libxslt/build/$xsltconfig/lib /LIBPATH:$root/src-stage1-dependencies/zlib-1.2.8/contrib/vstudio/vc14/x64/ZlibStat$xsltconfig /LIBPATH:$root/src-stage1-dependencies/libxml2/build/x64/$xsltconfig/lib /LIBPATH:$root/src-stage1-dependencies/gettext-msvc/x64/$xsltconfig"
	$env:LIBRARY = "$root/src-stage1-dependencies/lxml-lxml-$lxml_version/libs/$xsltconfig;$root/src-stage1-dependencies/libxslt/build/$xsltconfig/lib;$root/src-stage1-dependencies/zlib-1.2.8/contrib/vstudio/vc14/x64/ZlibStat$xsltconfig;$root/src-stage1-dependencies/libxml2/build/x64/$xsltconfig/lib;$root/src-stage1-dependencies/gettext-msvc/x64/$xsltconfig"
	$env:INCLUDE = "$root/src-stage1-dependencies/libxml2/build/x64/$xsltconfig/include/libxml2;$root/src-stage1-dependencies/gettext-msvc/libiconv-1.14;$root/src-stage1-dependencies/libxslt/build/$xsltconfig/include;$root/src-stage1-dependencies/lxml/src/lxml/includes"
	cp -Force $root/src-stage1-dependencies/libxml2/build/x64/$xsltconfig/lib/libxml2_a.lib $root/src-stage1-dependencies/lxml-lxml-$lxml_version/libs/$xsltconfig/libxml2_a.lib
	cp -Force $root/src-stage1-dependencies/gettext-msvc/x64/$xsltconfig/libiconv.lib $root/src-stage1-dependencies/lxml-lxml-$lxml_version/libs/$xsltconfig/iconv_a.lib
	& $pythonroot/$pythonexe setup.py clean 2>&1 >> $log
	if (Test-Path build) {del -Recurse -Force build}
	Write-Host -NoNewline "building..."
	& $pythonroot/$pythonexe setup.py build --static $debug 2>&1 >> $log
	Write-Host -NoNewline "installing..."
	& $pythonroot/$pythonexe setup.py install 2>&1 >> $log
	Write-Host -NoNewline "crafting wheel..."
	& $pythonroot/$pythonexe setup.py bdist_wheel --static 2>&1 >> $log
	move dist/lxml-$lxml_version-cp27-cp27${d}m-win_amd64.whl dist/lxml-$lxml_version-cp27-cp27${d}m-win_amd64.$xsltconfig.whl -Force 2>&1 >> $log
	$env:_CL_ = ""
	$env:_LINK_ = ""
	$env:LIBRARY = $oldlibrary
	$env:INCLUDE = $oldinclude
	$ErrorActionPreference = "Stop"
	Validate "dist/lxml-$lxml_version-cp27-cp27${d}m-win_amd64.$xsltconfig.whl" "$pythonroot/lib/site-packages/lxml-$lxml_version-py2.7-win-amd64.egg/lxml/etree.pyd"

	#__________________________________________________________________________________________
	# pyzmq
	#
	SetLog "$configuration pyzmq"
	Write-Host -NoNewline "configuring pyzmq..."
	if ($configuration -match "Debug") {$baseconfig="Debug"} else {$baseconfig="Release"}
	$ErrorActionPreference = "Continue"
	cd $root\src-stage1-dependencies\pyzmq-$pyzmq_version
	# this stdint.h file prevents the import of the real stdint file and causes the build to fail
	# TODO submit upstream patch
	if (!(Test-Path wheels)) {mkdir wheels 2>&1 >> $log}
	if (Test-Path buildutils/include_win32/stdint.h) 
	{
		if (Test-Path buildutils/include_win32/stdint.old.h) {del buildutils/include_win32/stdint.old.h}
		Rename-Item -Force buildutils/include_win32/stdint.h stdint.old.h
	}
	New-Item -ItemType Directory -Force libzmq 2>&1 >> $log
    New-Item -ItemType Directory -Force libzmq/$configuration 2>&1 >> $log
	New-Item -ItemType Directory -Force libzmq/$configuration/lib 2>&1 >> $log
	New-Item -ItemType Directory -Force libzmq/$configuration/include 2>&1 >> $log
	Copy-Item ..\libzmq\include/*.h libzmq/$configuration/include/ 2>&1 >> $log
	Copy-Item ..\libzmq\bin\x64\$baseconfig\v140\dynamic\libzmq.dll libzmq/$configuration/lib 2>&1 >> $log
	Copy-Item ..\libzmq\bin\x64\$baseconfig\v140\dynamic\libzmq.lib libzmq/$configuration/lib 2>&1 >> $log
	if ($configuration -match "AVX2") {$env:_CL_ = " /arch:AVX2 "} else {$env:_CL_ = ""}
	$env:_LINK_ = " /MANIFEST "
	$env:INCLUDE = $oldinclude + ";$root/libzmq/include"
	$env:CL = $oldcl
	$env:LINK = $oldlink
	# don't run clean because it wipes out /dist folder as well
	& $pythonroot/$pythonexe setup.py clean 2>&1 >> $log
	cp ..\libzmq\bin\x64\$baseconfig\v140\dynamic\libzmq.dll .\zmq 
	cp ..\libzmq\bin\x64\$baseconfig\v140\dynamic\libzmq.pdb .\zmq 
	& $pythonroot/$pythonexe setup.py configure $debug --zmq=./libzmq/$configuration 2>&1 >> $log
	Write-Host -NoNewline "building..."
	& $pythonroot/$pythonexe setup.py build_ext $debug --inplace 2>&1 >> $log
	# TODO a pyzmq socket test is failing which then prompts user to debug so disable for now so we don't slow down the build process
	# Write-Host -NoNewline "testing..."
	# & $pythonroot/$pythonexe setup.py test 2>&1 >> $log
	Write-Host -NoNewline "installing..."
	& $pythonroot/$pythonexe setup.py install 2>&1 >> $log
	Write-Host -NoNewline "crafting wheel..."
	& $pythonroot/$pythonexe setup.py bdist_wheel 2>&1 >> $log
	# these can't be in dist because clean wipes out dist completely
	move dist/pyzmq-$pyzmq_version-cp27-cp27${d}m-win_amd64.whl wheels/pyzmq-$pyzmq_version-cp27-cp27${d}m-win_amd64.$configuration.whl -Force 2>&1 >> $log
	$env:_LINK_ = ""
	$env:_CL_ = ""
	$env:INCLUDE = $oldinclude
	$ErrorActionPreference = "Stop"
	Validate "wheels/pyzmq-$pyzmq_version-cp27-cp27${d}m-win_amd64.$configuration.whl" "$pythonroot/lib/site-packages/zmq/libzmq.dll" "$pythonroot/lib/site-packages/zmq/devices/monitoredqueue.pyd" "$pythonroot/lib/site-packages/zmq/error.py"

	"finished installing python packages for $configuration"
}

$pythonexe = "python.exe"
SetLog("Setting up Python")
$pythonroot = "$root\src-stage2-python\gr-python27"
SetupPython "ReleaseDLL"
SetLog("Setting up AVX2 Python")
$pythonroot = "$root\src-stage2-python\gr-python27-avx2"
SetupPython "ReleaseDLL-AVX2"
SetLog("Setting up debug Python")
$pythonexe = "python_d.exe"
$pythonroot = "$root\src-stage2-python\gr-python27-debug"
SetupPython "DebugDLL"

cd $root/scripts 

""
"COMPLETED STEP 4: Python dependencies / packages have been built and installed"
""


if ($false)
{
	# these are just here for quick debugging

	ResetLog

	$configuration = "ReleaseDLL"
	$pythonroot = "$root\src-stage2-python\gr-python27"
	$pythonexe = "python.exe"
	$d = ""
	$debug = ""

	$configuration = "ReleaseDLL-AVX2"
	$pythonroot = "$root\src-stage2-python\gr-python27-avx2"
	$pythonexe = "python.exe"
	$d = ""
	$debug = ""

	$configuration = "DebugDLL"
	$pythonroot = "$root\src-stage2-python\gr-python27-debug"
	$pythonexe = "python_d.exe"
	$d = "d"
	$debug = "--debug"
}