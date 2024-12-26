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

def upload_file_to_drive(file_path, folder_id):
    file_metadata = {
        'name': os.path.basename(file_path),
        'parents': [folder_id]
    }
    media = MediaFileUpload(file_path, mimetype='video/mp4')
    file = service.files().create(body=file_metadata, media_body=media, fields='id, webViewLink').execute()
    file_id = file.get('id')
    download_link = f"https://drive.google.com/uc?id={file_id}&export=download"
    return download_link

if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: python3 upload_to_gdrive.py <file_path>")
        sys.exit(1)
    
    file_path = sys.argv[1]
    folder_id = "1BqeRm09e4HkxOahklm2f8YU6qHkvIkPr"  # ID folder di Google Drive
    
    link = upload_file_to_drive(file_path, folder_id)
    print(f"File uploaded successfully. Download it at: {link}")
