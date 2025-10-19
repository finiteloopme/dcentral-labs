from fastapi import FastAPI, Request, HTTPException
from fastapi.responses import JSONResponse
import httpx
import uuid

app = FastAPI()

ANALYST_API_URL = "http://localhost:8001"
MIDNIGHT_VERIFIER_URL = "http://localhost:8002"

@app.post("/api/predict")
async def predict(request: Request):
    auth_header = request.headers.get("Authorization")

    if not auth_header:
        invoice_id = str(uuid.uuid4())
        # In a real implementation, you would create a real invoice
        # and store it in a database.
        return JSONResponse(
            status_code=402,
            headers={
                "WWW-Authenticate": f'L402 token="{invoice_id}", invoice="{invoice_id}"'
            },
            content={"error": "Payment required"},
        )

    try:
        # The auth header should be in the format "L402 <midnight_tx_id>:<preimage>"
        auth_parts = auth_header.split(" ")
        if len(auth_parts) != 2 or auth_parts[0] != "L402":
            raise HTTPException(status_code=401, detail="Invalid authorization header")

        l402_token = auth_parts[1]
        token_parts = l402_token.split(":")
        if len(token_parts) != 2:
            raise HTTPException(status_code=401, detail="Invalid L402 token")

        midnight_tx_id, preimage = token_parts

        # Verify the payment with the midnight-verifier
        async with httpx.AsyncClient() as client:
            response = await client.post(
                f"{MIDNIGHT_VERIFIER_URL}/verify",
                json={"tx_id": midnight_tx_id, "preimage": preimage},
            )

        if response.status_code != 200 or not response.json().get("verified"):
            raise HTTPException(status_code=401, detail="Payment verification failed")

        # Forward the request to the analyst-api
        async with httpx.AsyncClient() as client:
            body = await request.json()
            response = await client.post(f"{ANALYST_API_URL}/analyze", json=body)

        return response.json()

    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
