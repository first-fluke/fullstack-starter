#!/bin/bash
# =============================================================================
# GCP Project Migration Script
# =============================================================================
# This script performs migration from an existing GCP project to a new project.
#
# Usage:
#   ./migrate-gcp-project.sh --old-project OLD_PROJECT_ID --new-project NEW_PROJECT_ID
#
# Example:
#   ./migrate-gcp-project.sh --old-project your-old-project --new-project your-new-project
#
# Prerequisites:
#   - gcloud CLI installed and authenticated
#   - Owner/Editor permissions for both projects
#   - psql installed (for DB migration)
#   - docker installed (for container image migration)
# =============================================================================

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default values
OLD_PROJECT=""
NEW_PROJECT=""
OLD_REGION="your-old-region"
NEW_REGION="your-new-region"
OLD_BUCKET_PREFIX="your-old-bucket-prefix"
NEW_BUCKET_PREFIX="your-new-bucket-prefix"
SKIP_DB=false
SKIP_STORAGE=false
SKIP_IMAGES=false
SKIP_APIS=false

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --old-project)
            OLD_PROJECT="$2"
            shift 2
            ;;
        --new-project)
            NEW_PROJECT="$2"
            shift 2
            ;;
        --old-region)
            OLD_REGION="$2"
            shift 2
            ;;
        --new-region)
            NEW_REGION="$2"
            shift 2
            ;;
        --skip-db)
            SKIP_DB=true
            shift
            ;;
        --skip-storage)
            SKIP_STORAGE=true
            shift
            ;;
        --skip-images)
            SKIP_IMAGES=true
            shift
            ;;
        --skip-apis)
            SKIP_APIS=true
            shift
            ;;
        -h|--help)
            echo "Usage: $0 --old-project OLD_PROJECT_ID --new-project NEW_PROJECT_ID [options]"
            echo ""
            echo "Options:"
            echo "  --old-project PROJECT_ID     Old project ID"
            echo "  --new-project PROJECT_ID     New project ID"
            echo "  --old-region REGION          Old project region (default: your-old-region)"
            echo "  --new-region REGION          New project region (default: your-new-region)"
            echo "  --skip-db                    Skip database migration"
            echo "  --skip-storage               Skip storage bucket migration"
            echo "  --skip-images                Skip container image migration"
            echo "  --skip-apis                  Skip API enablement"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

# Validate required arguments
if [[ -z "$OLD_PROJECT" || -z "$NEW_PROJECT" ]]; then
    echo -e "${RED}Error: --old-project and --new-project are required${NC}"
    exit 1
fi

