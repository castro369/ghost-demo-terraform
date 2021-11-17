#!/bin/bash

# Set Environment Variables
echo "###########################"
echo " Set Environment Variables "
echo "###########################"

export PROJECT_ID=$(gcloud config get-value project)
export PROJECT_NUMBER=$(gcloud projects list --filter="$(gcloud config get-value project)" --format="value(PROJECT_NUMBER)")

# Enable APIs
echo "###############"
echo " Enabling APIs "
echo "###############"
gcloud services enable compute.googleapis.com \
    servicenetworking.googleapis.com \
    sqladmin.googleapis.com \
    iap.googleapis.com \
    iam.googleapis.com \
    cloudresourcemanager.googleapis.com \
    cloudbuild.googleapis.com \
    monitoring.googleapis.com \
    compute.googleapis.com \
    logging.googleapis.com \
    containerregistry.googleapis.com \
    vpcaccess.googleapis.com \
    secretmanager.googleapis.com \
    run.googleapis.com


# Grant permissions to Compute SA
echo "############################"
echo " Granting Permissions to SA "
echo "############################"

gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member serviceAccount:"${PROJECT_NUMBER}-compute@developer.gserviceaccount.com" \
    --role="roles/secretmanager.secretAccessor"

gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member serviceAccount:"${PROJECT_NUMBER}-compute@developer.gserviceaccount.com" \
    --role="roles/vpcaccess.admin"

gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member serviceAccount:"${PROJECT_NUMBER}-compute@developer.gserviceaccount.com" \
    --role="roles/cloudsql.client"

gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member serviceAccount:"${PROJECT_NUMBER}-compute@developer.gserviceaccount.com" \
    --role="roles/secretmanager.secretAccessor"

# Grant permissions to Cloudbuild SA
gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member serviceAccount:"${PROJECT_NUMBER}@cloudbuild.gserviceaccount.com" \
    --role="roles/editor"

gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member="serviceAccount:${PROJECT_NUMBER}@cloudbuild.gserviceaccount.com" \
    --role="roles/secretmanager.secretAccessor"


echo "#############################################"
echo " Creating Bucket for TF state and Plan Files "
echo "#############################################"

# Create bucket for Terraform state
gsutil mb -c STANDARD -l EUROPE-WEST1 gs://${PROJECT_ID}-tfstate
gsutil versioning set on gs://${PROJECT_ID}-tfstate

# Create bucket for Terraform plan files
gsutil mb -c STANDARD -l EUROPE-WEST1 gs://${PROJECT_ID}-terraform-planfiles
gsutil versioning set on gs://${PROJECT_ID}-terraform-planfiles

echo "#####################################"
echo " Creating TF Service Account and key "
echo "#####################################"

# Create Terraform Service Account
gcloud iam service-accounts create terraform-sa \
    --description="Terraform Service Account" \
    --display-name="Terraform Service Account"  

# Bind Roles to Terraform Service Account
gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member="serviceAccount:terraform-sa@${PROJECT_ID}.iam.gserviceaccount.com" \
    --role="roles/owner"

# Create JSON KEY
gcloud iam service-accounts keys create terraform-sa.json \
    --iam-account=terraform-sa@${PROJECT_ID}.iam.gserviceaccount.com


# Create Secret with terraform key
echo "#################################"
echo " Saving TF key to Secret Manager "
echo "#################################"

gcloud secrets create GOOGLE_CREDENTIALS \
    --replication-policy="automatic"

gcloud secrets versions add GOOGLE_CREDENTIALS --data-file="./terraform-sa.json"



# Create Terraform Triggers 
echo "###########################"
echo " Create Terraform Triggers "
echo "###########################"

gcloud beta builds triggers create github \
    --repo-name=$REPO_NAME \
    --repo-owner=$REPO_OWNER \
    --branch-pattern=".*" \
    --build-config=cloudbuild_triggers/tf_plan.yaml \
    --name tf-plan

gcloud beta builds triggers create github \
    --repo-name=$REPO_NAME \
    --repo-owner=$REPO_OWNER \
    --pull-request-pattern=$BRANCH_PATTERN \
    --build-config=cloudbuild_triggers/tf_pr.yaml \
    --name tf-pr

gcloud beta builds triggers create github \
    --repo-name=$REPO_NAME \
    --repo-owner=$REPO_OWNER \
    --pull-request-pattern=$BRANCH_PATTERN \
    --require-approval \
    --build-config=cloudbuild_triggers/tf_apply.yaml \
    --name tf-apply

gcloud beta builds triggers create github \
    --repo-name=$REPO_NAME \
    --repo-owner=$REPO_OWNER \
    --pull-request-pattern=$BRANCH_PATTERN \
    --require-approval \
    --build-config=cloudbuild_triggers/tf_destroy.yaml \
    --name tf-destroy


# Build and push Ghost Image to GCR
echo "############################"
echo " Building and Pushing Image "
echo "############################"

gcloud builds submit --config cloudbuild.yaml .
