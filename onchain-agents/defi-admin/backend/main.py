from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from typing import List, Dict, Any
import uvicorn

app = FastAPI(title="DeFi Admin API", version="0.1.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["http://localhost:3000", "http://localhost:3001"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.get("/")
async def root():
    return {"message": "DeFi Admin API", "version": "0.1.0"}

@app.get("/health")
async def health_check():
    return {"status": "healthy"}

from api import protocols, agents, analysis, chains

app.include_router(protocols.router, prefix="/api/protocols", tags=["protocols"])
app.include_router(agents.router, prefix="/api/agents", tags=["agents"])
app.include_router(analysis.router, prefix="/api/analysis", tags=["analysis"])
app.include_router(chains.router, prefix="/api/chains", tags=["chains"])

if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8000, reload=True)