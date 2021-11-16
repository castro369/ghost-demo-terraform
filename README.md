# ghost-demo

## Requirements
- Google Cloud SDK
- Google Cloud Project
- Google Authentication to Project 
- Terraform installed on local machine
- GitHub Account and two Repositories

Connect both Terraform and CI/CD repos https://console.cloud.google.com/cloud-build/repos?  


## Assign ENV variables
export REPO_NAME=(Name of Terraform GitHub Repo) - (E.g. ghost-demo-terraform)
export REPO_OWNER=(Name of Repo Owner) - (E.g. antoniocauk)
export BRANCH_PATTERN=(Pattern of branch) - (E.g. ^main$)


## Clone the repository
git clone https://github.com/antoniocauk/ghost-demo-terraform.git

## Push code into your own repo

## Run Bootstrap
chmod +x ./bootstrap.sh
Run "bootstrap.sh" to create terraform service account and its JSON key. Enable needed APIs for Terraform to function. 

## Run Terraform
The Terraform code will create the following resources:
- Networks and Subnetworks
- Cloud SQL
- Secret Manager and Secrets
- Ghost Image in GCR
- Cloud Run
- Load Balancer
- Cloud Build Triggers

When the terraform finishes, the cloud build triggers can be found in the CLoud Build page. These were created to be triggered on Pull Requests.

https://console.cloud.google.com/cloud-build/triggers?


## Helpful commands while building the Ghost Image If you wish to run the code locally 
### Build Image Locally and push to Google Container Registry 
gcloud builds submit --config cloudbuild.yaml .

## Run Docker container locally and connect to external MySQL instance
docker build -t ghost --build-arg DB_HOST=$DB_HOST --build-arg DB_PORT=$DB_PORT --build-arg DB_USER=$DB_USER --build-arg DB_PASS=$DB_PASS --build-arg DB_NAME=$DB_NAME .  

## Extra Info
All the values found in Secret Manager are default and should be cahnged and adjusted to each environment. The same applies to the .tfvars file in the terraform folder.






database__client
mysql
database__connection__user
ghost
database__connection__password
123qwe
database__connection__database
ghost
database__connection__socketPath
/cloudsql/drone-shuttles-ghost-dev:europe-west1:ghost-db-18a5f692
url
http://localhost:2368




DB_CLIENT
DB_USER
DB_PASS
DB_NAME
DB_CON
URL