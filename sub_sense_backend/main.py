from fastapi import FastAPI, File, UploadFile, Form, HTTPException, status
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from typing import Optional

from schemas import UploadSuccessResponse, ErrorResponse
from ingestion.pdf_loader import load_pdf, PDFPasswordException
from ingestion.table_extractor import extract_tables_from_pdf
from ingestion.regex_fallback import fallback_parse
from cleaning.transaction_cleaner import clean_transactions
from cleaning.merchant_normalizer import normalize_transactions
from detection.subscription_detector import detect_subscriptions, calculate_health_score

app = FastAPI(
    title="SubSense API",
    description="Hidden Subscription & Recurring Payment Leak Detector API",
    version="1.0.0",
)

# Enable CORS for Flutter app
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.get("/api/health")
def health_check():
    return {"status": "ok", "app": "SubSense Backend"}

@app.post("/api/upload")
async def upload_statement(
    file: UploadFile = File(...),
    password: Optional[str] = Form(None),
):
    if not file.filename or not file.filename.lower().endswith(".pdf"):
        return JSONResponse(
            status_code=status.HTTP_400_BAD_REQUEST,
            content={
                "status": "error",
                "error_code": "PARSE_FAILED",
                "message": "That file isn't a PDF. Please upload a bank statement in PDF format.",
            },
        )

    file_bytes = await file.read()
    if len(file_bytes) == 0:
        return JSONResponse(
            status_code=status.HTTP_400_BAD_REQUEST,
            content={
                "status": "error",
                "error_code": "PARSE_FAILED",
                "message": "Uploaded file is empty.",
            },
        )

    # 1. Load PDF with pikepdf password decryption support
    try:
        pdf = load_pdf(file_bytes, password=password)
    except PDFPasswordException as e:
        status_code = (
            status.HTTP_401_UNAUTHORIZED
            if e.code == "PDF_PASSWORD_INCORRECT"
            else status.HTTP_422_UNPROCESSABLE_ENTITY
        )
        return JSONResponse(
            status_code=status_code,
            content={
                "status": "error",
                "error_code": e.code,
                "message": e.message,
            },
        )
    except Exception as e:
        return JSONResponse(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            content={
                "status": "error",
                "error_code": "PARSE_FAILED",
                "message": f"Could not parse PDF statement: {str(e)}",
            },
        )

    # 2. Extract transactions using Tier 1 table extractor
    parsing_method = "table"
    raw_txns = extract_tables_from_pdf(pdf)

    # 3. Fallback to Tier 2 Regex parser if Tier 1 yields < 3 transactions
    if len(raw_txns) < 3:
        parsing_method = "regex_fallback"
        raw_txns = fallback_parse(pdf)

    pdf.close()

    # If still no transactions found
    if len(raw_txns) == 0:
        return JSONResponse(
            status_code=status.HTTP_200_OK,
            content={
                "status": "error",
                "error_code": "NO_TRANSACTIONS_FOUND",
                "message": "No structured transactions found in this statement. Try another PDF or use the demo dataset.",
            },
        )

    # 4. Clean transactions & normalize dates/amounts
    cleaned_txns = clean_transactions(raw_txns)

    # 5. Normalize merchant names using merchants.json + rapidfuzz
    normalized_txns = normalize_transactions(cleaned_txns)

    # 6. Detect recurring subscriptions & price hikes
    subscriptions = detect_subscriptions(normalized_txns)
    
    # 7. Calculate baseline health score
    health_score = calculate_health_score(subscriptions)

    dates = [t["date"] for t in cleaned_txns if t.get("date")]
    dates.sort()
    from_date = dates[0] if dates else "2026-01-01"
    to_date = dates[-1] if dates else "2026-07-01"

    return {
        "status": "success",
        "summary": {
            "total_transactions_found": len(cleaned_txns),
            "subscriptions_detected": len(subscriptions),
            "parsing_method": parsing_method,
            "date_range": {"from_date": from_date, "to_date": to_date},
            "health_score": health_score,
        },
        "subscriptions": subscriptions,
    }
