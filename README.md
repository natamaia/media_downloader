# ⚡ MediaDownloader Pro

**MediaDownloader Pro** é uma aplicação desktop nativa para Windows 10 e 11, projetada com uma **arquitetura descentralizada de workers** e interface gráfica moderna estilo *Tailwind Slate* com **arquitetura de componentes reutilizáveis**.

Permite baixar vídeos e áudios a partir de links de múltiplos hospedadores (YouTube, YouTube Music, Spotify, Deezer, Instagram, SoundCloud, TikTok, Vimeo, entre outros), com seleção automática de formato (MP4 / MP3) e salvamento em diretórios nativos.

---

## 🏗️ Arquitetura do Sistema

```
+-------------------------------------------------------------+
|                C# WPF UI (Windows 10/11 Native)             |
|  - Componentes XAML Reutilizáveis (Header, Input, Preview)  |
|  - Troca Automática de Formato por Tipo (MP3/MP4)           |
|  - Auto-start Não-Bloqueante via BackendManager.cs          |
|  - Polling em Tempo Real de Workers e Progresso             |
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

O aplicativo altera automaticamente o formato selecionado (MP3 ou MP4) de acordo com o provedor identificado:
- **Áudios/Músicas (Spotify, Deezer, YT Music)**: Seleção automática de **MP3** -> Salvos em `%USERPROFILE%\Music\app_music\`
- **Vídeos (YouTube, Instagram)**: Seleção de **MP4** -> Salvos em `%USERPROFILE%\Videos\app_videos\`

---

## 🛠️ Comandos para Rodar e Desenvolver

> ⚠️ **Aviso de Navegação**: Se você já estiver dentro do diretório `src/frontend/MediaDownloaderUI`, execute os comandos do .NET diretamente sem repetir o `cd`.

### 1. Instalação das Dependências do Backend
```powershell
pip install -r requirements.txt
```

### 2. Modo Desenvolvimento com Hot-Reload (dotnet watch run)
Monitora alterações no código XAML/C# e recompila automaticamente:
```powershell
# Certifique-se de estar na pasta src/frontend/MediaDownloaderUI
dotnet watch run
```

### 3. Modo Execução Direta (Release / Executável)
```powershell
dotnet run
```

---

## 📁 Estrutura de Componentes da UI

```
src/frontend/MediaDownloaderUI/
├── Components/
│   ├── HeaderBarControl.xaml        # Componente de cabeçalho e status da API
│   ├── UrlInputControl.xaml         # Componente de input, seleção e auto-troca de formato
│   └── MediaPreviewControl.xaml     # Componente de pré-visualização de metadados
├── ApiClient.cs                     # Cliente HTTP para a API interna
├── BackendManager.cs                # Gerenciador assíncrono do backend Python
├── Models.cs                        # Modelos de dados C#
├── MainWindow.xaml                  # Janela principal que orquestra os componentes
└── MainWindow.xaml.cs
```
