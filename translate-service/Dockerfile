FROM python:3.11-slim

WORKDIR /app

# Install system deps for torch + sentencepiece
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY main.py .

# Pre-download the model so the container is self-contained (no internet needed at runtime)
RUN python -c "\
from transformers import MarianMTModel, MarianTokenizer; \
MarianTokenizer.from_pretrained('Helsinki-NLP/opus-mt-pt-en'); \
MarianMTModel.from_pretrained('Helsinki-NLP/opus-mt-pt-en'); \
print('Model downloaded.')"

EXPOSE 8000
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
