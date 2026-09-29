# ⚡ MediaDownloader Pro

**MediaDownloader Pro** é uma aplicação desktop nativa para Windows 10 e 11, projetada com uma **arquitetura descentralizada de workers** e interface gráfica moderna estilo *Tailwind Slate*. 

Permite baixar vídeos e áudios a partir de links de múltiplos hospedadores (YouTube, YouTube Music, Spotify, Deezer, Instagram, SoundCloud, TikTok, Vimeo, entre outros), com seleção de formato (MP4 / MP3) e qualidade personalizada.

---

## 🏗️ Arquitetura do Sistema

```
+-------------------------------------------------------------+
|                C# WPF UI (Windows 10/11 Native)             |
|  - Auto-start do Backend via BackendManager.cs              |
|  - Interface Gráfica Estilo Tailwind Slate                  |
|  - Polling em tempo real de progresso e estatísticas        |
+------------------------------+------------------------------+
                               |
                   HTTP / REST (http://127.0.0.1:8000)
                               |
+------------------------------v------------------------------+
|             Internal Controller API (FastAPI)               |
|  - Endpoints /health, /api/v1/info, /api/v1/downloads       |
+------------------------------+------------------------------+
                               |
                   WorkerOrchestrator Pool
                               |
     +-------------------------+-------------------------+
     |                         |                         |
+----v----+               +----v----+               +----v----+
| Worker  |               | Worker  |               | Worker  |
| Contr. 1|               | Contr. 2|               | Contr. N|
+----+----+               +----+----+               +----+----+
     |                         |                         |
 (yt-dlp)                  (yt-dlp)                  (yt-dlp)
```

---

## 📂 Diretórios de Destino Automáticos

O aplicativo direciona os arquivos baixados diretamente para os diretórios nativos da conta do usuário no Windows:
- **Áudios/Músicas (MP3)**: `%USERPROFILE%\Music\app_music\` (`C:\Users\<Usuario>\Music\app_music\`)
- **Vídeos (MP4)**: `%USERPROFILE%\Videos\app_videos\` (`C:\Users\<Usuario>\Videos\app_videos\`)

---

## 🛠️ Requisitos do Sistema

- **Windows 10** ou **Windows 11**
- **Python 3.12+** (para o motor de workers)
- **.NET 10 SDK** (ou .NET 8+ runtime para execução da UI WPF)

---

## 🚀 Todos os Comandos para Rodar o Projeto

### 1. Instalação das Dependências do Backend
Abra o terminal PowerShell no diretório do projeto e execute:
```powershell
pip install -r requirements.txt
```

---

### 2. Modos de Execução da Aplicação

#### Mode A: Execução Integrada (Recomendado - 1 Clique)
Basta iniciar a interface WPF. Ela verificará e subirá automaticamente a API do backend Python em segundo plano:
```powershell
cd src/frontend/MediaDownloaderUI
dotnet run
```

#### Modo B: Execução Manual (Backend + Frontend Separados)
Se preferir rodar a API do backend manualmente para depuração:

**Terminal 1 (Backend API Controller)**:
```powershell
python -m src.backend.main
```

**Terminal 2 (Frontend WPF UI)**:
```powershell
cd src/frontend/MediaDownloaderUI
dotnet run
```

#### Modo C: Desenvolvimento Containerizado (Docker)
```powershell
docker-compose up --build
```

---

## 🧪 Comandos para Testes e Validação

### Testes Unitários do Backend (pytest)
```powershell
python -m pytest tests/
```

### Compilação da Interface WPF (.NET)
```powershell
cd src/frontend/MediaDownloaderUI
dotnet build
```

---

## 📁 Estrutura do Código Fonte

```
media_downloader/
├── .env.example                  # Template de variáveis de ambiente
├── .gitignore                    # Regras de exclusão do Git
├── Dockerfile                    # Containerização do Backend
├── docker-compose.yml            # Orquestração para desenvolvimento Docker
├── requirements.txt              # Dependências Python (FastAPI, yt-dlp, pytest)
├── docs/                         # Documentação técnica do projeto
│   ├── ARCHITECTURE.md           # Detalhes da arquitetura descentralizada
│   ├── API_SPEC.md               # Especificação dos endpoints REST
│   └── GETTING_STARTED.md        # Guia rápido para desenvolvedores
├── tests/                        # Suíte de testes unitários automatizados
│   └── test_backend.py
└── src/
    ├── backend/                  # Motor de Workers & API Controller (Python)
    │   ├── config.py             # Gerenciador de configurações e caminhos
    │   ├── models.py             # Modelos de dados Pydantic
    │   ├── extractor.py          # Extrator e resolvedor de links multiplataforma
    │   ├── worker.py             # Executor individual de downloads (yt-dlp)
    │   ├── orchestrator.py       # Orquestrador concorrente de workers
    │   └── main.py               # API REST FastAPI (http://127.0.0.1:8000)
    └── frontend/
        └── MediaDownloaderUI/    # Interface Gráfica C# WPF (.NET)
            ├── ApiClient.cs      # Cliente HTTP para a API interna
            ├── BackendManager.cs # Gerenciador do ciclo de vida do backend Python
            ├── Models.cs         # Modelos de dados em C#
            ├── MainWindow.xaml   # Layout XAML estilo Tailwind Slate
            └── MainWindow.xaml.cs# Lógica e interatividade da interface
```
