#!/bin/bash

# AWS Amplify Log Downloader Script
# This script downloads logs for a specific AWS Amplify app and job

/*

# ------------------------------------------------------------
# sample script for amplify YAML file
# Environment variables:    ARTIFACT_BUCKET
# ------------------------------------------------------------

# version: 1
# applications:
#   - frontend:
#       phases:
#         preBuild:
#           commands:
#             - nvm use 20
#             - corepack enable
#             - |
#               if [ -n "$ARTIFACT_BUCKET" ]; then
#                 echo "Verifying S3 permissions for artifact bucket: $ARTIFACT_BUCKET"
                
#                 if aws s3 ls s3://$ARTIFACT_BUCKET > /dev/null 2>&1; then
#                   echo "✅ SUCCESS: Can access S3 bucket $ARTIFACT_BUCKET"
                  
#                   TEST_FILE="test-permission-$(date +%s).txt"
#                   echo "Testing write permissions..." > /tmp/$TEST_FILE
                  
#                   if aws s3 cp /tmp/$TEST_FILE s3://$ARTIFACT_BUCKET/test-permissions/ > /dev/null 2>&1; then
#                     echo "✅ SUCCESS: Can write to S3 bucket $ARTIFACT_BUCKET"
#                     aws s3 rm s3://$ARTIFACT_BUCKET/test-permissions/$TEST_FILE > /dev/null 2>&1
#                   else
#                     echo "❌ ERROR: Cannot write to S3 bucket $ARTIFACT_BUCKET"
#                     echo "Please check IAM permissions for the Amplify service role"
#                     exit 1
#                   fi
                  
#                   rm -f /tmp/$TEST_FILE
#                 else
#                   echo "❌ ERROR: Cannot access S3 bucket $ARTIFACT_BUCKET"
#                   echo "Please check:"
#                   echo "1. Bucket name is correct"
#                   echo "2. IAM permissions for the Amplify service role"
#                   echo "3. Bucket exists and is accessible"
#                   exit 1
#                 fi
#               else
#                 echo "⚠️  WARNING: ARTIFACT_BUCKET environment variable not set"
#                 echo "Artifact upload will be skipped. Set ARTIFACT_BUCKET in Amplify environment variables to enable artifact preservation."
#               fi
#         build:
#           commands:
#             - pnpm --filter @crmk-mm/utils build
#             - pnpm --filter @crmk-mm/web-consumer build:prod
#             - |
#               if [ -d "apps/web-consumer/.next" ]; then
#                 echo "Uploading .next directory to S3 for artifact preservation..."
                
#                 # Get Amplify environment variables
#                 APP_ID="${AWS_APP_ID:-unknown}"
#                 BRANCH_NAME="${AWS_BRANCH:-unknown}"
#                 JOB_ID="${CODEBUILD_BUILD_NUMBER:-unknown}"
#                 BUILD_ID="${CODEBUILD_BUILD_ID:-unknown}"
                
#                 echo "App ID: $APP_ID"
#                 echo "Branch: $BRANCH_NAME"
#                 echo "Job ID: $JOB_ID"
#                 echo "Build ID: $BUILD_ID"
                
#                 # Create a more organized S3 path structure
#                 S3_PATH="artifacts/$APP_ID/$BRANCH_NAME/$JOB_ID"
                
#                 aws s3 sync apps/web-consumer/.next s3://$ARTIFACT_BUCKET/$S3_PATH/.next --delete
#                 echo "Artifact upload completed. Build artifacts preserved in S3 at: s3://$ARTIFACT_BUCKET/$S3_PATH/.next"
#               else
#                 echo "Warning: .next directory not found after build"
#               fi
#       artifacts:
#         baseDirectory: apps/web-consumer/.next/standalone/apps/web-consumer
#         files:
#           - "**/*"
#       cache:
#         paths:
#           - apps/web-consumer/.next/cache/**/*
#           - apps/web-consumer/node_modules/**/*
#           - libs/utils/dist/**/*
#       buildPath: /
#     appRoot: apps/web-consumer

# ------------------------------------------------------------

