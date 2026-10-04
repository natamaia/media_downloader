# 🚀 Guia de Compilação do APK e Instalação no Celular (Sem Modo Desenvolvedor)

Este guia fornece o passo a passo completo para compilar o binário **APK** do **MediaDownloader Mobile**, gerar o arquivo na pasta dedicada `build_apk/` e instalá-lo diretamente no seu smartphone Android sem precisar ativar o Modo Desenvolvedor ou usar comandos ADB via terminal.

---

## 1. Pré-requisitos de Compilação (No Computador)

O seu ambiente de desenvolvimento já possui todas as ferramentas necessárias configuradas:
- **Flutter SDK**: Versão 3.x (canal stable)
- **Java Development Kit**: JDK 17
- **Android SDK**: Plataforma API 34+ e Build Tools
- **Python**: 3.10+ com suporte a ambientes virtuais

---

## 2. Comandos de Compilação do APK

### 2.1. Compilação Rápida Automatizada
Criamos um comando automatizado que compila o aplicativo e move o binário final diretamente para a pasta `build_apk/`:

```bash
# Executar a compilação do APK de Release
make apk
```

### 2.2. Compilação Manual via CLI do Flutter
Se preferir executar os passos do Flutter manualmente:

```bash
# 1. Entrar no diretório do projeto mobile
cd mobile_app

# 2. Obter as dependências do Flutter
flutter pub get

# 3. Compilar o APK Release universal (otimizado para todos os processadores)
flutter build apk --release

# 4. Copiar o APK gerado para a pasta de saída na raiz do projeto
cp build/app/outputs/flutter-apk/app-release.apk ../build_apk/MediaDownloader.apk
```

---

## 3. Onde Encontrar o Arquivo Compilado

Ao final do processo de build, o arquivo estará disponível em:
```text
media_downloader/
└── build_apk/
    ├── README.md               # Instruções rápidas de instalação
    └── MediaDownloader.apk     # Binário pronto para instalação no smartphone
```

---

## 4. Como Instalar no Smartphone (Passo a Passo Visual)

Você **não precisa** ativar a Depuração USB, nem as "Opções do Desenvolvedor" do Android.

### Passo 1: Transferir o arquivo para o celular
Escolha uma das opções abaixo:
1. **Cabo USB (Mais rápido)**:
   - Conecte o celular ao computador via cabo USB.
   - No celular, selecione o modo **"Transferência de Arquivos" (MTP)**.
   - Abra a pasta do celular no seu computador, vá até a pasta `Downloads` e cole o arquivo `MediaDownloader.apk`.
2. **Sem Fio (LocalSend, Telegram ou WhatsApp)**:
   - Envie o arquivo `MediaDownloader.apk` para si mesmo (ex: no chat "Mensagens Salvas" do Telegram ou WhatsApp).
   - No celular, toque para baixar o arquivo.

### Passo 2: Executar o Instalador
1. Abra o aplicativo gerenciador de arquivos do seu celular (ex: **Files do Google**, **Meus Arquivos** da Samsung, **Arquivos** da Motorola/Xiaomi).
2. Navegue até a pasta **Downloads**.
3. Toque no arquivo `MediaDownloader.apk`.

### Passo 3: Autorizar Fontes Desconhecidas (Sideloading)
1. O Android exibirá uma mensagem de proteção:
   > *"Por segurança, seu smartphone não tem permissão para instalar apps desconhecidos desta fonte."*
2. Toque no botão **Configurações**.
3. Ative a chave **"Permitir desta fonte"** (isso autoriza apenas o seu gerenciador de arquivos a abrir o instalador).
4. Pressione o botão Voltar e toque em **Instalar**.

### Passo 4: Aviso do Google Play Protect
Como o aplicativo foi compilado diretamente no seu computador e assinado com uma chave local privada (sem passar pela loja Google Play Store):
1. A tela do Google Play Protect pode exibir: *"App bloqueado pelo Play Protect"* ou *"Desenvolvedor desconhecido"*.
2. Toque no link **"Mais detalhes"** (ou na pequena seta para baixo).
3. Toque no botão **"Instalar assim mesmo"** (*Install anyway*).

---

## 5. Resolução de Dúvidas e Problemas Frequentes (FAQ)

### P: O celular mostra a mensagem "O pacote parece estar corrompido" ou "Erro de análise"?
- **Causa**: O arquivo APK não terminou de ser copiado completamente para a memória do celular antes de você tocar nele.
- **Solução**: Aguarde a transferência USB ou o download no mensageiro terminar 100% e tente novamente.

### P: O download de um vídeo longo pausa quando a tela do celular apaga?
- **Causa**: O gerenciador de bateria do Android (especialmente em aparelhos Xiaomi/MIUI, Samsung e Huawei) suspendeu o aplicativo.
- **Solução**: Vá em *Configurações do Celular > Aplicativos > MediaDownloader > Bateria* e selecione a opção **"Sem restrições"** ou **"Não otimizar"**.

### P: Onde os vídeos e músicas baixados são salvos no celular?
- As músicas são salvas na pasta pública de **Músicas** (`/Music/MediaDownloader/`).
- Os vídeos são salvos na pasta pública de **Filmes** ou **Downloads** (`/Movies/MediaDownloader/` ou `/Download/MediaDownloader/`).
- Todos aparecem instantaneamente na sua galeria de fotos e reprodutores de mídia padrão do aparelho.
