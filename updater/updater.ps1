$uri = 'https://github.com/izakc-spc/WIM-Editor/raw/main/main.bat'
$theHashIHave = Get-FileHash main.bat -Algorithm SHA256

try {
    $content = Invoke-RestMethod $uri
    $memstream = [System.IO.MemoryStream]::new($content.ToCharArray())
    $thisFileHash = Get-FileHash -InputStream $memstream -Algorithm SHA256
    if($theHashIhave.Hash -eq $thisFileHash.Hash) {
        "0"
    }
    else {
        "1"
    }
}
finally {
    $memstream.foreach('Dispose')
}