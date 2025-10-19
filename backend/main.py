from fastapi import FastAPI
import os
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

# Create FastAPI app
app = FastAPI(
    title="PeakFindr API",
    version="0.1.0",
    description="A simple API for PeakFindr mobile app"
)

@app.get("/")
async def root():
    return {"message": "Hello from PeakFindr API!"}

@app.get("/health")
async def health_check():
    return {"status": "healthy", "service": "PeakFindr API"}

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(
        "main:app", 
        host="0.0.0.0", 
        port=8000, 
        reload=True
    )