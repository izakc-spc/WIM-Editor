$wc = [System.Net.WebClient]::new()
$URI = 'https://github.com/izakc-spc/WIM-Editor/raw/main/main.bat'
$LocalHash = Get-FileHash .\main.bat
$OnlineHash = Get-FileHash -InputStream ($wc.OpenRead($URI))
if ($LocalHash.Hash -eq $OnlineHash.Hash) {$OUT = 0; Write-Output $OUT} else {$OUT = 1; Write-Output $OUT}