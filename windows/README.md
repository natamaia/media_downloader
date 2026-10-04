# 🪟 MediaDownloader Pro - Windows Desktop Edition

Esta pasta contém o aplicativo desktop para **Windows 10/11**, construído em **C# WPF (.NET 10)** com interface moderna, suporte a modo escuro/claro e integração automática com o motor analítico Python.

---

## 📂 Estrutura do Diretório `windows/`

*   `MediaDownloaderUI/`: Solução e código-fonte da aplicação desktop WPF (C# / XAML).
*   `installer/`: Script Inno Setup 6 (`setup.iss`) e recursos de ícone (`app_icon.ico`) para empacotamento do instalador executável.
*   `build_installer.ps1`: Script PowerShell de automação para compilar o backend, publicar o WPF e gerar o instalador final.
*   `MediaDownloaderBackend.spec`: Configuração do PyInstaller para empacotar o backend Python local.

---

## 🛠️ Requisitos de Compilação

*   **Windows 10 ou 11** (64-bit)
*   [.NET 10 SDK](https://dotnet.microsoft.com/download)
*   [Python 3.11+](https://www.python.org/)
*   [Inno Setup 6](https://jrsoftware.org/isdl.php) (opcional, para gerar o `.exe` instalador)

---

## 🚀 Como Executar em Desenvolvimento

Na raiz do repositório:

1. **Instale as dependências Python**:
   ```bash
   pip install -r requirements.txt
   ```

2. **Inicie a interface WPF**:
   ```bash
   dotnet run --project windows/MediaDownloaderUI/MediaDownloaderUI.csproj
   ```
   *(O `BackendManager.cs` iniciará o backend Python em segundo plano automaticamente)*.

---

## 📦 Como Gerar o Instalador de Produção

Execute o script PowerShell a partir do Windows Terminal:
```powershell
powershell -ExecutionPolicy Bypass -File windows/build_installer.ps1
```

O instalador será gerado em:
`windows\installer\output\MediaDownloaderPro_Setup_v1.0.0.exe`
