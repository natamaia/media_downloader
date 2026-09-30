# MediaDownloader Pro

**MediaDownloader Pro** é uma aplicação desktop para Windows (10 e 11) desenvolvida com interface gráfica nativa em C# WPF (.NET 10) e arquitetura de processamento assíncrono em Python (FastAPI + yt-dlp).

O sistema suporta a extração e o download de mídias a partir de múltiplos provedores (YouTube, YouTube Music, Spotify, Deezer, Instagram, TikTok, Vimeo, entre outros), com seleção automática de formato de saída (MP4 e MP3) e gerenciamento de arquivos em disco.

---

## 1. Arquitetura do Sistema

A aplicação adota o modelo cliente-servidor descentralizado em ambiente local:

```text
+-------------------------------------------------------------+
|                 Interface Gráfica (C# WPF)                  |
|  - Componentes XAML Reutilizáveis (Input, Preview, List)    |
|  - Gerenciamento de Temas (Claro / Escuro)                  |
|  - Auto-start Assíncrono via BackendManager.cs              |
|  - Animações Interativas e Suavização de Barra de Progresso |
+------------------------------+------------------------------+
                               |
                   HTTP / REST (http://127.0.0.1:8000)
                               |
+------------------------------v------------------------------+
|               API Interna Controller (FastAPI)              |
|  - Endpoints REST (/health, /api/v1/info, /api/v1/downloads)|
+------------------------------+------------------------------+
                               |
                     WorkerOrchestrator Pool
                               |
     +-------------------------+-------------------------+
     |                         |                         |
+----v----+               +----v----+               +----v----+
| Worker  |               | Worker  |               | Worker  |
| Inst. 1 |               | Inst. 2 |               | Inst. N |
+----+----+               +----+----+               +----+----+
     |                         |                         |
  (yt-dlp)                  (yt-dlp)                  (yt-dlp)
```

---

## 2. Recursos Principais

- **Seleção Automática de Formatos**: Músicas e áudios (Spotify, Deezer, YouTube Music) são direcionados para o formato **MP3**, salvos no diretório `%USERPROFILE%\Music\app_music\`. Vídeos são direcionados para o formato **MP4**, salvos em `%USERPROFILE%\Videos\app_videos\`.
- **Verificação de Arquivos Existentes**: Identifica previamente se o arquivo de mídia já se encontra no diretório de destino, informando o status **ARQUIVO EXISTENTE** sem duplicar o download ou gerar erros.
- **Remoção Segura de Mídia**: O botão de exclusão altera o status da tarefa para **DELETADO** e remove o arquivo do disco rígido.
- **Interface Responsiva**: Animações de entrada, scroll suavizado e progresso interpolado.

---

## 3. Ambientes de Execução e Desenvolvimento

### Pré-requisitos
- .NET 10.0 SDK (ou runtime compatível no Windows)
- Python 3.10 ou superior
- FFmpeg (opcional, para conversões avançadas)

### Instalação de Dependências do Backend
```powershell
pip install -r requirements.txt
```

### Execução em Modo de Desenvolvimento (Watch Mode)

- **Interface WPF (Hot Reload)**:
  ```powershell
  dotnet watch run --project src/frontend/MediaDownloaderUI/MediaDownloaderUI.csproj
  ```

- **Backend Controller (Auto Reload)**:
  ```powershell
  uvicorn src.backend.main:app --reload
  ```

---

## 4. Geração do Executável e Instalador

A compilação da aplicação e empacotamento no assistente de instalação (Inno Setup) é automatizada pelo script PowerShell:

```powershell
powershell -ExecutionPolicy Bypass -File .\build_installer.ps1
```

O instalador resultante será gerado em:
`installer\output\MediaDownloaderPro_Setup_v1.0.0.exe`

---

## 5. Estrutura do Projeto

```text
media_downloader/
├── installer/
│   ├── app_icon.ico                 # Ícone do assistente de instalação
│   ├── setup.iss                    # Script Inno Setup 6
│   └── output/                      # Executável de instalação compilado
├── src/
│   ├── backend/
│   │   ├── config.py                # Configurações do sistema
│   │   ├── extractor.py             # Serviços de extração e oEmbed
│   │   ├── main.py                  # API FastAPI e rotas REST
│   │   ├── models.py                # Modelos de dados Pydantic
│   │   ├── orchestrator.py          # Gerenciador da fila e pool de workers
│   │   └── worker.py                # Threads de download assíncrono (yt-dlp)
│   └── frontend/MediaDownloaderUI/
│       ├── Components/              # Componentes XAML reutilizáveis e controles suaves
│       ├── ApiClient.cs             # Cliente HTTP para comunicação interna
│       ├── BackendManager.cs        # Execução assíncrona do backend Python
│       ├── Models.cs                # Modelos de dados WPF e Notificação de Propriedades
│       ├── MainWindow.xaml          # Interface principal
│       └── MainWindow.xaml.cs
├── build_installer.ps1              # Script de automação do build e empacotamento
└── requirements.txt                 # Dependências Python
```
