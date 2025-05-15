#!/bin/bash

# Amazon Transcribe Automation Script
# Usage: ./transcribe.sh <video_file>

set -e

# Configuration
BUCKET_NAME="none-of-the-above"
LANGUAGE_CODE="en-US"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUTPUT_DIR="${SCRIPT_DIR}/transcriptions"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Functions
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

check_dependencies() {
    log_info "Checking dependencies..."
    
    if ! command -v aws &> /dev/null; then
        log_error "AWS CLI not found. Please install and configure AWS CLI."
        exit 1
    fi
    
    if ! command -v jq &> /dev/null; then
        log_error "jq not found. Please install jq for JSON processing."
        exit 1
    fi
    
    if ! command -v ffmpeg &> /dev/null; then
        log_error "ffmpeg not found. Please install ffmpeg for audio extraction."
        echo "  macOS: brew install ffmpeg"
        echo "  Ubuntu/Debian: sudo apt install ffmpeg"
        exit 1
    fi
    
    # Check AWS credentials
    if ! aws sts get-caller-identity &> /dev/null; then
        log_error "AWS credentials not configured. Please run 'aws configure'."
        exit 1
    fi
    
    log_info "All dependencies satisfied."
}

usage() {
    echo "Usage: $0 <video_file>"
    echo ""
    echo "Arguments:"
    echo "  video_file    Path to the video file to transcribe"
    echo ""
    echo "Example:"
    echo "  $0 /path/to/video.mp4"
    exit 1
}

# Parse arguments
if [ $# -ne 1 ]; then
    usage
fi

VIDEO_FILE="$1"

# Validate input file
if [ ! -f "$VIDEO_FILE" ]; then
    log_error "Video file not found: $VIDEO_FILE"
    exit 1
fi

# Check dependencies
check_dependencies

# Get file info
FILENAME=$(basename "$VIDEO_FILE")
FILE_EXTENSION="${FILENAME##*.}"
FILE_BASE="${FILENAME%.*}"
TIMESTAMP=$(date +%Y%m%d-%H%M%S)

# Extract audio from video
AUDIO_FILE="${OUTPUT_DIR}/${FILE_BASE}.wav"
AUDIO_FILENAME="${FILE_BASE}.wav"

log_info "Extracting audio from video..."
if [ ! -f "$AUDIO_FILE" ]; then
    ffmpeg -i "$VIDEO_FILE" -vn -acodec pcm_s16le -ar 44100 -ac 2 "$AUDIO_FILE" -y || {
        log_error "Failed to extract audio from video"
        exit 1
    }
    log_info "Audio extracted to: $AUDIO_FILE"
else
    log_info "Audio file already exists: $AUDIO_FILE"
fi

# Sanitize job name - replace spaces and special chars with underscores
JOB_NAME="transcribe-$(echo "${FILE_BASE}" | sed 's/[^a-zA-Z0-9._-]/_/g')-${TIMESTAMP}"

# Create output directory
mkdir -p "$OUTPUT_DIR"

# Check if audio file already exists on S3
log_info "Checking if audio file already exists on S3..."
S3_URI="s3://${BUCKET_NAME}/${AUDIO_FILENAME}"

if aws s3 ls "$S3_URI" &> /dev/null; then
    log_info "Audio file already exists on S3: $S3_URI"
else
    # Upload audio file to S3
    log_info "Uploading $AUDIO_FILENAME to S3..."
    
    aws s3 cp "$AUDIO_FILE" "$S3_URI" || {
        log_error "Failed to upload audio file to S3"
        exit 1
    }
    
    log_info "Audio file uploaded to: $S3_URI"
fi

# Start transcription job with subtitle generation
log_info "Starting transcription job: $JOB_NAME"

aws transcribe start-transcription-job \
    --transcription-job-name "$JOB_NAME" \
    --language-code "$LANGUAGE_CODE" \
    --media-format "wav" \
    --media "MediaFileUri=$S3_URI" \
    --output-bucket-name "$BUCKET_NAME" \
    --output-key "transcriptions/${JOB_NAME}/" \
    --subtitles "Formats=srt" || {
    log_error "Failed to start transcription job"
    exit 1
}

# Wait for job completion
log_info "Waiting for transcription to complete..."
echo -n "Progress: "
while true; do
    STATUS=$(aws transcribe get-transcription-job \
        --transcription-job-name "$JOB_NAME" \
        --query 'TranscriptionJob.TranscriptionJobStatus' \
        --output text)
    
    case $STATUS in
        "COMPLETED")
            echo ""
            log_info "Transcription completed successfully!"
            break
            ;;
        "FAILED")
            echo ""
            log_error "Transcription job failed!"
            aws transcribe get-transcription-job \
                --transcription-job-name "$JOB_NAME" \
                --query 'TranscriptionJob.FailureReason' \
                --output text
            exit 1
            ;;
        "IN_PROGRESS")
            echo -n "."
            sleep 10
            ;;
        *)
            log_warn "Unknown status: $STATUS"
            sleep 10
            ;;
    esac
done

# Get job details
JOB_DETAILS=$(aws transcribe get-transcription-job --transcription-job-name "$JOB_NAME")

# Get transcript URI
TRANSCRIPT_URI=$(echo "$JOB_DETAILS" | jq -r '.TranscriptionJob.Transcript.TranscriptFileUri')

# Get SRT subtitle URI
SRT_URI=$(echo "$JOB_DETAILS" | jq -r '.TranscriptionJob.Subtitles.SubtitleFileUris[0]')

log_info "Downloading files..."

# Download and save plain text transcript
TRANSCRIPT_FILE="${OUTPUT_DIR}/${FILE_BASE}_transcript.txt"
curl -s "$TRANSCRIPT_URI" | jq -r '.results.transcripts[0].transcript' > "$TRANSCRIPT_FILE"

log_info "Plain text transcript saved to: $TRANSCRIPT_FILE"

# Download and save SRT file
SRT_FILE="${OUTPUT_DIR}/${FILE_BASE}.srt"
curl -s "$SRT_URI" > "$SRT_FILE"

log_info "SRT subtitles saved to: $SRT_FILE"

# Summary
log_info "Transcription complete! Files saved:"
echo "  - Original video: $VIDEO_FILE"
echo "  - S3 audio file: $S3_URI"
echo "  - S3 transcript: $TRANSCRIPT_URI"
echo "  - S3 SRT subtitles: $SRT_URI"
echo "  - Local audio: $AUDIO_FILE"
echo "  - Local plain text: $TRANSCRIPT_FILE"
echo "  - Local SRT subtitles: $SRT_FILE"

log_info "Note: Audio and transcription files remain on S3 in bucket '$BUCKET_NAME'"