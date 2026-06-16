import os
import firebase_admin
from firebase_admin import credentials, auth, firestore
from dotenv import load_dotenv

# Load env variables
env_path = os.getenv("ENV_PATH", "app/config/env/Development.env")
load_dotenv(env_path)

def init_firebase():
    """
    Initialize Firebase Admin SDK using a service account JSON file.
    """
    if not firebase_admin._apps:
        try:
            cred_path = os.getenv("GOOGLE_APPLICATION_CREDENTIALS")
            
            if cred_path and os.path.exists(cred_path):
                cred = credentials.Certificate(cred_path)
                firebase_admin.initialize_app(cred)
                print(f"✅ Firebase Admin initialized via JSON file: {cred_path}")
            else:
                # Fallback to default application credentials
                firebase_admin.initialize_app()
                print("⚠️ Firebase Admin initialized via default application credentials.")
                
        except Exception as e:
            print(f"❌ Failed to initialize Firebase: {e}")

def get_auth_client():
    """
    Get the Firebase Auth client instance.
    """
    if not firebase_admin._apps:
        init_firebase()
    return auth

def get_firestore_client():
    """
    Get the Firestore database client instance.
    """
    if not firebase_admin._apps:
        init_firebase()
    return firestore.client()

# Auto-initialize when this module is imported
init_firebase()
