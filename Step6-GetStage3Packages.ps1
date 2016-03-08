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

# gnuradio
SetLog "Retrieve GNURadio"
if (!(Test-Path $root/src-stage3-gnuradio/src)) {
		cd $root/src-stage3-gnuradio
		mkdir src
	} 
if (!(Test-Path $root/src-stage3-gnuradio/src/gnuradio)) {
	cd src
	git clone --recursive https://github.com/gnieboer/gnuradio.git 2>&1 >> $log 
} else {
	"gnuradio already present";
}