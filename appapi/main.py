from fastapi import FastAPI, File, UploadFile
from fastapi.middleware.cors import CORSMiddleware
import tempfile
import os

app = FastAPI()

# Allow Flutter (mobile) to communicate
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # for testing; later restrict to your device IP
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.get("/")
def home():
    return {"message": "Voice assistant backend running!"}

@app.post("/transcribe")
async def transcribe_audio(file: UploadFile = File(...)):
    # Save uploaded file temporarily
    with tempfile.NamedTemporaryFile(delete=False, suffix=".wav") as tmp:
        tmp.write(await file.read())
        tmp_path = tmp.name

    # Here you would normally call Whisper or another ASR model
    # For testing, let's fake the transcription
    fake_transcript = "Hello, this is a sample transcription."

    # Delete the temp file after use
    os.remove(tmp_path)

    return {"transcribed_text": fake_transcript}
