GNURadio_Windows_Build_Scripts
==============================

A series of Powershell scripts to automatically download,  build from source, and install GNURadio and -all- it's dependencies as 64-bit native binaries then package as an .msi using Visual Studio 2015.

<strong>Note: </strong>*These scripts have not yet reached a "release" stage and will not work out of the box.  They are only of use for those looking for a reference on how to approach building a particular library.  Expect release sometime in April.*

For more details on this effort, please see the support [website](http://www.gcndevelopment.com/gnuradio)

<h2>INSTALLATION</h2>

Run the below from an **elevated** command prompt (the only command that requires elevation is the Set-ExecutionPolicy.  If desired, the rest can be run from a user-privilege account)

```powershell
git clone http://www.github.com/gnieboer/GNURadio_Windows_Build_Scripts
cd GNURadio_Windows_Build_Scripts
powershell 
Set-ExecutionPolicy Unrestricted
./~RUNME_FIRST.ps1
```

Build logs can be found in the $root/logs directory.  The scripts will validate keys of each step, but are not 100% guaranteed to detect a partial build failure.  Use the logs to further diagnose issues.

<h2>ISSUES</h2>

1- Ensure your anti-virus is off during installation... even Windows Defender.  PyQt4 may fail to create manifest files as a result.

2- Right-click your powershell window, go to "Properties" and ensure QuickEdit and Insert Mode are NOT checked.  Otherwise when you click on the window, execution may pause without any indication as to why, leading you to believe the build has hung.


