GNURadio_Windows_Build_Scripts
==============================

A series of Powershell scripts to automatically download,  build from source, and install GNURadio and -all- it's dependencies as 64-bit native binaries then package as an .msi using Visual Studio 2015.

<strong>Note: </strong>*These scripts have not yet reached a "release" stage and will not work out of the box.  They are only of use for those looking for a reference on how to approach building a particular library.  Expect release sometime in April.*

For more details on this effort, please see the support [website](http://www.gcndevelopment.com/gnuradio)

The finished MSI includes:

Device Support: UHD, RTL-SDR, hackrf, airspy, BladeRF, osmoSDR, FCD
GNURadio modules: 3.7.9 with all but gr-comedi modules built and included
OOT modules: gq-iqbal, gr-osmosdr

<h2>PREREQUISITES</h2>

The following tools must be installed:  
- MS Visual Studio 2015 (Community or higher)  
- Git For Windows  
- CMake  
- Doxygen  
- ActiveState Perl  
- Wix toolset for VS 2015  

Also, the complete build requires no less than **35 GB** of free disk space.

<h2>INSTALLATION & BUILD</h2>

Run the below from an **elevated** command prompt (the only command that requires elevation is the Set-ExecutionPolicy.  If desired, the rest can be run from a user-privilege account)

```powershell
git clone http://www.github.com/gnieboer/GNURadio_Windows_Build_Scripts
cd GNURadio_Windows_Build_Scripts
powershell 
Set-ExecutionPolicy Unrestricted
./~RUNME_FIRST.ps1
```

Build logs can be found in the $root/logs directory.  The scripts will validate key parts of each step, but are not 100% guaranteed to detect a partial build failure.  Use the logs to further diagnose issues.

<h2>ISSUES</h2>

1- Ensure your anti-virus is off during installation... even Windows Defender.  PyQt4 may fail to create manifest files as a result.

2- Right-click your powershell window, go to "Properties" and ensure QuickEdit and Insert Mode are NOT checked.  Otherwise when you click on the window, execution may pause without any indication as to why, leading you to believe the build has hung.

3- This has been tested on a B200 UHD and an RTL-SDR.  Other device drivers have not been phyiscally verified to work.  If you own one, please let me know if you had success.

4- In the event of issues, I highly recommend [Dependency Walker](https://www.dependencywalker.com/) to troubleshoot what libraries are linked to what.