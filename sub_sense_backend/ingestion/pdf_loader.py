import io
import pikepdf
import pdfplumber

class PDFPasswordException(Exception):
    def __init__(self, code: str, message: str):
        self.code = code
        self.message = message
        super().__init__(message)

def load_pdf(file_bytes: bytes, password: str | None = None):
    """
    Attempts to open PDF. Handles decryption via pikepdf if password protected.
    Returns open pdfplumber.PDF object.
    """
    try:
        if password:
            buf = io.BytesIO()
            with pikepdf.open(io.BytesIO(file_bytes), password=password) as pdf:
                pdf.save(buf)
            buf.seek(0)
            return pdfplumber.open(buf)
        else:
            # Try loading without password
            try:
                buf = io.BytesIO(file_bytes)
                pdf = pdfplumber.open(buf)
                # Force access to pages to trigger encryption check
                _ = len(pdf.pages)
                return pdf
            except Exception as e:
                err_str = str(e).lower()
                if "password" in err_str or "encrypted" in err_str or "pikepdf" in err_str:
                    raise PDFPasswordException(
                        "PDF_PASSWORD_REQUIRED",
                        "This PDF bank statement is password-protected. Please enter your password.",
                    )
                # Try pikepdf without password to double check
                try:
                    with pikepdf.open(io.BytesIO(file_bytes)) as pdf:
                        buf2 = io.BytesIO()
                        pdf.save(buf2)
                        buf2.seek(0)
                        return pdfplumber.open(buf2)
                except pikepdf.PasswordError:
                    raise PDFPasswordException(
                        "PDF_PASSWORD_REQUIRED",
                        "This PDF bank statement is password-protected. Please enter your password.",
                    )
                except Exception:
                    raise e

    except pikepdf.PasswordError:
        raise PDFPasswordException(
            "PDF_PASSWORD_INCORRECT",
            "Incorrect password entered for this PDF statement. Please verify and try again.",
        )
    except PDFPasswordException:
        raise
    except Exception as e:
        raise Exception(f"Failed to open PDF file: {str(e)}")
