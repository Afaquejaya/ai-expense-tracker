# AI Smart Expense Tracker

An AI-powered Flutter app that turns natural-language text into structured expenses, backed by a Python (FastAPI) server that demonstrates LangChain-style **AI execution hooks** (`on_llm_start`, `on_llm_end`, `on_chain_error`).

<p align="center">
  <img src="ChatGPT%20Image%20Jun%2020,%202026,%2010_26_22%20PM.png" alt="AI Smart Expense Tracker preview" width="600">
</p>

## How it works

```
Flutter app ──POST /process-expense──▶ FastAPI backend
                                        ├─ on_llm_start   → app shows shimmer loader
                                        ├─ on_llm_end     → raw text cleaned into strict JSON
                                        └─ on_chain_error → app shows offline / save-local fallback
```

| Hook | Backend (`ai_backend/main.py`) | App UI (`lib/main.dart`) |
|------|-------------------------------|--------------------------|
| `on_llm_start` | AI starts "thinking" | Shimmer placeholder cards |
| `on_llm_end` | Output converted to a JSON list of expenses | Expense cards with item, category and amount |
| `on_chain_error` | Returns `action: save_local` | Orange offline / error message |

> The backend currently **simulates** the AI response, so no API key is needed.

## Tech stack

- **Flutter** (Dart SDK `>=3.1.5`), using the `http` package
- **Python 3.8+**, **FastAPI**, **Uvicorn**

## Project structure

```
ai_backend/main.py   # FastAPI server with the AI hooks
lib/main.dart        # Flutter UI
test/                # Flutter widget tests
```

## Run the app

### 1. Start the backend

```bash
cd ai_backend
pip install fastapi uvicorn
python main.py
```

The server starts on `http://0.0.0.0:8000`. Keep this terminal open: the hook logs (`[HOOK TRIGGERED] ...`) are printed here.

### 2. Point the app at the backend

Open `lib/main.dart` and set `_backendUrl` for the device you're using:

| Device | URL |
|--------|-----|
| Android emulator | `http://10.0.2.2:8000/process-expense` |
| iOS simulator / desktop | `http://localhost:8000/process-expense` |
| Real phone (same Wi-Fi) | `http://<your-PC-IPv4>:8000/process-expense` |

To find your PC's IPv4 address, run `ipconfig` on Windows or `ifconfig` on macOS/Linux. If you're testing on a real phone and the requests fail, allow port `8000` through your firewall.

### 3. Run the Flutter app

```bash
flutter pub get
flutter run
```

## Test the flow

### Manual testing in the app

| # | Type this | Expected result |
|---|-----------|-----------------|
| 1 | `Yaar aaj dosto ke sath Dubai Mall mein 120 AED ka dinner kiya aur 15 AED taxi mein kharch hue.` | Shimmer loader, then two cards: **Dinner with friends (Dubai Mall), 120 AED** (Food) and **Taxi Ride, 15 AED** (Transport) |
| 2 | Any other text, e.g. `Bought groceries` | One card: **General Expense, 50 INR** (Other) |
| 3 | Any text containing `error` | Orange message: *Hook Error: Network dropped... Saved to Local Database (Offline)* |
| 4 | Any text, with the backend **stopped** | *Failed to connect to backend AI pipeline.* |

In each case, watch the backend terminal to see the matching `[HOOK TRIGGERED]` logs.

### Test the API directly

```bash
curl -X POST http://localhost:8000/process-expense \
  -H "Content-Type: application/json" \
  -d '{"text": "Dubai Mall dinner 120 AED and taxi 15 AED"}'
```

Expected response:

```json
{
  "status": "success",
  "data": [
    {"item": "Dinner with friends (Dubai Mall)", "amount": 120, "currency": "AED", "category": "Food"},
    {"item": "Taxi Ride", "amount": 15, "currency": "AED", "category": "Transport"}
  ]
}
```

FastAPI also serves interactive API docs at `http://localhost:8000/docs`.

### Flutter tests

```bash
flutter test
```

## Contact

afaquejaya123@gmail.com
