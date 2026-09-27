"""
File for supabase connection.
"""

from dotenv import load_dotenv
import os
from supabase import create_client

load_dotenv()  # Load environment variables from .env file
SUPABASE_API_URL = "https://lvtjyhigbynbhomsktjm.supabase.co"
SUPABASE_API_KEY = os.getenv("SUPABASE_API_KEY")

supabase = create_client(SUPABASE_API_URL, SUPABASE_API_KEY)