log_step() {
    echo -e "\n${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${GREEN}[STEP]${NC} $1"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

log_info() {
    echo -e "${YELLOW}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# =============================================================================
# Step 1: Enable Required APIs
# =============================================================================
enable_apis() {
    log_step "Enabling required APIs in new project"
    
    APIS=(
        "sqladmin.googleapis.com"
        "run.googleapis.com"
        "artifactregistry.googleapis.com"
        "iamcredentials.googleapis.com"
        "cloudtasks.googleapis.com"
        "pubsub.googleapis.com"
        "storage.googleapis.com"
        "compute.googleapis.com"
        "vpcaccess.googleapis.com"
        "aiplatform.googleapis.com"
    )
    
    for api in "${APIS[@]}"; do
        log_info "Enabling $api..."
        gcloud services enable "$api" --project="$NEW_PROJECT" 2>/dev/null || true
    done
    
    log_success "All APIs enabled"
}

# =============================================================================
# Step 2: Database Migration
# =============================================================================
migrate_database() {
    log_step "Migrating Cloud SQL Database"
    
    # Get old instance info
    OLD_INSTANCE=$(gcloud sql instances list --project="$OLD_PROJECT" --format="value(NAME)" | head -1)
    if [[ -z "$OLD_INSTANCE" ]]; then
        log_error "No Cloud SQL instance found in old project"
        return 1
    fi
    log_info "Old instance: $OLD_INSTANCE"
    
    # Get new instance info
    NEW_INSTANCE=$(gcloud sql instances list --project="$NEW_PROJECT" --format="value(NAME)" | head -1)
    if [[ -z "$NEW_INSTANCE" ]]; then
        log_error "No Cloud SQL instance found in new project"
        return 1
    fi
    log_info "New instance: $NEW_INSTANCE"
    
    # Get service account for old instance
    OLD_SA=$(gcloud sql instances describe "$OLD_INSTANCE" --project="$OLD_PROJECT" --format="value(serviceAccountEmailAddress)")
    
    # Create temp bucket for migration
    MIGRATION_BUCKET="gs://${NEW_PROJECT}-migration"
    log_info "Creating migration bucket: $MIGRATION_BUCKET"
    gcloud storage buckets create "$MIGRATION_BUCKET" --location="$NEW_REGION" --project="$NEW_PROJECT" 2>/dev/null || true
    
    # Grant old Cloud SQL SA access to migration bucket
    log_info "Granting bucket access to old Cloud SQL service account..."
    gcloud storage buckets add-iam-policy-binding "$MIGRATION_BUCKET" \
        --member="serviceAccount:$OLD_SA" \
        --role="roles/storage.objectAdmin" \
        --project="$NEW_PROJECT"
    
    # Export database from old instance
    TIMESTAMP=$(date +%Y%m%d_%H%M%S)
    DUMP_FILE="$MIGRATION_BUCKET/db_dump_$TIMESTAMP.sql"
    log_info "Exporting database to $DUMP_FILE..."
    gcloud sql export sql "$OLD_INSTANCE" "$DUMP_FILE" \
        --database=your-old-database \
        --project="$OLD_PROJECT"
    
    # Get new Cloud SQL SA
    NEW_SA=$(gcloud sql instances describe "$NEW_INSTANCE" --project="$NEW_PROJECT" --format="value(serviceAccountEmailAddress)")
    
    # Grant new Cloud SQL SA access to migration bucket
    log_info "Granting bucket access to new Cloud SQL service account..."
    gcloud storage buckets add-iam-policy-binding "$MIGRATION_BUCKET" \
        --member="serviceAccount:$NEW_SA" \
        --role="roles/storage.objectViewer" \
        --project="$NEW_PROJECT"
    
    # Create database if not exists
    log_info "Creating database in new instance..."
    gcloud sql databases create your-new-database --instance="$NEW_INSTANCE" --project="$NEW_PROJECT" 2>/dev/null || true
    
    # Import database to new instance
    log_info "Importing database from $DUMP_FILE..."
    gcloud sql import sql "$NEW_INSTANCE" "$DUMP_FILE" \
        --database=your-new-database \
        --user=postgres \
        --project="$NEW_PROJECT" \
        --quiet
    
    log_success "Database migration completed"
}

# =============================================================================
# Step 3: Storage Bucket Migration
# =============================================================================
migrate_storage() {
    log_step "Migrating GCS Buckets"
    
    # Define bucket pairs (old -> new)
    declare -A BUCKET_PAIRS=(
        ["${OLD_BUCKET_PREFIX}-prod"]="${NEW_BUCKET_PREFIX}-prod"
        ["${OLD_BUCKET_PREFIX}-backup"]="${NEW_BUCKET_PREFIX}-backup"
    )
    
    for OLD_BUCKET in "${!BUCKET_PAIRS[@]}"; do
        NEW_BUCKET="${BUCKET_PAIRS[$OLD_BUCKET]}"
        log_info "Migrating gs://$OLD_BUCKET -> gs://$NEW_BUCKET"
        
        # Create new bucket if not exists
        gcloud storage buckets create "gs://$NEW_BUCKET" \
            --location="$NEW_REGION" \
            --project="$NEW_PROJECT" 2>/dev/null || true
        
        # Sync data
        log_info "Syncing data..."
        gcloud storage rsync -r "gs://$OLD_BUCKET" "gs://$NEW_BUCKET" 2>/dev/null || true
        
        log_success "Migrated $OLD_BUCKET -> $NEW_BUCKET"
    done
    
    log_success "Storage migration completed"
}

# =============================================================================
# Step 4: Container Image Migration
# =============================================================================
migrate_images() {
    log_step "Migrating Container Images"
    
    # Configure docker auth for both registries
    log_info "Configuring Docker authentication..."
    gcloud auth configure-docker "${OLD_REGION}-docker.pkg.dev,${NEW_REGION}-docker.pkg.dev" --quiet
    
    # Get running images from old project Cloud Run services
    SERVICES=("your-old-image-1" "your-old-image-2" "your-old-image-3")
    
    for SERVICE in "${SERVICES[@]}"; do
        log_info "Processing service: $SERVICE"
        
        # Get current image
        OLD_IMAGE=$(gcloud run services describe "$SERVICE" \
            --region="$OLD_REGION" \
            --project="$OLD_PROJECT" \
            --format="value(spec.template.spec.containers[0].image)" 2>/dev/null) || continue
        
        if [[ -z "$OLD_IMAGE" ]]; then
            log_info "Service $SERVICE not found in old project, skipping"
            continue
        fi
        
        log_info "Old image: $OLD_IMAGE"
        
        # Extract image name and tag
        IMAGE_TAG=$(echo "$OLD_IMAGE" | grep -oE ':[^:]+$' | sed 's/://')
        
        # Determine new image path
        case "$SERVICE" in
            your-old-image-1|your-old-image-2|your-old-image-3)
                NEW_IMAGE="${NEW_REGION}-docker.pkg.dev/${NEW_PROJECT}/your-new-image-1:${IMAGE_TAG}"
                ;;
        esac
        
        log_info "New image: $NEW_IMAGE"
        
        # Pull, tag, push
        docker pull "$OLD_IMAGE"
        docker tag "$OLD_IMAGE" "$NEW_IMAGE"
        docker push "$NEW_IMAGE"
        
        # Also push as latest
        LATEST_IMAGE=$(echo "$NEW_IMAGE" | sed "s/:${IMAGE_TAG}/:latest/")
        docker tag "$OLD_IMAGE" "$LATEST_IMAGE"
        docker push "$LATEST_IMAGE"
        
        log_success "Migrated image for $SERVICE"
    done
    
    log_success "Container image migration completed"
}

# =============================================================================
# Main Execution
# =============================================================================
main() {
    echo -e "${GREEN}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║   GCP Project Migration for $OLD_PROJECT to $NEW_PROJECT     ║"
    echo "╠══════════════════════════════════════════════════════════════╣"
    echo "║  Old Project: $OLD_PROJECT"
    echo "║  New Project: $NEW_PROJECT"
    echo "║  Old Region:  $OLD_REGION"
    echo "║  New Region:  $NEW_REGION"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    
    # Confirm
    read -p "Proceed with migration? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Migration cancelled"
        exit 0
    fi
    
    # Enable APIs
    if [[ "$SKIP_APIS" == false ]]; then
        enable_apis
    fi
    
    # Migrate database
    if [[ "$SKIP_DB" == false ]]; then
        migrate_database
    fi
    
    # Migrate storage
    if [[ "$SKIP_STORAGE" == false ]]; then
        migrate_storage
    fi
    
    # Migrate images
    if [[ "$SKIP_IMAGES" == false ]]; then
        migrate_images
    fi
    
    echo -e "\n${GREEN}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║                   Migration Complete!                         ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    
    echo -e "${YELLOW}Next Steps:${NC}"
    echo "1. Update GitHub Secrets:"
    echo "   - GCP_WORKLOAD_IDENTITY_PROVIDER"
    echo "   - GCP_SERVICE_ACCOUNT"
    echo ""
    echo "2. Update app configuration files:"
    echo "   - apps/api/src/lib/config.py (gcs_bucket_name)"
    echo "   - apps/infra/variables.tf (project_id, region variables)"
    echo ""
    echo "3. Run Terraform apply in new project"
    echo ""
    echo "4. Test API and Web endpoints"
}

main
