# 🐍 Integração do Motor Python no Android APK (Chaquopy & JNI)

Este documento especifica a estratégia e a arquitetura técnica para empacotar o motor Python (`yt-dlp` e orquestração) diretamente dentro do binário **Android APK**, operando de forma 100% autônoma, offline (sem depender de servidores remotos) e integrada ao **Flutter** via canais de plataforma nativos.

---

## 1. Por que Chaquopy?

Para rodar código Python com dependências complexas (como `yt-dlp`, manipulação de sockets, SSL e processamento de streams) nativamente dentro de um processo Android, o **Chaquopy** (`com.chaquo.python`) é a solução padrão da indústria:
- **CPython Nativo**: Executa CPython real (versão 3.10 ou 3.11) compilado para a arquitetura nativa do processador do smartphone (`arm64-v8a` e `armeabi-v7a`).
- **Gerenciador de Pacotes Pip Integrado ao Gradle**: Permite declarar dependências Python (`yt-dlp`, `certifi`, etc.) diretamente no arquivo `build.gradle` do Android, empacotando-as durante a geração do APK.
- **Interoperabilidade Total (JNI bidirecional)**: Chamadas entre Kotlin/Java e Python ocorrem no mesmo processo em memória, sem a latência ou o overhead de conexões de rede HTTP locais.
- **Tamanho Otimizado**: Carrega apenas as bibliotecas estáticas estritamente necessárias para a arquitetura do dispositivo.

---

## 2. Configuração do Gradle no Android

### 2.1. `android/build.gradle` (Nível do Projeto)
```groovy
buildscript {
    repositories {
        google()
        mavenCentral()
        maven { url "https://chaquo.com/maven" }
    }
    dependencies {
        classpath "com.android.tools.build:gradle:8.2.1"
        classpath "org.jetbrains.kotlin:kotlin-gradle-plugin:1.9.22"
        classpath "com.chaquo.python:gradle:15.0.1" // Plugin Chaquopy
    }
}
```

### 2.2. `android/app/build.gradle` (Nível do Módulo)
```groovy
plugins {
    id "com.android.application"
    id "kotlin-android"
    id "dev.flutter.flutter-gradle-plugin"
    id "com.chaquo.python"
}

android {
    namespace "com.example.media_downloader"
    compileSdk 34

    defaultConfig {
        applicationId "com.example.media_downloader"
        minSdk 24
        targetSdk 34
        versionCode 1
        versionName "1.0.0"

        ndk {
            // Suporte completo a aparelhos modernos de 64 bits e legado 32 bits
            abiFilters "arm64-v8a", "armeabi-v7a", "x86_64"
        }

        python {
            version "3.11"
            pip {
                install "yt-dlp>=2024.08.06"
                install "certifi>=2024.2.2"
                install "mutagen>=1.47.0"
            }
        }
    }
    
    sourceSets {
        main {
            python.srcDir "../../src/backend"
        }
    }
}
```

---

## 3. Módulo de Ponte Python (`src/backend/mobile_bridge.py`)

Para permitir a chamada direta e enxuta do Kotlin sem a sobrecarga do servidor web FastAPI/Uvicorn, o backend disponibiliza um módulo de ponte que expõe funções simplificadas retornando JSON:

