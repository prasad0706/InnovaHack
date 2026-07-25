from fastapi import FastAPI, File, UploadFile, Form, HTTPException, Header, status
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from pydantic import BaseModel
from typing import Optional

from schemas import UploadSuccessResponse, ErrorResponse
from ingestion.pdf_loader import load_pdf, PDFPasswordException
from ingestion.table_extractor import extract_tables_from_pdf
from ingestion.regex_fallback import fallback_parse
from cleaning.transaction_cleaner import clean_transactions
from cleaning.merchant_normalizer import normalize_transactions
from detection.subscription_detector import detect_subscriptions, calculate_health_score
import auth
import database
import plaid_service

app = FastAPI(
    title="SubSense API",
    description="Hidden Subscription & Recurring Payment Leak Detector API with Plaid Sandbox & PostgreSQL DB",
    version="1.4.0",
)

# Enable CORS for Flutter app
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

class RegisterRequest(BaseModel):
    email: str
    password: str
    name: Optional[str] = None

class LoginRequest(BaseModel):
    email: str
    password: str

class PlaidConnectRequest(BaseModel):
    bank_name: Optional[str] = "HDFC Bank"
    months: Optional[int] = 6
    user_id: Optional[str] = None

class DisconnectBankRequest(BaseModel):
    user_id: Optional[str] = None

@app.get("/")
@app.head("/")
def root():
    return {
        "status": "ok",
        "message": "SubSense API Backend is live and operational!",
        "version": "1.4.0",
        "docs": "/docs",
    }

@app.get("/api/health")
def health_check():
    return {
        "status": "ok",
        "app": "SubSense Backend",
        "database": "Supabase PostgreSQL" if database.is_supabase_enabled() else "Local Persistent DB",
        "plaid_mode": plaid_service.PLAID_ENV,
    }

@app.post("/api/auth/register")
def register(req: RegisterRequest):
    try:
        user_data = auth.register_user(req.email, req.password, req.name or "")
        return {"status": "success", "user": user_data}
    except ValueError as e:
        return JSONResponse(
            status_code=status.HTTP_400_BAD_REQUEST,
            content={"status": "error", "error_code": "REGISTRATION_FAILED", "message": str(e)},
        )

@app.post("/api/auth/login")
def login(req: LoginRequest):
    try:
        user_data = auth.login_user(req.email, req.password)
        return {"status": "success", "user": user_data}
    except ValueError as e:
        return JSONResponse(
            status_code=status.HTTP_401_UNAUTHORIZED,
            content={"status": "error", "error_code": "AUTH_FAILED", "message": str(e)},
        )

@app.get("/api/auth/me")
def get_current_user(authorization: Optional[str] = Header(None)):
    if not authorization or not authorization.startswith("Bearer "):
        return JSONResponse(
            status_code=status.HTTP_401_UNAUTHORIZED,
            content={"status": "error", "error_code": "UNAUTHORIZED", "message": "Missing authentication token."},
        )
    token = authorization.replace("Bearer ", "").strip()
    user_data = auth.verify_token(token)
    if not user_data:
        return JSONResponse(
            status_code=status.HTTP_401_UNAUTHORIZED,
            content={"status": "error", "error_code": "INVALID_TOKEN", "message": "Invalid or expired token."},
        )
    return {"status": "success", "user": user_data}

@app.post("/api/plaid/create_link_token")
def create_plaid_link_token(authorization: Optional[str] = Header(None)):
    user_id = "default_user"
    if authorization and authorization.startswith("Bearer "):
        token = authorization.replace("Bearer ", "").strip()
        user_info = auth.verify_token(token)
        if user_info:
            user_id = user_info["id"]

    return plaid_service.create_link_token(user_id)

