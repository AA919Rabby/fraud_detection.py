import os
import resend

resend.api_key = os.getenv("RESEND_API_KEY")


def send_reset_code_email(to_email: str, code: str):
    if not resend.api_key:
        raise RuntimeError("RESEND_API_KEY not configured")

    resend.Emails.send({
        "from": "onboarding@resend.dev",
        "to": [to_email],
        "subject": "Your password reset code",
        "text": (
            f"Your password reset code is: {code}\n\n"
            "This code expires in 15 minutes."
        ),
    })