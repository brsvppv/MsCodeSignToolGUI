$signToolLocaion = "C:\Program Files (x86)\Windows Kits\10\bin\10.0.19041.0\x64"
$FileToSign = ""
$PfxCertificate = ""
$PfxPassword = (Read-host Password:)

Set-Location "$signToolLocaion"

./signtool.exe sign /t http://timestamp.digicert.com /f "$PfxCertificate" /p $PfxPassword "$FileToSign"