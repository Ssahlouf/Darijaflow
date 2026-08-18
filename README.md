# Darija Translator — Backend API

FastAPI server exposing two endpoints for your Android app.

## Setup

```bash
pip install -r requirements.txt
```

## Run

```bash
uvicorn main:app --host 0.0.0.0 --port 8000
```

> Use `--host 0.0.0.0` so your Android phone can reach it over Wi-Fi.

## API Endpoints

### GET /
Health check.
```json
{ "status": "ok", "message": "Darija Translator API is running" }
```

---

### POST /translate/text
Translate Darija text → English.

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
Send a `.wav` / `.mp3` audio file → get Darija transcription + English translation.

**Request:** `multipart/form-data` with field `file`

**Response:**
```json
{ "darija": "لاباس عليك", "english": "I'm fine" }
```

---

## Interactive Docs
Once running, open in browser:
```
http://localhost:8000/docs
```

## Connect from Android
Find your PC's local IP:
```bash
# Windows
ipconfig
```
Look for `IPv4 Address` e.g. `192.168.1.10`

Your Android app base URL will be:
```
http://192.168.1.10:8000
```
Make sure your phone and PC are on the same Wi-Fi network.
