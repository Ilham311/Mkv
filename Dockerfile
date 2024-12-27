# Gunakan image dasar Ubuntu
FROM ubuntu:latest

# Install dependencies
RUN apt-get update && \
    apt-get install -y ffmpeg curl python3-pip python3-full && \
    apt-get install -y python3-venv

# Buat dan aktifkan virtual environment
RUN python3 -m venv /opt/venv

# Aktifkan virtual environment dan install paket Python
RUN /opt/venv/bin/pip install --upgrade pip && \
    /opt/venv/bin/pip install google-auth google-auth-oauthlib google-auth-httplib2 google-api-python-client

# Salin skrip upload ke dalam container
COPY upload_to_gdrive.py /usr/local/bin/upload_to_gdrive.py

# Salin token Google Drive
COPY token.pickle /usr/local/bin/token.pickle

# Definisikan direktori kerja
WORKDIR /data

# Jalankan semua langkah dalam satu RUN
RUN VIDEO_URL="https://sxtcp.tg-index.workers.dev/download.aspx?file=Yx5s%2Be9wDli6mozqFtq2sX3XZGG5PxANRhGgYe3KHRQRVaMmmEmgYedSUzowgiHP&expiry=950dgENNoY%2F%2Fzr%2B9Tp89Kg%3D%3D&mac=36c69f84b389142965d4b424adfeb7cd7d6c02286f330904b54996baea17e19a" && \
    curl -L -o video.mkv "$VIDEO_URL" && \
    ffmpeg -i video.mkv -vf "scale=-1:720" -r 23 -c:v libx264 -preset medium -crf 23 -c:a aac -b:a 128k -c:s mov_text -movflags +faststart video.mp4 && \
    GDRIVE_TOKEN="$(cat /usr/local/bin/token.pickle)" && \
    /opt/venv/bin/python /usr/local/bin/upload_to_gdrive.py video.mp4

# Setelah selesai, keluar
CMD ["exit"]
