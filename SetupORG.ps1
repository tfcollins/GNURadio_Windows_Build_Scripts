# GNURadio Windows Build System
# Geof Nieboer
#

function getPackage
{
	[CmdletBinding()]
	Param(
		[Parameter(Mandatory=$True,Position=1)]
		[string]$toGet,
	
		[Parameter(Mandatory=$False, Position=2)]
		[string]$newname = "",

		[Parameter(Mandatory=$False)]
		[switch]$Stage3,

		[Parameter(Mandatory=$False)]
		[switch]$AddFolderName,

		[Parameter(Mandatory=$False)]
		[string]$branch = ""
	)
	$archiveName = [io.path]::GetFileNameWithoutExtension($toGet)
	$archiveExt = [io.path]::GetExtension($toGet)
	$isTar = [io.path]::GetExtension($archiveName)
	if ($Stage3) {$destdir = "src-stage3\oot_code"} else {$destdir = "src-stage1-dependencies"}
	Write-Host -NoNewline "$archiveName..."
	if ($isTar -eq ".tar") {
		$archiveExt = $isTar + $archiveExt
		$archiveName = [io.path]::GetFileNameWithoutExtension($archiveName)  
	}
	if ($archiveExt -eq ".git" -or $toGet.StartsWith("git://")) {
		# the source is a git repo, so make a shallow clone
		# no need to store anything in the packages dir
		if (((Test-Path "$root\$destdir\$archiveName") -and ($newname -eq "")) -or
			(($newname -ne "") -and (Test-Path $root\$destdir\$newname))) {
			"previously shallowed cloned"
		} else {
			cd $root\$destdir	
			if (Test-Path $root\$destdir\$archiveName) {
				Remove-Item  $root\$destdir\$archiveName -Force -Recurse
			}
			$ErrorActionPreference = "Continue"
			if ($branch -eq "") {
				git clone --recursive --depth=1 $toGet  2>&1 >> $Log 
			} else {
				git clone --recursive --depth=1 $toGet --branch $branch  2>&1 >> $Log 
			}
			$ErrorActionPreference = "Stop"
			if ($LastErrorCode -eq 1) {
				Write-Host -BackgroundColor Red -ForegroundColor White "git clone FAILED"
			} else {
				"shallow cloned"
			}
			if ($newname -ne "") {
				if (Test-Path $root\$destdir\$newname) {
					Remove-Item  $root\$destdir\$newname -Force -Recurse
				}
				if (Test-Path $root\$destdir\$archiveName) {
					ren $root\$destdir\$archiveName $root\$destdir\$newname
				}
			}
		}
	} else {
		# source is a compressed package
		# store it in the packages dir so we can reuse it if we
		# clean the whole install
		if (!(Test-Path $root/packages/$archiveName)) {
			mkdir $root/packages/$archiveName >> $Log
		}
		if (!(Test-Path $root/packages/$archiveName/$archiveName$archiveExt)) {
			cd $root/packages/$archiveName
			# user-agent is for sourceforge downloads
            $count = 0
            do {
                Try 
			    {
				    wget $toGet -OutFile "$archiveName$archiveExt" -UserAgent [Microsoft.PowerShell.Commands.PSUserAgent]::FireFox
                    $count = 999
			    }
			    Catch [System.IO.IOException]
			    {
				    Write-Host -NoNewline "failed, retrying..."
				    $count ++
			    }
            } while ($count -lt 5)
            if ($count -ne 999) {
                Write-Host ""
                Write-Host -BackgroundColor Black -ForegroundColor Red "Error Downloading File, retries exceeded, aborting..."
                Exit
            }
		} else {
			Write-Host -NoNewLine "already downloaded..."
		}
		# extract the package if the final destination directory doesn't exist
		if (!((Test-Path $root\$destdir\$archiveName) -or ($newname -ne "" -and (Test-Path $root\$destdir\$newName)))) {
			$archive = "$root/packages/$archiveName/$archiveName$archiveExt"
			if ($AddFolderName) {
				New-Item -Force -ItemType Directory $root/$destdir/$archiveName >> $Log
				cd "$root\$destdir\$archiveName" >> $Log
			} else {
				cd "$root\$destdir"
			}
			if ($archiveExt -eq ".7z" -or ($archiveExt -eq ".zip")) {
				sz x -y $archive 2>&1 >> $Log
			} elseif ($archiveExt -eq ".zip") {
				$destination = "$root/$destdir"
				[io.compression.zipfile]::ExtractToDirectory($archive, $destination) >> $Log
			} elseif ($archiveExt -eq ".tar.xz" -or $archiveExt -eq ".tgz" -or $archiveExt -eq ".tar.gz" -or $archiveExt -eq ".tar.bz2") {
				sz x -y $archive >> $Log
				if (!(Test-Path $root\$destdir\$archiveName.tar)) {
					# some python .tar.gz files put the tar in a dist subfolder
					cd dist
					sz x -aoa -ttar -o"$root\$destdir" "$archiveName.tar" >> $Log
					cd ..
					rm -Recurse -Force dist >> $Log
				} else {
					sz x -aoa -ttar -o"$root\$destdir" "$archiveName.tar" >> $Log
					del "$archiveName.tar" -Force
					}
			} else {
				throw "Unknown file extension on $archiveName$archiveExt"
			}
			if ($newname -ne "") {
				if (Test-Path $root\$destdir\$newname) {
					Remove-Item  $root\$destdir\$newname -Force -Recurse >> $Log
					}
				if (Test-Path $root\$destdir\$archiveName) {
					if ($AddFolderName) {
						cd $root\$destdir
						}
					ren $root\$destdir\$archiveName $root\$destdir\$newname
					}
			}
			"extracted"
		} else {
			"previously extracted"
		}
	}
}

