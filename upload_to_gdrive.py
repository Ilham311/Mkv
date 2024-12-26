import os
import pickle
import sys
from googleapiclient.discovery import build
from googleapiclient.http import MediaFileUpload
from google.auth.transport.requests import Request

# Load token.pickle
token_path = 'token.pickle'
if not os.path.exists(token_path):
    print("Error: token.pickle file not found")
    sys.exit(1)

with open(token_path, 'rb') as token:
    try:
        creds = pickle.load(token)
    except Exception as e:
        print(f"Error loading token.pickle: {e}")
        sys.exit(1)

# If the token is expired, refresh it
if creds.expired and creds.refresh_token:
    creds.refresh(Request())

# Build the Google Drive service
service = build('drive', 'v3', credentials=creds)

def upload_file_to_drive(file_path):
    file_metadata = {'name': os.path.basename(file_path)}
    media = MediaFileUpload(file_path, mimetype='video/mp4')
    file = service.files().create(body=file_metadata, media_body=media, fields='id').execute()
    print(f"File ID: {file.get('id')}")

if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: python3 upload_to_gdrive.py <file_path>")
        sys.exit(1)
    upload_file_to_drive(sys.argv[1])
