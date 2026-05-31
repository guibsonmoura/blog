FROM python:3.11-slim

WORKDIR /app

# curl needed for healthcheck
RUN apt-get update && apt-get install -y --no-install-recommends curl \
    && rm -rf /var/lib/apt/lists/*

# Install CPU-only torch first (avoids downloading 2+ GB of CUDA libraries)
RUN pip install --no-cache-dir torch==2.7.0 --index-url https://download.pytorch.org/whl/cpu

COPY requirements.txt .
# Install remaining deps (torch already installed above, pip skips it)
RUN pip install --no-cache-dir -r requirements.txt

COPY main.py .

# Pre-download the model so the container is self-contained (no internet at runtime)
RUN python -c "\
from transformers import MarianMTModel, MarianTokenizer; \
MarianTokenizer.from_pretrained('Helsinki-NLP/opus-mt-ROMANCE-en'); \
MarianMTModel.from_pretrained('Helsinki-NLP/opus-mt-ROMANCE-en'); \
print('Model downloaded.')"

EXPOSE 8000
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
  CMD curl -f http://localhost:8000/health || exit 1
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
