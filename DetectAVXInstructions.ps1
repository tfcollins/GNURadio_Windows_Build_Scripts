$root = $args[0]
if ($root.Length.Equals(0)) {
    $root=$PWD
}
cd $root 

$dirs = Get-ChildItem $root -Directory #-Recurse "Release" | Where-Object {$_.FullName -inotmatch "avx"}
$dlls = $dirs | Get-ChildItem -Recurse -File -Filter *.dll 
$dllfound = 0
foreach ($dll in $dlls) {
    $result = & dumpbin $dll.FullName /DISASM:nobytes /NOLOGO | select-string -pattern "ymm[0-9]"
    if ($result.length -gt 0) {
        $dll.FullName + ": AVX FOUND <-----------------------------" 
        $dllfound++
    } else {
        $dll.FullName + ": AVX NOT FOUND" 
    }
}

$pyds = $dirs | Get-ChildItem -Recurse -File -Filter *.pyd 
$pydfound = 0
foreach ($pyd in $pyds) {
    $result = & dumpbin $pyd.FullName /DISASM:nobytes /NOLOGO | select-string -pattern "ymm[0-9]"
    if ($result.length -gt 0) {
        $pyd.FullName + ": AVX FOUND <-----------------------------" 
        $pydfound++
    } else {
        $pyd.FullName + ": AVX NOT FOUND" 
    }
}

$exes = $dirs | Get-ChildItem -Recurse -File -Filter *.exe
$exefound = 0
foreach ($exe in $exes) {
    $result = & dumpbin $exe.FullName /DISASM:nobytes /NOLOGO | select-string -pattern "ymm[0-9]"
    if ($result.length -gt 0) {
        $exe.FullName + ":  AVX FOUND <-----------------------------"
        $exefound++
    } else {
        $exe.FullName + ":  AVX NOT FOUND"
    }
}

$libs = $dirs | Get-ChildItem -Recurse -File -Filter *.lib 
$libfound = 0
foreach ($lib in $libs) {
    $result = & dumpbin $lib.FullName /DISASM:nobytes /NOLOGO | select-string -pattern "ymm[0-9]"
    if ($result.length -gt 0) {
        $lib.FullName + ":  AVX FOUND <-----------------------------"
        $libfound++
    } else {
        $lib.FullName + ":  AVX NOT FOUND"
    }
}

"Found $dllfound DLLs, $pydfound PYDs, $libfound libs, and $exefound exes with AVX registers out of $($dlls.count) DLLs, $(pyds.count) PYDs, $($libs.count) libs, and $($exes.count) exes scanned"