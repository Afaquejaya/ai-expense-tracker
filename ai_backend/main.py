import asyncio
import json
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel

app = FastAPI()

# --- THE AI HOOKS MECHANISM ---
class AIExecutionHooks:
    async def on_llm_start(self):
        print("\n[HOOK TRIGGERED]: on_llm_start() -> AI started thinking. Shimmer active.")
        # Real app mein yahan hum WebSockets/SSE se mobile ko 'loading' bhejte hain.
        await asyncio.sleep(1.5) # Simulating network delay

    async def on_llm_end(self, raw_output: str):
        print(f"[HOOK TRIGGERED]: on_llm_end() -> Received raw text from AI: '{raw_output}'")
        print("[HOOK TRIGGERED]: Cleaning and enforcing strict JSON format...")
        
        # Real app mein yahan regex ya schema validation hota hai.
        # Hum simulated text ko strict JSON array mein transform kar rahe hain.
        await asyncio.sleep(0.5) 
        
        if "dubai mall" in raw_output.lower():
            structured_data = [
                {"item": "Dinner with friends (Dubai Mall)", "amount": 120, "currency": "AED", "category": "Food"},
                {"item": "Taxi Ride", "amount": 15, "currency": "AED", "category": "Transport"}
            ]
        else:
            # Fallback output agar user kuch aur likhe
            structured_data = [
                {"item": "General Expense", "amount": 50, "currency": "INR", "category": "Other"}
            ]
        return structured_data

    async def on_chain_error(self, error_msg: str):
        print(f"[CRITICAL HOOK TRIGGERED]: on_chain_error() -> Error: {error_msg}")
        return {"status": "error", "action": "save_local", "message": "Network dropped. Save to SQLite."}


# --- API ENDPOINT FOR FLUTTER ---
class ExpenseRequest(BaseModel):
    text: str

@app.post("/process-expense")
async def process_expense(request: ExpenseRequest):
    hooks = AIExecutionHooks()
    
    # Trigger 1: Pre-processing Hook (Shimmer Start)
    await hooks.on_llm_start()
    
    # Simulated AI Network Drop (Error Hook Testing)
    if "error" in request.text.lower():
        error_response = await hooks.on_chain_error("Simulated OpenAI Timeout Exception")
        return error_response

    # Simulated AI Raw Output
    raw_ai_text = request.text
    
    # Trigger 2: Post-processing Hook (Enforce JSON Structure)
    final_structured_json = await hooks.on_llm_end(raw_ai_text)
    
    return {
        "status": "success",
        "data": final_structured_json
    }

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)