# Patches are overlaid on top of the main source for gnuradio-specific adjustments
function getPatch
{	[CmdletBinding()]
	Param(
		[Parameter(Mandatory=$True,Position=1)]
		[string]$toGet,
	
		[Parameter(Mandatory=$True, Position=2)]
		[string]$whereToPlace = "",

		[Parameter(Mandatory=$False)]
		[switch]$Stage3,
		
		[Parameter(Mandatory=$False)]
		[switch]$gnuradio 
	)
	if ($Stage3) {$IntDir = "src-stage3/oot_code"} 
	elseif ($gnuradio) {$IntDir = "src-stage3/src"}
	else {$IntDir = "src-stage1-dependencies"}
	$archiveName = [io.path]::GetFileNameWithoutExtension($toGet)
	$archiveExt = [io.path]::GetExtension($toGet)
	$isTar = [io.path]::GetExtension($archiveName)
	
	Write-Host -NoNewline "patch $archiveName..."

	if ($isTar -eq ".tar") {
		$archiveExt = $isTar + $archiveExt
		$archiveName = [io.path]::GetFileNameWithoutExtension($archiveName)  
	}
	$url = "http://www.gcndevelopment.com/gnuradio/downloads/sources/" + $toGet 
	if (!(Test-Path $root/packages/patches)) {
		mkdir $root/packages/patches
	}
	cd $root/packages/patches
	if (!(Test-Path $root/packages/patches/$toGet)) {
		Write-Host -NoNewline "retrieving..."
		wget $url -OutFile $toGet >> $Log 
		Write-Host -NoNewline "retrieved..."
	} else {
		Write-Host -NoNewline "previously retrieved..."
	}
	
	$archive = "$root/packages/patches/$toGet"
	$destination = "$root/$IntDir/$whereToPlace"
	if ($archiveExt -eq ".7z" -or $archiveExt -eq ".zip") {
		New-Item -path $destination -type directory -force >> $Log
		cd $destination 
		sz x -y $archive 2>&1 >> $Log
	} elseif ($archiveExt -eq ".tar.gz") {
		New-Item -path $destination -type directory -force >> $Log
		cd $destination 
		tar zxf $archive 2>&1 >> $Log
	} elseif ($archiveExt -eq ".tar.xz") {
		New-Item -path $destination -type directory -force >> $Log
		cd $destination 
		sz x -y $archive 2>&1 >> $Log
		sz x -aoa -ttar "$archiveName.tar" 2>&1 >> $Log
		del "$archiveName.tar"
	} elseif ($archiveExt -eq ".diff") {
		New-Item -path $destination -type directory -force >> $Log
		cd $destination 
		Copy-Item $archive $destination -Force >> $Log 
		git apply --verbose --whitespace=fix $toGet >> $Log 
	} else {
		throw "Unknown file extension on $archiveName$archiveExt"
	}

	"extracted"
}

