from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker, declarative_base
import os
from dotenv import load_dotenv

load_dotenv()

DATABASE_URL = os.getenv("DATABASE_URL", "sqlite:///./fallback.db")

engine = create_engine(
    DATABASE_URL,
    pool_pre_ping=True,      # tests connections before using them, reconnects if stale
    pool_recycle=300,        # recycles connections every 5 minutes (Neon closes idle ones)
)

SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
Base = declarative_base()

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()