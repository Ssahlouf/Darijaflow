from transformers import pipeline
import torch
import librosa
from openai import OpenAI
from dotenv import load_dotenv
import os

load_dotenv()

client = OpenAI(api_key=os.getenv("OPENAI_API_KEY"))


class DarijaPipeline:
    def __init__(self):
        self.device = 0 if torch.cuda.is_available() else -1
        print("  Loading ASR model...")
        self.asr = pipeline(
            "automatic-speech-recognition",
            model="boumehdi/wav2vec2-large-xlsr-moroccan-darija",
            device=self.device,
            chunk_length_s=30,
            stride_length_s=5,
        )
        print("  ✅ ASR model ready!")
        print("  ✅ Translation via GPT-4o-mini ready!")


    def detect_language(self, text):
        arabic_chars = sum(1 for c in text if "\u0600" <= c <= "\u06FF")
        total_chars = len(text.replace(" ", ""))
        if total_chars == 0:
            return "darija"
        return "darija" if (arabic_chars / total_chars) > 0.3 else "other"

    def translate(self, text, target_lang="auto"):
        if target_lang == "auto":
            detected = self.detect_language(text)
            target = "English" if detected == "darija" else "Moroccan Darija (Arabic script)"
            output_lang = "english" if detected == "darija" else "darija"
        else:
            target = target_lang
            output_lang = target_lang.lower()

        prompt = f"Translate the following text to {target}. Return only the translation, nothing else.\n\n{text}"

        response = client.chat.completions.create(
            model="gpt-4o-mini",
            messages=[
                {"role": "system", "content": "You are an expert translator specializing in Moroccan Darija and multiple languages. Translate accurately while preserving natural tone and colloquial expressions."},
                {"role": "user", "content": prompt}
            ],
            max_tokens=512,
            temperature=0.3,
        )

        output = response.choices[0].message.content.strip()
        return {
            "input": text,
            "input_lang": "auto",
            "output": output,
            "output_lang": output_lang,
        }

    def transcribe(self, audio_path):
        audio, _ = librosa.load(audio_path, sr=16000, mono=True)
        result = self.asr({"raw": audio, "sampling_rate": 16000})
        return result["text"].strip()

    def run(self, audio_path, target_lang="auto"):
        darija = self.transcribe(audio_path)
        return self.translate(darija, target_lang)