```python
"""
mobile_bridge.py
Interface direta em memória entre a camada nativa Android (Kotlin) e o motor yt-dlp.
"""
import json
import logging
from typing import Callable, Optional
from src.backend.extractor import ExtractorService
from src.backend.worker import DownloadWorker
from src.backend.models import FormatType, WorkerStatus

logger = logging.getLogger("MobileBridge")

def extract_metadata_json(url: str) -> str:
    """Extrai informações e formatos suportados do link fornecido."""
    try:
        info = ExtractorService.extract_info(url)
        return json.dumps({
            "success": True,
            "data": info.model_dump()
        })
    except Exception as e:
        logger.error(f"Erro na extração: {e}")
        return json.dumps({
            "success": False,
            "error": str(e)
        })

class MobileDownloadManager:
    def __init__(self):
        self.workers = {}

    def start_download(self, url: str, format_str: str, quality: str, output_dir: str, callback_proxy) -> str:
        """Inicia worker em thread e reporta progresso ao proxy Kotlin."""
        fmt = FormatType.MP3 if format_str.lower() == "mp3" else FormatType.MP4
        
        def on_update(worker: DownloadWorker):
            payload = json.dumps({
                "download_id": worker.download_id,
                "status": worker.status.value,
                "progress_percent": worker.progress_percent,
                "download_speed": worker.download_speed,
                "eta_seconds": worker.eta_seconds,
                "downloaded_bytes": worker.downloaded_bytes,
                "total_bytes": worker.total_bytes,
                "file_path": worker.file_path,
                "error_message": worker.error_message
            })
            if callback_proxy:
                callback_proxy.onProgressUpdate(payload)

        worker = DownloadWorker(
            url=url,
            format_type=fmt,
            quality=quality,
            output_dir=output_dir,
            on_update_callback=on_update
        )
        self.workers[worker.download_id] = worker
        worker.start_async()
        return worker.download_id

    def cancel_download(self, download_id: str) -> bool:
        worker = self.workers.get(download_id)
        if worker:
            worker.cancel()
            return True
        return False

# Instância global gerenciada pelo processo
manager = MobileDownloadManager()
```

---

## 4. Ponte Nativa Android (`MainActivity.kt`)

No lado Android nativo, a classe Kotlin conecta os canais do Flutter ao motor Python através da API do Chaquopy:

```kotlin
package com.example.media_downloader

import android.os.Bundle
import com.chaquo.python.Python
import com.chaquo.python.android.AndroidPlatform
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.EventChannel

class MainActivity: FlutterActivity() {
    private val ENGINE_CHANNEL = "com.mediadownloader/engine"
    private val PROGRESS_CHANNEL = "com.mediadownloader/progress"
    private var progressEventSink: EventChannel.EventSink? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Inicializa o ambiente CPython via Chaquopy
        if (!Python.isStarted()) {
            Python.start(AndroidPlatform(this))
        }
        val py = Python.getInstance()
        val bridgeModule = py.getModule("mobile_bridge")

        // Canal de Eventos (Streaming de Progresso em Tempo Real)
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, PROGRESS_CHANNEL)
            .setStreamHandler(object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    progressEventSink = events
                }
                override fun onCancel(arguments: Any?) {
                    progressEventSink = null
                }
            })

        // Canal de Métodos (Comandos: Extrair, Baixar, Cancelar)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, ENGINE_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "extractMetadata" -> {
                        val url = call.argument<String>("url") ?: ""
                        Thread {
                            val resJson = bridgeModule.callAttr("extract_metadata_json", url).toString()
                            runOnUiThread { result.success(resJson) }
                        }.start()
                    }
                    "startDownload" -> {
                        val url = call.argument<String>("url") ?: ""
                        val format = call.argument<String>("format") ?: "mp4"
                        val quality = call.argument<String>("quality") ?: "720p"
                        val outputDir = call.argument<String>("outputDir") ?: filesDir.absolutePath

                        val proxy = object {
                            fun onProgressUpdate(jsonPayload: String) {
                                runOnUiThread { progressEventSink?.success(jsonPayload) }
                            }
                        }

                        val dlId = bridgeModule.get("manager")
                            .callAttr("start_download", url, format, quality, outputDir, proxy)
                            .toString()
                        result.success(dlId)
                    }
                    "cancelDownload" -> {
                        val dlId = call.argument<String>("downloadId") ?: ""
                        val success = bridgeModule.get("manager")
                            .callAttr("cancel_download", dlId)
                            .toBoolean()
                        result.success(success)
                    }
                    else -> result.notImplemented()
                }
            }
    }
}
```

---

## 5. Vantagens desta Abordagem

1. **Sem Necessidade de Servidor Local Aberto**: Não é necessário abrir portas TCP (como `127.0.0.1:8000`) nem executar um servidor HTTP uvicorn em background, o que reduz o consumo de memória RAM e de bateria no smartphone.
2. **Execução em Thread Segura**: As chamadas de extração e downloads ocorrem em threads dedicadas fora da UI Thread do Android, garantindo que o app permaneça sempre responsivo.
3. **Compatibilidade Multiplataforma**: O código base do `src/backend` (`extractor.py`, `worker.py`, `models.py`) é preservado integralmente, compartilhando a mesma inteligência de extração.
