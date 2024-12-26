import subprocess
from pathlib import Path
import sys
import logging
import argparse

# Set up logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

def check_file_exists(file_path):
    """Check if the specified file exists."""
    file_path = Path(file_path)
    if not file_path.is_file():
        raise FileNotFoundError(f"File '{file_path}' does not exist.")
    logger.debug(f"File '{file_path}' exists.")

def build_ffmpeg_command(input_file, output_file, video_codec='copy', audio_codec='copy'):
    """Construct the ffmpeg command to convert MKV to MP4 with no quality loss."""
    return [
        'ffmpeg',
        '-i', str(input_file),
        '-c:v', video_codec,
        '-c:a', audio_codec,
        '-strict', 'experimental',
        str(output_file)
    ]

def run_ffmpeg_command(command):
    """Execute the ffmpeg command and handle potential errors."""
    logger.info(f"Running command: {' '.join(command)}")
    try:
        result = subprocess.run(command, check=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)
        logger.info("Conversion completed successfully.")
        logger.debug(result.stdout)
    except subprocess.CalledProcessError as error:
        logger.error(f"Error during conversion:\n{error.stdout}")
        sys.exit(1)

def check_file_size(file_path):
    """Check if the file size is greater than 0."""
    file_path = Path(file_path)
    if file_path.stat().st_size == 0:
        raise ValueError(f"File '{file_path}' is empty.")
    logger.debug(f"File '{file_path}' has size {file_path.stat().st_size} bytes.")

def convert_mkv_to_mp4(input_file, output_file, video_codec='copy', audio_codec='copy'):
    """Convert an MKV video to MP4 format with no quality loss."""
    input_file = Path(input_file)
    output_file = Path(output_file)

    check_file_exists(input_file)
    command = build_ffmpeg_command(input_file, output_file, video_codec, audio_codec)
    run_ffmpeg_command(command)
    check_file_size(output_file)

def parse_arguments():
    """Parse command line arguments."""
    parser = argparse.ArgumentParser(description="Convert MKV to MP4 without quality loss.")
    parser.add_argument('input_file', type=str, help='Path to the input MKV file')
    parser.add_argument('output_file', type=str, help='Path to the output MP4 file')
    parser.add_argument('--video_codec', type=str, default='copy', help='Video codec (default: copy)')
    parser.add_argument('--audio_codec', type=str, default='copy', help='Audio codec (default: copy)')

    args = parser.parse_args()

    return args.input_file, args.output_file, args.video_codec, args.audio_codec

def main():
    """Main function to handle script execution."""
    input_file, output_file, video_codec, audio_codec = parse_arguments()

    try:
        convert_mkv_to_mp4(input_file, output_file, video_codec, audio_codec)
    except (FileNotFoundError, ValueError) as e:
        logger.error(e)
        sys.exit(1)

if __name__ == "__main__":
    main()
