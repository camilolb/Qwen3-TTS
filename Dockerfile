FROM ghcr.io/jamiepine/voicebox:latest

# Instalar git (necesario para clonar el repo)
RUN apt-get update && apt-get install -y git && rm -rf /var/lib/apt/lists/*

# Crear directorios para modelos
RUN mkdir -p /app/models

# Tu fork con cambios para forzar 0.6B
RUN git clone https://github.com/camilolb/Qwen3-TTS.git /opt/Qwen3-TTS
ENV PYTHONPATH=/opt/Qwen3-TTS

# Configurar variables de entorno para modelos (sin offline mode aún)
ENV HF_HOME=/app/models
ENV HF_HUB_CACHE=/app/models
ENV XDG_CACHE_HOME=/app/models

# Configuración forzada para modelo 0.6B
ENV QWEN_TTS_MODEL=0.6B
ENV DEVICE=cpu
ENV CUDA_VISIBLE_DEVICES=""

# Optimizaciones críticas de rendimiento para CPU
ENV OMP_NUM_THREADS=8
ENV MKL_NUM_THREADS=8
ENV NUMEXPR_NUM_THREADS=8
ENV TORCH_NUM_THREADS=8
ENV OPENBLAS_NUM_THREADS=8
ENV PYTORCH_MPS_HIGH_WATERMARK_RATIO=0.0
ENV PYTORCH_CUDA_ALLOC_CONF=max_split_size_mb:512
ENV TOKENIZERS_PARALLELISM=false
ENV PYTHONUNBUFFERED=1
ENV PYTHONOPTIMIZE=1

# Pre-descargar modelos durante la construcción (CRÍTICO para modo offline y rendimiento)
RUN python3 -c "import os; os.environ['HF_HOME'] = '/app/models'; os.environ['HF_HUB_CACHE'] = '/app/models'; from huggingface_hub import snapshot_download; \
    print('Descargando modelos...'); \
    snapshot_download('Qwen/Qwen3-TTS-12Hz-0.6B-Base'); \
    snapshot_download('openai/whisper-base'); \
    print('Modelos descargados exitosamente!')"

# Ahora sí habilitar modo offline después de descargar el modelo
ENV TRANSFORMERS_OFFLINE=1
ENV HF_HUB_OFFLINE=1

# Verificar que el modelo esté descargado
RUN ls -la /app/models/ && echo 'Verificación completa'
