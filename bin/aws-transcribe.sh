#!/bin/bash

# Amazon Transcribe Automation Script, by claude 3.7 sonnet
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
    
    # Check AWS credentials, also output them because I like to see them
    if ! aws sts get-caller-identity ; then
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
JOB_NAME="transcribe-${FILE_BASE}-${TIMESTAMP}"

# Create output directory
mkdir -p "$OUTPUT_DIR"

# Upload file to S3
log_info "Uploading $FILENAME to S3..."
S3_URI="s3://${BUCKET_NAME}/${FILENAME}"

aws s3 cp "$VIDEO_FILE" "$S3_URI" || {
    log_error "Failed to upload file to S3"
    exit 1
}

log_info "File uploaded to: $S3_URI"

# Start transcription job with subtitle generation
log_info "Starting transcription job: $JOB_NAME"

aws transcribe start-transcription-job \
    --transcription-job-name "$JOB_NAME" \
    --language-code "$LANGUAGE_CODE" \
    --media-format "$FILE_EXTENSION" \
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
echo "  - S3 video file: $S3_URI"
echo "  - S3 transcript: $TRANSCRIPT_URI"
echo "  - S3 SRT subtitles: $SRT_URI"
echo "  - Local plain text: $TRANSCRIPT_FILE"
echo "  - Local SRT subtitles: $SRT_FILE"

log_info "Note: Video and transcription files remain on S3 in bucket '$BUCKET_NAME'"v