# Default configuration variables
APP_ID="d1xt9tuzgdhhye"
JOB_ID="7"
BRANCH_NAME="develop-stage"
LOG_DIR="./aws-amplify-log"
ARTIFACT_BUCKET="public-mm"
DOWNLOAD_ARTIFACTS=true

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print usage information
print_usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  --job ID           Specify the job ID (default: 3)"
    echo "  --app ID           Specify the app ID (default: d3k5nbxvxuz6fb)"
    echo "  --branch NAME      Specify the branch name (default: main)"
    echo "  --output DIR       Specify the output directory (default: ./aws-amplify-log)"
    echo "  --bucket NAME      Specify the S3 bucket for artifacts (required for --artifacts)"
    echo "  --artifacts        Download .next directory artifacts from S3"
    echo "  --help             Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 --job 23"
    echo "  $0 --job 45 --branch main"
    echo "  $0 --job 12 --app d3k5nbxvxuz6fb --output ./logs"
    echo "  $0 --job 3 --bucket my-artifact-bucket --artifacts"
}

# Function to parse command line arguments
parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --job)
                JOB_ID="$2"
                shift 2
                ;;
            --app)
                APP_ID="$2"
                shift 2
                ;;
            --branch)
                BRANCH_NAME="$2"
                shift 2
                ;;
            --output)
                LOG_DIR="$2"
                shift 2
                ;;
            --bucket)
                ARTIFACT_BUCKET="$2"
                shift 2
                ;;
            --artifacts)
                DOWNLOAD_ARTIFACTS=true
                shift
                ;;
            --help)
                print_usage
                exit 0
                ;;
            *)
                print_error "Unknown option: $1"
                print_usage
                exit 1
                ;;
        esac
    done
    
    # Set the final log directory to include app ID, branch, and job ID
    LOG_DIR="${LOG_DIR}/${APP_ID}/${BRANCH_NAME}/${JOB_ID}"
    
    # Validate artifact download requirements
    if [ "$DOWNLOAD_ARTIFACTS" = true ] && [ -z "$ARTIFACT_BUCKET" ]; then
        print_error "S3 bucket name is required when using --artifacts option"
        print_usage
        exit 1
    fi
}

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check if AWS CLI is installed and configured
check_aws_cli() {
    if ! command -v aws &> /dev/null; then
        print_error "AWS CLI is not installed. Please install it first."
        exit 1
    fi

    if ! aws sts get-caller-identity &> /dev/null; then
        print_error "AWS CLI is not configured. Please run 'aws configure' first."
        exit 1
    fi

    print_success "AWS CLI is properly configured"
}

# Function to get job details
get_job_details() {
    print_status "Getting job details for App ID: $APP_ID, Job ID: $JOB_ID, Branch: $BRANCH_NAME"
    
    # Get job details
    JOB_DETAILS=$(aws amplify get-job --app-id "$APP_ID" --branch-name "$BRANCH_NAME" --job-id "$JOB_ID" 2>&1)
    
    if [ $? -ne 0 ]; then
        print_error "Failed to get job details: $JOB_DETAILS"
        exit 1
    fi

    print_success "Job details retrieved successfully"
    
    # Extract job status
    JOB_STATUS=$(echo "$JOB_DETAILS" | jq -r '.job.summary.status // "UNKNOWN"')
    COMMIT_MESSAGE=$(echo "$JOB_DETAILS" | jq -r '.job.summary.commitMessage // "No commit message"')
    START_TIME=$(echo "$JOB_DETAILS" | jq -r '.job.summary.startTime // "Unknown"')
    END_TIME=$(echo "$JOB_DETAILS" | jq -r '.job.summary.endTime // "Unknown"')
    
    print_status "Job Status: $JOB_STATUS"
    print_status "Commit Message: $COMMIT_MESSAGE"
    print_status "Start Time: $START_TIME"
    print_status "End Time: $END_TIME"
}

# Function to download logs for a specific step
download_step_logs() {
    local step_name=$1
    local log_url=$2
    
    if [ -z "$log_url" ] || [ "$log_url" = "null" ]; then
        print_warning "No log URL available for step: $step_name"
        return
    fi
    
    local log_file="$LOG_DIR/${step_name}_log.txt"
    print_status "Downloading logs for step: $step_name"
    
    # Download the log file
    if curl -s -L "$log_url" -o "$log_file"; then
        print_success "Downloaded logs for $step_name to $log_file"
        
        # Show first few lines of the log
        print_status "First 10 lines of $step_name log:"
        echo "----------------------------------------"
        head -n 10 "$log_file"
        echo "----------------------------------------"
    else
        print_error "Failed to download logs for step: $step_name"
    fi
}

