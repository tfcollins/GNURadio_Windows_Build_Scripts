# GNURadio Windows Build System
# Geof Nieboer
#
Write-Host "Welcome to GNURadio windows build and installation script."
Write-Host ""
Write-Host "This script can build GNURadio and every dependency needed using Visual Studio 2015"
Write-Host "to ensure version and binary compatibility."
Write-Host ""
Write-Host "This build script also includes a number of OOT packages in the final installer"
Write-Host "This version currently builds and includes:"
Write-Host "- UHD drivers"
Write-Host "- airspy drivers"
Write-Host "- bladeRF drivers"
Write-Host "- RTL-SDR drivers"
Write-Host "- HackRF drivers"
Write-Host "- gr-osmocomsdr"
Write-Host "- gr-imbalance"
Write-Host "- gr-benchmark"
Write-Host ""
Write-Host "The only GNURadio component not currently built is gr-comedi."
Write-Host ""
Write-Host "Dependencies (VS 2015, git, perl, cmake, 7-zip) are installed."
if ($hasIFORT) 
{
    Write-Host "Intel Fortran compiler has been detected.  Numpy/Scipy will be built from source"
} else {
    Write-Host "Intel Fortran compiler not installed.  Numpy/Scipy will be installed from wheels"
}
Write-Host ""
Write-Host "You must be connected to the internet to run this script."
Write-Host "Downloaded packages will be cached in the packages subdir."
Write-Host ""
Write-Host "This script can build GNURadio in three different ways:"
Write-Host "1- Compile every dependency from source right now [LONGEST]"
Write-Host "2- For non-python dependencies, download a pre-built package, then build the rest"
Write-Host "3- Download all dependencies, including custom python, and build GNURadio"
Write-Host ""

$buildoption = Read-Host "Please choose an option (1,2,3)<3>"
if (!$buildoption) {$buildoption = "3"}
if ($buildoption -ne "1" -and $buildoption -ne "2" -and $buildoption -ne "3") 
{
    Write-Host "'$buildoption' was not a valid choice.  Exiting script."
    return
}

Write-Host ""
$defaultroot = Split-Path (Split-Path -Parent $script:MyInvocation.MyCommand.Path)
$Global:root = Read-Host "Please choose an absolute root directory for this build <$defaultroot>"
if (!$root) {$root = $defaultroot}
if (!(Test-Path -isValid -LiteralPath $root)) {
    Write-Host "'$root' is not a valid path.  Exiting script."
    return
}
if (![System.IO.Path]::IsPathRooted($root)) {
    Write-Host "'$root' is not an absolute path.  Exiting script."
    return
}
Write-Host ""
Write-Host "By default, GNURadio uses only open source libraries.  However, if you have Intel MKL installed"
Write-Host "the script can find it and use it to build numpy and scipy, which are significantly faster than"
Write-Host "the MSVC version of OpenBLAS.  However, the resulting products CANNOT be distributed as it"
Write-Host "would violate the GPL."
Write-Host ""
$useMKLstr = Read-Host "Use MKL libraries if available? <N>"
if ($useMKLstr -match "y") {$Global:BuildNumpyWithMKL = $true} else {$Global:BuildNumpyWithMKL = $false}

Write-Host ""
Write-Host "This script can build 3 different configurations of GNURadio:"
Write-Host "1- Release"
Write-Host "2- Release, optimized for AVX2 cpu's only.  Fastest, but will crash on non-AVX2 processors!"
Write-Host "3- Debug"
Write-Host "Or, the script can build all three versions so all the dependencies are available to you."
Write-Host ""
$Global:configmode = Read-Host "What configuration do you want to build? (1,2,3,all)<1>"
if (!$configmode) {$configmode = "1"}
if (($configmode -ne "1" -and $configmode -ne "2" -and $configmode -ne "3" -and $configmode -ne "all")) {
    Write-Host "That was not a valid choice.  Exiting script"
    return
}

if ($buildoption -eq "1") {$numberof = 4}
if ($buildoption -eq "2") {$numberof = 1}
if ($buildoption -eq "3") {$numberof = .5}
if ($configmode -eq "all") {$numberof = $numberof * 3}

Write-Host ""
Write-Host "Thank you.  Package download is first, then compilation and build will begin."
Write-Host "Building will take about $numberof hours on a Intel X5930 machine"
Write-Host "After downloads are complete.  Logs can be found in $root/Logs in the build fails."
Write-Host ""

# RUN

if ($buildoption -eq "1") 
{
	& .\Step2-GetStage1Packages.ps1
	& .\Step3-BuildStage1Packages.ps1 $configmode
} 
if ($buildoption -eq "1" -or $buildoption -eq "2")
{
	& .\Step4-BuildPythonPackages.ps1 $configmode
	& .\Step5-ConsolidateLibs.ps1 $configmode
} 
& .\Step6-GetStage3Packages.ps1
& .\Step7-BuildGNURadio.ps1 $configmode
& .\Step8-BuildOOTModules.ps1 $configmode
& .\Step9-BuildMSI.ps1 $configmode 