from pydantic import BaseModel
from typing import List, Optional

class DateRange(BaseModel):
    from_date: str
    to_date: str

class AnalysisSummary(BaseModel):
    total_transactions_found: int
    subscriptions_detected: int
    parsing_method: str  # "table" | "regex_fallback"
    date_range: Optional[DateRange] = None
    health_score: Optional[int] = None

class PriceChangeSchema(BaseModel):
    increased: bool
    amount_change: float = 0.0
    percent_change: float = 0.0

class HistoryItemSchema(BaseModel):
    date: str
    amount: float

class SubscriptionSchema(BaseModel):
    id: str
    merchant: str
    category: str
    frequency: str
    current_amount: float
    confidence: float
    price_change: Optional[PriceChangeSchema] = None
    history: List[HistoryItemSchema] = []
    recommended_action: str  # "Cancel" | "Downgrade" | "Keep"
    action_reason: str
    monthly_saving: float

class UploadSuccessResponse(BaseModel):
    status: str = "success"
    summary: AnalysisSummary
    subscriptions: List[SubscriptionSchema]

class ErrorResponse(BaseModel):
    status: str = "error"
    error_code: str  # "PDF_PASSWORD_REQUIRED" | "PDF_PASSWORD_INCORRECT" | "PARSE_FAILED" | "NO_TRANSACTIONS_FOUND"
    message: str