# Function to download all step logs
download_all_logs() {
    print_status "Downloading all step logs..."
    
    # Get job details and extract log URLs
    JOB_DETAILS=$(aws amplify get-job --app-id "$APP_ID" --branch-name "$BRANCH_NAME" --job-id "$JOB_ID")
    
    # Extract log URLs for each step
    echo "$JOB_DETAILS" | jq -r '.job.steps[] | "\(.stepName)|\(.logUrl // "null")"' | while IFS='|' read -r step_name log_url; do
        if [ "$log_url" != "null" ] && [ -n "$log_url" ]; then
            download_step_logs "$step_name" "$log_url"
        else
            print_warning "No log URL available for step: $step_name"
        fi
    done
}

# Function to download .next artifacts from S3
download_artifacts() {
    if [ "$DOWNLOAD_ARTIFACTS" != true ]; then
        return
    fi
    
    print_status "Downloading .next artifacts from S3..."
    
    local artifact_dir="$LOG_DIR/.next"
    local s3_path="s3://$ARTIFACT_BUCKET/artifacts/$APP_ID/$BRANCH_NAME/$JOB_ID/.next"
    
    # Check if artifacts exist in S3
    if aws s3 ls "$s3_path" &> /dev/null; then
        print_status "Found artifacts in S3, downloading to $artifact_dir"
        
        # Create artifact directory
        mkdir -p "$artifact_dir"
        
        # Download artifacts
        if aws s3 sync "$s3_path" "$artifact_dir" --delete; then
            print_success "Successfully downloaded .next artifacts to $artifact_dir"
            
            # Show artifact structure
            print_status "Artifact structure:"
            echo "----------------------------------------"
            find "$artifact_dir" -type f | head -20
            echo "----------------------------------------"
            print_status "Total files: $(find "$artifact_dir" -type f | wc -l)"
        else
            print_error "Failed to download artifacts from S3"
        fi
    else
        print_warning "No artifacts found in S3 at path: $s3_path"
        print_warning "Make sure your amplify.yml is configured to upload artifacts to S3"
    fi
}

# Function to create summary report
create_summary_report() {
    local summary_file="$LOG_DIR/summary_report.txt"
    
    print_status "Creating summary report..."
    
    cat > "$summary_file" << EOF
AWS Amplify Log Summary Report
==============================

App ID: $APP_ID
Job ID: $JOB_ID
Branch: $BRANCH_NAME
Download Time: $(date)

Job Details:
- Status: $JOB_STATUS
- Commit Message: $COMMIT_MESSAGE
- Start Time: $START_TIME
- End Time: $END_TIME

Downloaded Log Files:
EOF

    # List all downloaded log files
    for log_file in "$LOG_DIR"/*_log.txt; do
        if [ -f "$log_file" ]; then
            echo "- $(basename "$log_file")" >> "$summary_file"
        fi
    done
    
    # Add artifact information if artifacts were downloaded
    if [ "$DOWNLOAD_ARTIFACTS" = true ] && [ -d "$LOG_DIR/.next" ]; then
        echo "" >> "$summary_file"
        echo "Downloaded Artifacts:" >> "$summary_file"
        echo "- .next directory (from S3: $ARTIFACT_BUCKET/artifacts/$APP_ID/$BRANCH_NAME/$JOB_ID/.next)" >> "$summary_file"
        echo "- Total files: $(find "$LOG_DIR/.next" -type f | wc -l)" >> "$summary_file"
    fi
    
    print_success "Summary report created: $summary_file"
}

# Main execution
main() {
    print_status "Starting AWS Amplify log download..."
    print_status "App ID: $APP_ID"
    print_status "Job ID: $JOB_ID"
    print_status "Branch: $BRANCH_NAME"
    print_status "Log Directory: $LOG_DIR"
    
    if [ "$DOWNLOAD_ARTIFACTS" = true ]; then
        print_status "Artifact download enabled for bucket: $ARTIFACT_BUCKET"
    fi
    
    # Check prerequisites
    check_aws_cli
    
    # Create log directory if it doesn't exist
    mkdir -p "$LOG_DIR"
    
    # Get job details
    get_job_details
    
    # Download all logs
    download_all_logs
    
    # Download artifacts if requested
    download_artifacts
    
    # Create summary report
    create_summary_report
    
    print_success "Download completed! Check the $LOG_DIR directory for downloaded files."
}

# Check if jq is installed
if ! command -v jq &> /dev/null; then
    print_error "jq is not installed. Please install it first:"
    print_error "  macOS: brew install jq"
    print_error "  Ubuntu: sudo apt-get install jq"
    print_error "  CentOS: sudo yum install jq"
    exit 1
fi

# Parse command line arguments
parse_arguments "$@"

# Run main function
main "$@"
