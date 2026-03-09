FROM ghcr.io/jamiepine/voicebox:latest

# Crear directorios para modelos
RUN mkdir -p /app/models

# Tu fork con cambios para forzar 0.6B
RUN git clone https://github.com/camilolb/Qwen3-TTS.git /opt/Qwen3-TTS
ENV PYTHONPATH=/opt/Qwen3-TTS

# Configurar variables de entorno para modelos y offline mode
ENV HF_HOME=/app/models
ENV HF_HUB_CACHE=/app/models
ENV XDG_CACHE_HOME=/app/models
ENV TRANSFORMERS_OFFLINE=1
ENV HF_HUB_OFFLINE=1

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

# Pre-descargar el modelo 0.6B durante la construcción (CRÍTICO)
RUN python3 -c "import os; os.environ['HF_HOME'] = '/app/models'; os.environ['HF_HUB_CACHE'] = '/app/models'; from huggingface_hub import snapshot_download; print('Descargando modelo Qwen3-TTS 0.6B...'); snapshot_download('Qwen/Qwen3-TTS-12Hz-0.6B-Base'); print('Modelo 0.6B descargado exitosamente!')"

# Verificar que el modelo esté descargado
RUN ls -la /app/models/ && echo 'Verificación completa'
