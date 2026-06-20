$PSVersionTable.PSVersion.ToString() | Out-File -FilePath versionps.tmp -Encoding ascii
Get-Content -Path versionps.tmp 
$env:PSModulePath.Split(';')