function Exec
{
    [CmdletBinding()]
    param (
        [Parameter(Position=0, Mandatory=1)]
        [scriptblock]$Command,
        [Parameter(Position=1, Mandatory=0)]
        [string]$ErrorMessage = "Execution of command failed.`n$Command"
    )
    & $Command
    if ($LastExitCode -ne 0) {
        throw "Exec: $ErrorMessage"
    }
}

function SetLog ($name)
{
	if ($Global:LogNumber -eq $null) {$Global:LogNumber = 1}
	$LogNumStr = $Global:LogNumber.ToString("00")
	$Global:Log = "$root\logs\$LogNumStr-$name.txt"
	"" > $Log 
	$Global:LogNumber ++
}

function ResetLog 
{
	$Global:LogNumber = 1
	del $root/logs/*.*
}

function GetMajorMinor($versionstring)
{
	$version = [Version]$versionstring
	$result = '{0}.{1}' -f $version.major,$version.minor
	return $result
}

# Used to check each build step to see if the critical files have been built as an indicator of success
# We need this because powershell doesn't seem to handle exit codes well, particular when they are nested in calls, so it's hard to tell if a build call succeeded.
function TryValidate
{
	$retval = $true
	foreach ($i in $args)
	{
		if (!(Test-Path $i)) {
			$retval = $false 
		}
	}
	return $retval 
}

function Validate
{
	foreach ($i in $args)
	{
		if (!(Test-Path $i)) {
			cd $root/scripts
			Write-Host ""
			Write-Host -BackgroundColor Black -ForegroundColor Red "Validation Failed, $i was not found and is required"
			throw ""  2>&1 >> $null
		}
	}
	"validated complete"
}

function CheckNoAVX
{
	if ($configuration -match "AVX") {return}

	$thisroot = $args[0]
	if ($thisroot.Length.Equals(0)) {
		$thisroot=$PWD
	}
	cd $thisroot 
	$avxfound = $false
	$dirs = $thisroot 
	$Include=@("*.lib","*.pyd","*.dll", "*.exe")

	$libs = $dirs | Get-ChildItem -Recurse -File -Include "$Include"
	foreach ($lib in $libs) {
		$result = & dumpbin $lib.FullName /DISASM:nobytes /NOLOGO | select-string -pattern "ymm[0-9]"
		if ($result.length -gt 0) {
			if ($AVX_Whitelist -notcontains $lib.Name ) {
				Write-Host -BackgroundColor Black -ForegroundColor Red $lib.FullName + ": AVX FOUND <-----------------------------" 
				$avxfound = $true
			}
		}
	}
	if ($avxfound -eq $true) {throw ""  2>&1 >> $null}
}

#load configuration variables
$mypath =  Split-Path $script:MyInvocation.MyCommand.Path
$Config = Import-LocalizedData -BaseDirectory $mypath -FileName ConfigInfo.psd1 
$gnuradio_version = $Config.VersionInfo.gnuradio
$png_version = $Config.VersionInfo.libpng
$sdl_version = $Config.VersionInfo.SDL
$cppunit_version = $Config.VersionInfo.cppunit
$openssl_version = $Config.VersionInfo.openssl
$qwt_version = $Config.VersionInfo.qwt
$qwt6_version = $Config.VersionInfo.qwt6
$sip_version = $Config.VersionInfo.sip
$PyQt_version = $Config.VersionInfo.PyQt
$cython_version = $Config.VersionInfo.Cython
$numpy_version = $Config.VersionInfo.numpy
$scipy_version = $Config.VersionInfo.scipy
$pyopengl_version = $Config.VersionInfo.pyopengl
$fftw_version = $Config.VersionInfo.fftw
$libusb_version = $Config.VersionInfo.libusb
$cheetah_version = $Config.VersionInfo.cheetah 
$wxpython_version = $Config.VersionInfo.wxpython
$py2cairo_version = $Config.VersionInfo.py2cairo
$pygobject_version = $Config.VersionInfo.pygobject 
$pygtk_version = $Config.VersionInfo.pygtk
$pygtk_gitversion = $Config.VersionInfo.pygtk_git
$gsl_version = $Config.VersionInfo.gsl
$boost_version = $Config.VersionInfo.boost 
$boost_version_ = $Config.VersionInfo.boost_ 
$pthreads_version = $Config.VersionInfo.pthreads
$lapack_version = $Config.VersionInfo.lapack
$openBLAS_version = $Config.VersionInfo.OpenBLAS 
$UHD_version = $Config.VersionInfo.UHD
$pyzmq_version = $Config.VersionInfo.pyzmq
$lxml_version = $Config.VersionInfo.lxml
$pkgconfig_version = $Config.VersionInfo.pkgconfig 
$dp_version = $Config.VersionInfo.dp
$log4cpp_version = $Config.VersionInfo.log4cpp
$gqrx_version = $Config.VersionInfo.gqrx
$volk_version = $Config.VersionInfo.volk 
$libxslt_version = $Config.VersionInfo.libxslt
$matplotlib_version = $Config.VersionInfo.matplotlib
$PIL_version = $Config.VersionInfo.PIL
$bitarray_version = $Config.VersionInfo.bitarray
$mbedtls_version = $Config.VersionInfo.mbedtls
$openlte_version = $Config.VersionInfo.openlte

# The below libraries will have AVX code detected, even for non-AVX builds
# these libraries all have guards to ensure the feature is supported 
# whether in the code itself or because the intel fortran compiler added them
# or it's a known false alarm
$AVX_Whitelist = @(
	"boost_log-vc140-mt-1_60.dll",  # specifically built with guards (dump.cpp)
	"Qt5Gui.dll",                   # specifically built with guards
	"Qt5Multimedia.dll",            # specifically built with guards
	"volk.dll",                     # specifically built with guards
	"sqlite3.dll",
	"sqlite3_d.dll",
	"wininst-14.0-amd64.exe",
	"wininst-9.0-amd64.exe",
	"gnuradio-specest-fortran.dll", # intel fortran compiler
	"gnuradio-specest.dll"          # includes openblas_static which uses intel fortran compiler
	"ssleay32.lib",                 # openssl built with guards
	"_hashlib.pyd",                 # includes openssl
	"_ssl.pyd",                     # includes openssl
	"_hashlib_d.pyd",               # includes openssl 
	"_ssl_d.pyd",                   # includes openssl
	
	"_vq.pyd",                      # scipy begin
	"lsoda.pyd",
	"vode.pyd",
	"_odepack.pyd",
	"_test_odeint_banded.pyd",
	"_ppoly.pyd",
	"cython_blas.pyd",
	"cython_lapack.pyd",
	"_fblas.pyd",
	"_flapack.pyd",
	"_flinalg.pyd",
	"_interpolative.pyd",
	"__odrpack.pyd",
	"_lbfgsb.pyd",
	"_sparsetools.pyd",
	"_arpack.pyd",
	"_iterative.pyd",
	"qhull.pyd",
	"_distance_wrap.pyd",
	"specfun.pyd",
	"_ellip_harm_2.pyd",
	"_ufuncs.pyd",
	"_funcs_cxx.pyd"                # scipy end
)

# setup paths
if (!$Global:root) {$Global:root = Split-Path (Split-Path -Parent $script:MyInvocation.MyCommand.Path)}

# ensure on a 64-bit machine
if ($env:PROCESSOR_ARCHITECTURE -ne "AMD64") {throw "It appears you are using 32-bit windows.  This build requires 64-bit windows"} 
$myprog = "${Env:ProgramFiles(x86)}"

# Check for binary dependencies

# check for git/tar
if (-not (test-path "$env:ProgramFiles\Git\usr\bin\tar.exe")) {throw "Git For Windows must be installed.  Aborting script"} 
set-alias tar "$env:ProgramFiles\Git\usr\bin\tar.exe"  

# CMake (to build gnuradio)
if (-not (test-path "${env:ProgramFiles(x86)}\Cmake\bin\cmake.exe")) {throw "CMake must be installed.  Aborting script"} 
Set-Alias cmake "${env:ProgramFiles(x86)}\Cmake\bin\cmake.exe"
	
# ActivePerl (to build OpenSSL)
if ((Get-Command "perl.exe" -ErrorAction SilentlyContinue) -eq $null)  {throw "ActiveState Perl must be installed.  Aborting script"} 
	
# MSVC 2015
if (-not (test-path "${env:ProgramFiles(x86)}\Microsoft Visual Studio 14.0\VC")) {throw "Visual Studio 2015 must be installed.  Aborting script"} 

# WIX
if (-not (test-path $env:WIX)) {throw "WIX toolset must be installed.  Aborting script"}

# doxygen
if (-not (test-path "$env:ProgramFiles\doxygen")) {throw "Doxygen must be installed.  Aborting script"} 
	
# set VS 2015 environment
if (!(Test-Path variable:global:oldpath))
{
	pushd "${env:ProgramFiles(x86)}\Microsoft Visual Studio 14.0\VC"
	cmd /c "vcvarsall.bat amd64&set" |
	foreach {
		if ($_ -match "=") {
			$v = $_.split("="); set-item -force -path "ENV:\$($v[0])"  -value "$($v[1])"
		}
	}
	popd
	write-host "Visual Studio 2015 Command Prompt variables set." -ForegroundColor Yellow
	# set Intel Fortran environment (if exists)... will detect 2016/2017 compilers only 
	if (Test-Path env:IFORT_COMPILER17) {
		& $env:IFORT_COMPILER17\bin\ifortvars.bat -arch intel64 -platform vs2015 
		$Global:MY_IFORT = $env:IFORT_COMPILER17
		$Global:hasIFORT = $true
	} else {
		if (Test-Path env:IFORT_COMPILER16) {
			& $env:IFORT_COMPILER16\bin\ifortvars.bat -arch intel64 -platform vs2015 
			$Global:MY_IFORT = $env:IFORT_COMPILER16
			$Global:hasIFORT = $true
		} else {
			$Global:hasIFORT = $false
		}
	}
	# Now set a persistent variable holding the original path. vcvarsall will continue to add to the path until it explodes
	Set-Variable -Name oldpath -Value "$env:Path" -Description "original %Path%" -Option readonly -Scope "Global"
}
if (!(Test-Path variable:global:oldlib)) {Set-Variable -Name oldlib -Value "$env:Lib" -Description "original %LIB%" -Option readonly -Scope "Global"}
if (!(Test-Path variable:global:oldcl)) {Set-Variable -Name oldcl -Value "$env:CL" -Description "original %CL%" -Option readonly -Scope "Global"}
if (!(Test-Path variable:global:oldlink)) {Set-Variable -Name oldlink -Value "$env:LINK" -Description "original %CL%" -Option readonly -Scope "Global"}
if (!(Test-Path variable:global:oldinclude)) {Set-Variable -Name oldinclude -Value "$env:INCLUDE" -Description "original %INCLUDE%" -Option readonly -Scope "Global"}
if (!(Test-Path variable:global:oldlibrary)) {Set-Variable -Name oldlibrary -Value "$env:LIBRARY" -Description "original %LIBRARY%" -Option readonly -Scope "Global"}

# import .NET modules
Add-Type -assembly "system.io.compression.filesystem"

# set initial state
set-alias sz "$root\bin\7za.exe"  
cd $root




