# Build Installer Automation Script for MediaDownloader Pro

Write-Host "1/4. Compilando o Backend Python via PyInstaller..." -ForegroundColor Cyan
pyinstaller --noconfirm --onedir --console --name "MediaDownloaderBackend" src/backend/main.py

Write-Host "2/4. Publicando o Frontend C# WPF (.NET 10 Release)..." -ForegroundColor Cyan
dotnet publish src/frontend/MediaDownloaderUI/MediaDownloaderUI.csproj -c Release -r win-x64 --self-contained true

Write-Host "3/4. Empacotando Backend junto com Frontend..." -ForegroundColor Cyan
Copy-Item -Path "dist\MediaDownloaderBackend" -Destination "src\frontend\MediaDownloaderUI\bin\Release\net10.0-windows\win-x64\publish\backend" -Recurse -Force

Write-Host "4/4. Gerando o Instalador Executável Wizard (Inno Setup)..." -ForegroundColor Cyan
$isccPath = "$env:LOCALAPPDATA\Programs\Inno Setup 6\ISCC.exe"
if (Test-Path $isccPath) {
    & $isccPath installer/setup.iss
} else {
    & "C:\Program Files (x86)\Inno Setup 6\ISCC.exe" installer/setup.iss
}

Write-Host "✅ Instalador gerado com sucesso em: installer\output\MediaDownloaderPro_Setup_v1.0.0.exe" -ForegroundColor Green
