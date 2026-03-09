FROM ghcr.io/jamiepine/voicebox:latest

# Instalar tini para estabilidad de procesos
RUN apt-get update && apt-get install -y git tini && rm -rf /var/lib/apt/lists/*

# Crear directorios para modelos
RUN mkdir -p /app/models

# Usar el código proporcionado por Easypanel (contexto de construcción)
WORKDIR /opt/Qwen3-TTS
COPY . .

# Instalar dependencias del backend
RUN pip install --no-cache-dir -r backend/requirements.txt
# Asegurar que qwen-tts esté instalado desde el repo oficial
RUN pip install --no-cache-dir git+https://github.com/QwenLM/Qwen3-TTS.git

# Variables de entorno Core
ENV PYTHONPATH=/opt/Qwen3-TTS
ENV DEVICE=cpu
ENV CUDA_VISIBLE_DEVICES=""
ENV HF_HOME=/app/models

# Optimización para tus 5 núcleos
ENV OMP_NUM_THREADS=5
ENV MKL_NUM_THREADS=5
ENV TORCH_NUM_THREADS=5
ENV OPENBLAS_NUM_THREADS=5
ENV PYTHONUNBUFFERED=1
ENV PYTHONOPTIMIZE=1

# Pre-descarga del modelo (para que el arranque sea inmediato)
RUN python3 -c "from huggingface_hub import snapshot_download; \
    print('Pre-descargando modelo...'); \
    snapshot_download('Qwen/Qwen3-TTS-12Hz-0.6B-Base', cache_dir='/app/models')"

# Configuración de inicio para Zero Downtime y estabilidad de RAM
ENTRYPOINT ["/usr/bin/tini", "--"]
CMD ["uvicorn", "backend.main:app", "--host", "0.0.0.0", "--port", "8000", "--workers", "1"]
