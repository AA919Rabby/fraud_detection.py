import os
import smtplib
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart

SMTP_EMAIL = os.getenv("SMTP_EMAIL")
SMTP_PASSWORD = os.getenv("SMTP_PASSWORD")
SMTP_SERVER = "smtp.gmail.com"
SMTP_PORT = 587


def send_reset_code_email(to_email: str, code: str):
    if not SMTP_EMAIL or not SMTP_PASSWORD:
        raise RuntimeError("SMTP_EMAIL / SMTP_PASSWORD not configured")

    msg = MIMEMultipart()
    msg["From"] = SMTP_EMAIL
    msg["To"] = to_email
    msg["Subject"] = "Your password reset code"

    body = f"""
    Your password reset code is: {code}

    This code expires in 15 minutes. If you didn't request this, you can ignore this email.
    """
    msg.attach(MIMEText(body, "plain"))

    with smtplib.SMTP(SMTP_SERVER, SMTP_PORT) as server:
        server.starttls()
        server.login(SMTP_EMAIL, SMTP_PASSWORD)
        server.sendmail(SMTP_EMAIL, to_email, msg.as_string())