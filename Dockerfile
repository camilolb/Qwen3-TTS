FROM ghcr.io/jamiepine/voicebox:latest

USER root

# Instalar dependencias del sistema
RUN apt-get update && apt-get install -y \
    git \
    curl \
    sox \
    libsox-fmt-all \
    python3-dev \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Provider PyTorch CPU
RUN mkdir -p /root/.local/share/voicebox/providers
RUN curl -L https://github.com/jamiepine/voicebox/releases/latest/download/tts-provider-pytorch-cpu-linux.tar.gz \
    -o /root/.local/share/voicebox/providers/tts-provider-pytorch-cpu-linux.tar.gz

# Instalar Qwen3-TTS original
RUN pip install --no-cache-dir git+https://github.com/QwenLM/Qwen3-TTS.git

# Tu fork (asegúrate de que tenga los cambios para forzar 0.6B)
RUN git clone https://github.com/camilolb/Qwen3-TTS.git /opt/Qwen3-TTS
ENV PYTHONPATH=/opt/Qwen3-TTS

# Crear directorios para modelos
RUN mkdir -p /app/models

# Configurar variables de entorno para modelos
ENV MODELS_DIR=/app/models
ENV HF_HOME=/app/models
ENV HF_HUB_CACHE=/app/models
ENV XDG_CACHE_HOME=/app/models

# Configuración de dispositivo y modelo
ENV DEVICE=cpu
ENV CUDA_VISIBLE_DEVICES=""
ENV TTS_MODE=local
ENV QWEN_TTS_MODEL=0.6B

# Optimizaciones críticas de rendimiento para CPU
ENV OMP_NUM_THREADS=8
ENV MKL_NUM_THREADS=8
ENV NUMEXPR_NUM_THREADS=8
ENV TORCH_NUM_THREADS=8
ENV OPENBLAS_NUM_THREADS=8

# Optimizaciones adicionales de PyTorch
ENV PYTORCH_MPS_HIGH_WATERMARK_RATIO=0.0
ENV PYTORCH_CUDA_ALLOC_CONF=max_split_size_mb:512

# Pre-descargar el modelo 0.6B durante la construcción
RUN python3 -c "import os; os.environ['HF_HOME'] = '/app/models'; os.environ['HF_HUB_CACHE'] = '/app/models'; from huggingface_hub import snapshot_download; print('Descargando modelo Qwen3-TTS 0.6B...'); snapshot_download('Qwen/Qwen3-TTS-12Hz-0.6B-Base'); print('Modelo descargado exitosamente!')"

# Ahora sí habilitar modo offline después de descargar el modelo
ENV TRANSFORMERS_OFFLINE=1
ENV HF_HUB_OFFLINE=1

# Deshabilitar paralelismo de tokenizers y otras optimizaciones
ENV TOKENIZERS_PARALLELISM=false
ENV PYTHONUNBUFFERED=1
ENV PYTHONOPTIMIZE=1

# Verificar que el modelo esté descargado
RUN ls -la /app/models/ && echo 'Verificación completa'
