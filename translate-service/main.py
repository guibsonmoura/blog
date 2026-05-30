from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from transformers import MarianMTModel, MarianTokenizer
import logging

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

MODEL_NAME = "Helsinki-NLP/opus-mt-pt-en"

logger.info(f"Loading model {MODEL_NAME}...")
tokenizer = MarianTokenizer.from_pretrained(MODEL_NAME)
model = MarianMTModel.from_pretrained(MODEL_NAME)
logger.info("Model loaded.")

app = FastAPI(title="Opus-MT PT→EN", version="1.0.0")


class TranslateRequest(BaseModel):
    text: str


class TranslateResponse(BaseModel):
    translation: str


def translate_text(text: str) -> str:
    """Translate text, splitting on double-newlines to handle long inputs."""
    segments = [s.strip() for s in text.split("\n\n") if s.strip()]
    translated_segments = []

    for segment in segments:
        inputs = tokenizer([segment], return_tensors="pt", padding=True, truncation=True, max_length=512)
        outputs = model.generate(**inputs, num_beams=4, max_length=512)
        translated = tokenizer.decode(outputs[0], skip_special_tokens=True)
        translated_segments.append(translated)

    return "\n\n".join(translated_segments)


@app.post("/translate", response_model=TranslateResponse)
def translate(req: TranslateRequest):
    if not req.text.strip():
        raise HTTPException(status_code=422, detail="text must not be blank")
    translation = translate_text(req.text)
    return TranslateResponse(translation=translation)


@app.get("/health")
def health():
    return {"status": "ok"}