@app.post("/api/plaid/connect")
def connect_bank_account(
    req: PlaidConnectRequest,
    authorization: Optional[str] = Header(None),
):
    bank_name = req.bank_name or "HDFC Bank"
    months = req.months or 6

    target_user_id = req.user_id or "default_user"
    if authorization and authorization.startswith("Bearer "):
        token = authorization.replace("Bearer ", "").strip()
        user_info = auth.verify_token(token)
        if user_info:
            target_user_id = user_info["id"]

    raw_txns = plaid_service.fetch_bank_transactions(bank_name=bank_name, months=months)
    cleaned_txns = clean_transactions(raw_txns)
    normalized_txns = normalize_transactions(cleaned_txns)
    subscriptions = detect_subscriptions(normalized_txns)
    health_score = calculate_health_score(subscriptions)

    dates = [t["date"] for t in cleaned_txns if t.get("date")]
    dates.sort()
    from_date = dates[0] if dates else "2026-01-01"
    to_date = dates[-1] if dates else "2026-07-01"

    summary_data = {
        "total_transactions_found": len(cleaned_txns),
        "subscriptions_detected": len(subscriptions),
        "parsing_method": f"Plaid Sandbox ({bank_name})",
        "bank_connected": bank_name,
        "date_range": {"from_date": from_date, "to_date": to_date},
        "health_score": health_score,
    }

    # Save bank connection status
    database.update_user_bank_connection(target_user_id, bank_name, is_connected=True)

    # Save analysis & merge transaction history
    saved = database.merge_and_save_analysis(
        user_id=target_user_id,
        summary=summary_data,
        subscriptions=subscriptions,
        new_transactions=normalized_txns,
    )

    return {
        "status": "success",
        "summary": summary_data,
        "subscriptions": subscriptions,
        "all_transactions": saved.get("all_transactions", normalized_txns),
        "is_bank_connected": True,
        "connected_bank": bank_name,
    }

@app.post("/api/plaid/disconnect")
def disconnect_bank_account(
    req: DisconnectBankRequest,
    authorization: Optional[str] = Header(None),
):
    target_user_id = req.user_id or "default_user"
    if authorization and authorization.startswith("Bearer "):
        token = authorization.replace("Bearer ", "").strip()
        user_info = auth.verify_token(token)
        if user_info:
            target_user_id = user_info["id"]

    res = database.update_user_bank_connection(target_user_id, bank_name=None, is_connected=False)
    return {"status": "success", "message": "Bank account disconnected successfully.", "profile": res}

@app.get("/api/analysis/latest")
def get_latest_analysis(
    user_id: Optional[str] = None,
    authorization: Optional[str] = Header(None),
):
    target_user_id = user_id or "default_user"
    if authorization and authorization.startswith("Bearer "):
        token = authorization.replace("Bearer ", "").strip()
        user_info = auth.verify_token(token)
        if user_info:
            target_user_id = user_info["id"]

    res = database.get_latest_analysis(target_user_id)
    if not res:
        return JSONResponse(
            status_code=status.HTTP_404_NOT_FOUND,
            content={"status": "error", "error_code": "NOT_FOUND", "message": "No stored analysis found for this account."},
        )
    return res

@app.post("/api/upload")
async def upload_statement(
    file: UploadFile = File(...),
    password: Optional[str] = Form(None),
    user_id: Optional[str] = Form(None),
    authorization: Optional[str] = Header(None),
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

    parsing_method = "table"
    raw_txns = extract_tables_from_pdf(pdf)

    if len(raw_txns) < 3:
        parsing_method = "regex_fallback"
        raw_txns = fallback_parse(pdf)

    pdf.close()

    if len(raw_txns) == 0:
        return JSONResponse(
            status_code=status.HTTP_200_OK,
            content={
                "status": "error",
                "error_code": "NO_TRANSACTIONS_FOUND",
                "message": "No structured transactions found in this statement. Try another PDF or use the demo dataset.",
            },
        )

    cleaned_txns = clean_transactions(raw_txns)
    normalized_txns = normalize_transactions(cleaned_txns)

    target_user_id = user_id or "default_user"
    if authorization and authorization.startswith("Bearer "):
        token = authorization.replace("Bearer ", "").strip()
        user_info = auth.verify_token(token)
        if user_info:
            target_user_id = user_info["id"]

    # Save & Merge with existing user history
    saved = database.merge_and_save_analysis(
        user_id=target_user_id,
        summary={},
        subscriptions=[],
        new_transactions=normalized_txns,
    )

    # Re-run detection over COMBINED transaction history!
    combined_txns = saved.get("all_transactions", normalized_txns)
    subscriptions = detect_subscriptions(combined_txns)
    health_score = calculate_health_score(subscriptions)

    dates = [t["date"] for t in combined_txns if t.get("date")]
    dates.sort()
    from_date = dates[0] if dates else "2026-01-01"
    to_date = dates[-1] if dates else "2026-07-01"

    summary_data = {
        "total_transactions_found": len(combined_txns),
        "subscriptions_detected": len(subscriptions),
        "parsing_method": parsing_method,
        "date_range": {"from_date": from_date, "to_date": to_date},
        "health_score": health_score,
    }

    # Re-save final summary & subscriptions
    database.save_analysis(
        user_id=target_user_id,
        summary=summary_data,
        subscriptions=subscriptions,
        all_transactions=combined_txns,
    )

    return {
        "status": "success",
        "summary": summary_data,
        "subscriptions": subscriptions,
        "all_transactions": combined_txns,
    }
