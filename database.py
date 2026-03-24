"""
Database Configuration - SQLAlchemy Setup
SQLite (development) ya PostgreSQL (production) dono support karta hai
"""

import os
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker, DeclarativeBase
from dotenv import load_dotenv

load_dotenv()

# DATABASE_URL .env se lo
# Default: SQLite (local file, koi server nahi chahiye)
# Production ke liye: postgresql://user:password@host:5432/dbname
DATABASE_URL = os.getenv(
    "DATABASE_URL",
    "sqlite:///./transcriptions.db"  # Local SQLite file
)

# SQLite ke liye special argument zaroori hai (multithreading issue)
connect_args = {}
if DATABASE_URL.startswith("sqlite"):
    connect_args = {"check_same_thread": False}

# Database engine banao
engine = create_engine(
    DATABASE_URL,
    connect_args=connect_args,
    echo=False,  # True karo toh SQL queries console mein dikhegi (debugging)
)

# Session factory
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)


# Base class - sare models is se inherit karenge
class Base(DeclarativeBase):
    pass
