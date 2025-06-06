#!/bin/bash

# Amazon Transcribe Automation Script
# Usage: ./transcribe.sh <video_file>

set -e

# Configuration
BUCKET_NAME="none-of-the-above"
LANGUAGE_CODE="en-US"
OUTPUT_DIR="./transcriptions"

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
# No timestamp so we can reuse the same job name for the same file
JOB_NAME="transcribe-$(echo "${FILE_BASE}" | sed 's/[^a-zA-Z0-9._-]/_/g')"

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

# Start transcription job with subtitle generation (or check if already exists)
log_info "Checking for existing transcription job: $JOB_NAME"

# Check if job already exists
if aws transcribe get-transcription-job --transcription-job-name "$JOB_NAME" --output json &> /dev/null; then
    log_info "Transcription job already exists, checking status..."
    STATUS=$(aws transcribe get-transcription-job \
        --transcription-job-name "$JOB_NAME" \
        --query 'TranscriptionJob.TranscriptionJobStatus' \
        --output text)
    
    if [ "$STATUS" = "COMPLETED" ]; then
        log_info "Job already completed, skipping to download..."
    elif [ "$STATUS" = "FAILED" ]; then
        log_error "Previous job failed, please use a different job name or delete the failed job"
        exit 1
    else
        log_info "Job in progress, waiting for completion..."
    fi
else
    # Start new transcription job
    log_info "Starting new transcription job: $JOB_NAME"
    
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
fi

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
JOB_DETAILS=$(aws transcribe get-transcription-job --transcription-job-name "$JOB_NAME" --output json)

# Get transcript URI
TRANSCRIPT_URI=$(echo "$JOB_DETAILS" | jq -r '.TranscriptionJob.Transcript.TranscriptFileUri')

# Get SRT subtitle URI
SRT_URI=$(echo "$JOB_DETAILS" | jq -r '.TranscriptionJob.Subtitles.SubtitleFileUris[0]')

log_info "Transcript URI: $TRANSCRIPT_URI"
log_info "SRT URI: $SRT_URI"

log_info "Downloading files..."

# Download and save plain text transcript
TRANSCRIPT_FILE="${OUTPUT_DIR}/${FILE_BASE}_transcript.txt"

# Download transcript with AWS CLI (handles authentication)
log_info "Downloading transcript..."
TEMP_JSON=$(mktemp)

# Extract bucket and key from transcript URI
TRANSCRIPT_S3_PATH=$(echo "$TRANSCRIPT_URI" | sed 's|https://[^/]*/||')

if aws s3 cp "s3://${TRANSCRIPT_S3_PATH}" "$TEMP_JSON"; then
    # Show what we actually downloaded
    log_info "Downloaded file size: $(wc -c < "$TEMP_JSON") bytes"
    
    # Verify JSON is valid and extract transcript
    if jq empty "$TEMP_JSON" 2>/dev/null; then
        jq -r '.results.transcripts[0].transcript' "$TEMP_JSON" > "$TRANSCRIPT_FILE"
        log_info "Plain text transcript saved to: $TRANSCRIPT_FILE"
    else
        log_error "Downloaded file is not valid JSON"
        log_info "First 500 characters:"
        head -c 500 "$TEMP_JSON"
        echo ""
        exit 1
    fi
else
    log_error "Failed to download transcript from S3"
    exit 1
fi

rm "$TEMP_JSON"

# Download and save SRT file
SRT_FILE="${OUTPUT_DIR}/${FILE_BASE}.srt"

# Extract bucket and key from SRT URI
SRT_S3_PATH=$(echo "$SRT_URI" | sed 's|https://[^/]*/||')

if aws s3 cp "s3://${SRT_S3_PATH}" "$SRT_FILE"; then
    log_info "SRT subtitles saved to: $SRT_FILE"
else
    log_error "Failed to download SRT file from S3"
    exit 1
fi

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