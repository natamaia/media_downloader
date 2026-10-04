# 📱 Diretório de Saída do APK (build_apk)

Este diretório é o destino centralizado para onde o binário compilado do **MediaDownloader Android (.apk)** é copiado automaticamente após o build.

Ele foi projetado para que você possa simplesmente pegar o arquivo `.apk`, transferir para o seu smartphone Android e instalar diretamente, **sem necessidade de ativar o Modo Desenvolvedor ou a Depuração USB**.

---

## 📦 Arquivo Gerado

- **Nome padrão do binário**: `MediaDownloader.apk` (ou `MediaDownloader-release.apk`)
- **Arquitetura suportada**: Universal (`arm64-v8a`, `armeabi-v7a`, `x86_64`)
- **Compatibilidade**: Android 8.0 (Oreo / API 26) até Android 15 (API 35+)

---

## 📲 Como Instalar no Celular Sem Modo Desenvolvedor

Você **não precisa** ativar as Opções do Desenvolvedor nem conectar via cabo ADB. Siga estes passos simples:

### 1. Transferir o arquivo para o celular
Escolha o método mais prático:
- **Cabo USB**: Conecte o celular ao computador no modo "Transferência de Arquivos (MTP)" e cole o APK na pasta `Download`.
- **Nuvem / Mensageiros**: Envie o arquivo para si mesmo via Telegram, WhatsApp, Google Drive ou LocalSend e baixe no celular.

### 2. Executar o Instalador
1. Abra o gerenciador de arquivos do seu celular (ex: **Files do Google**, **Meus Arquivos** da Samsung, ou o gerenciador padrão da Motorola/Xiaomi).
2. Vá até a pasta **Downloads** e toque no arquivo `MediaDownloader.apk`.

### 3. Permitir Instalação de Fontes Desconhecidas (Apenas 1 vez)
1. O Android exibirá um aviso: *"Por segurança, seu smartphone não tem permissão para instalar apps desconhecidos desta fonte"*.
2. Toque no botão **Configurações**.
3. Ative a chave **"Permitir desta fonte"** (para o seu gerenciador de arquivos).
4. Volte e toque em **Instalar**.

### 4. Aviso do Google Play Protect (Se aparecer)
Como o app é assinado com certificado de desenvolvimento/privado (sideloading):
1. Caso apareça o aviso do Play Protect ("App não reconhecido"), toque em **"Mais detalhes"** (ou na seta para baixo).
2. Toque em **"Instalar assim mesmo"** (ou *"Install anyway"*).

Pronto! O aplicativo aparecerá na gaveta de aplicativos do seu celular e estará pronto para uso.
