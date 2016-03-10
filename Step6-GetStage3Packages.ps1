#
# Step6_GetStage3Packages.ps1
#
# GNURadio Windows Build System
# Geof Nieboer

# script setup
$ErrorActionPreference = "Stop"

# setup helper functions
$mypath =  Split-Path $script:MyInvocation.MyCommand.Path
. $mypath\Setup.ps1 -Force

GetPackage git://git.osmocom.org/gr-osmosdr -Stage3
GetPackage git://git.osmocom.org/osmo-sdr -Stage3

# gnuradio
SetLog "Retrieve GNURadio"
if (!(Test-Path $root/src-stage3/src)) {
		cd $root/src-stage3
		mkdir src
	} 
if (!(Test-Path $root/src-stage3/src/gnuradio)) {
	cd src
	git clone --recursive https://github.com/gnieboer/gnuradio.git 2>&1 >> $log 
} else {
	"gnuradio already present";
}

