# Darijaflow

A Moroccan Darija translator with a FastAPI backend and a Flutter Android app.

- **Backend:** Python + FastAPI — speech-to-text (wav2vec2) + translation (GPT-4o-mini)
- **Frontend:** Flutter Android app with Firebase auth

---

## Prerequisites
- Python 3.10+
- An OpenAI API key
- Flutter SDK (for the mobile app)

---

## Environment Variables
Create a `.env` file in the root directory:
```env
OPENAI_API_KEY=your-openai-key-here
```
> Never commit this file. It is already listed in `.gitignore`.

---

## Backend Setup

```bash
pip install -r requirements.txt
```

## Run

```bash
uvicorn main:app --host 0.0.0.0 --port 8000
```

> Use `--host 0.0.0.0` so your Android phone can reach it over Wi-Fi.

---

## API Endpoints

### GET /
Health check.
```json
{ "status": "ok", "message": "Darija Translator API is running" }
```

---

### POST /translate/text
Translate text between Darija and English (auto-detects direction).

**Request:**
```json
{ "text": "كيف داير؟" }
```

**Response:**
```json
{ "darija": "كيف داير؟", "english": "How are you?" }
```

---

### POST /translate/audio
Send a `.wav` or `.mp3` audio file and get a Darija transcription + English translation.

**Request:** `multipart/form-data` with field `file`

**Response:**
```json
{ "darija": "لاباس عليك", "english": "Are you doing well?" }
```

---

## Interactive Docs
Once the server is running, open in your browser:
http://localhost:8000/docs


---

## Connect from Android
Find your PC's local IP:
```bash
# Windows
ipconfig
```
Look for `IPv4 Address` e.g. `192.168.1.10`

Set your Android app base URL to:


http://192.168.1.10:8000



Make sure your phone and PC are on the same Wi-Fi network.

---

## Flutter App
The mobile app is in the `darija_translator66/` folder. It uses:
- Firebase Authentication (email/password + Google Sign-In)
- Cloud Firestore for translation history

To run it:
```bash
cd darija_translator66
flutter pub get
flutter run
```

---

## Project Structure

darija-api/
├── main.py # FastAPI app
├── pipeline.py # ASR + translation pipeline
├── requirements.txt
├── .env # Your API keys (not committed)
└── darija_translator66/ # Flutter app
└── lib/main.dart