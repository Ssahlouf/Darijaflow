from fastapi import FastAPI, UploadFile, File, Form
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
import tempfile, os
from pipeline import DarijaPipeline

app = FastAPI(title="Darija Translator API")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

pipe = DarijaPipeline()

# ── Schemas ────────────────────────────────────────────────
class TextRequest(BaseModel):
    text: str
    target_lang: str = "auto"

class TranslationResponse(BaseModel):
    input: str
    input_lang: str
    output: str
    output_lang: str

# ── Health check ──────────────────────────────────────────────
@app.get("/")
def root():
    return {"status": "ok", "message": "Darija Translator API is running"}

# ── Text → auto detect + translate ───────────────────────────
@app.post("/translate/text", response_model=TranslationResponse)
def translate_text(req: TextRequest):
    return pipe.translate(req.text, req.target_lang)

# ── Audio → transcribe → translate ───────────────────────────
@app.post("/translate/audio", response_model=TranslationResponse)
async def translate_audio(file: UploadFile = File(...)):
    suffix = os.path.splitext(file.filename)[-1] or ".wav"
    with tempfile.NamedTemporaryFile(suffix=suffix, delete=False) as tmp:
        tmp.write(await file.read())
        tmp_path = tmp.name
    try:
        return pipe.run(tmp_path)
    finally:
        os.unlink(tmp_path)


@app.post("/translate/image", response_model=TranslationResponse)
async def translate_image(
    file: UploadFile = File(...),  # Fixed: was File(...) - this was a typo
    target_lang: str = Form(default="English")
):
    image_bytes = await file.read()
    return pipe.translate_image(image_bytes, target_lang)
