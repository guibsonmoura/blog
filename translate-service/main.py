from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from transformers import MarianMTModel, MarianTokenizer
import logging
import re

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

MODEL_NAME = "Helsinki-NLP/opus-mt-ROMANCE-en"

logger.info(f"Loading model {MODEL_NAME}...")
tokenizer = MarianTokenizer.from_pretrained(MODEL_NAME)
model = MarianMTModel.from_pretrained(MODEL_NAME)
logger.info("Model loaded.")

app = FastAPI(title="Opus-MT PT→EN", version="1.0.0")


class TranslateRequest(BaseModel):
    text: str


class TranslateResponse(BaseModel):
    translation: str


# Pure structural elements — pass through without translating.
PASSTHROUGH = re.compile(r"^(---+|===+|\*\*\*+|```[\s\S]*```|#{1,6}\s*$)$")

# Heading line: capture prefix (# ## ###) and text separately so the
# model translates only the text and we restore the prefix afterwards.
# Without this the model may output "- ### heading" (list + heading).
HEADING = re.compile(r"^(#{1,6})\s+(.+)$")


def run_model(text: str) -> str:
    prefixed = f">>en<< {text}"
    inputs = tokenizer([prefixed], return_tensors="pt", padding=True, truncation=True, max_length=512)
    outputs = model.generate(**inputs, num_beams=4, max_length=512)
    return tokenizer.decode(outputs[0], skip_special_tokens=True)


def translate_text(text: str) -> str:
    """Translate text, splitting on double-newlines to handle long inputs."""
    segments = [s.strip() for s in text.split("\n\n") if s.strip()]
    translated_segments = []

    for segment in segments:
        # Pass structural markdown through unchanged
        if PASSTHROUGH.match(segment):
            translated_segments.append(segment)
            continue

        # Headings: translate only the label, restore the # prefix.
        # Strip leading "- " artifact the model sometimes prepends.
        heading_match = HEADING.match(segment)
        if heading_match:
            prefix = heading_match.group(1)
            label = heading_match.group(2)
            translated_label = run_model(label).lstrip("- ").strip()
            translated_segments.append(f"{prefix} {translated_label}")
            continue

        translated_segments.append(run_model(segment))

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
