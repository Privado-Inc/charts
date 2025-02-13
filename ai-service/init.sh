#!/bin/bash

# Function to prompt the user for input with a default value
prompt() {
  local prompt_text=$1
  local default_value=$2
  read -p "$prompt_text ($default_value): " input
  echo "${input:-$default_value}"
}

# File to update
BASE_PATH=$(pwd)
ai_values_file=$BASE_PATH/values.yaml

# Prompt the user for each value
cluster_domain=$(prompt "Enter the cluster domain" "cluster.local")
use_ecr=$(prompt "Use Privado ECR to pull container images? (true/false)" "true")
node_instance_type=$(prompt "Enter the GPU node instance type" "g5.xlarge")
storage_class=$(prompt "Enter the storage class name that supports RWX" "efs-sc")
enable_autoupdates=$(prompt "Enable auto-updates cronjob? (true/false)" "false")
hf_access_token=$(prompt "Enter the Huggingface access token (provided by privado)" "None")

if [[ "$use_ecr" == "false" ]]; then
  echo "Using Privado ECR is disabled. This requires pre-emptively copying service images to a private repository."
  ai_service_image_repo_url=$(prompt "Enter the AI Service image repository URL" "None")
  secret_access_key_id=""
  secret_access_key=""
else
  ai_service_image_repo_url="638117407428.dkr.ecr.eu-west-1.amazonaws.com/ai-service-on-premise"
  secret_access_key_id=$(prompt "Enter the AWS Secret Access Key ID (required if useECR:true)" "None")
  secret_access_key=$(prompt "Enter the AWS Secret Access Key (required if useECR:true)" "None")
fi
# Update the values.yaml file
sed -i.bak -e "s|useECR: true  # NEEDS-CUSTOMER-INPUT|useECR: $use_ecr|" \
  -e "s/__CLUSTER_DOMAIN__/$cluster_domain/" \
  -e "s/__AWS_ACCESS_KEY_ID__/$secret_access_key_id/" \
  -e "s/__AWS_SECRET_ACCESS_KEY__/$secret_access_key/" \
  -e "s/node.kubernetes.io\/instance-type: .*/node.kubernetes.io\/instance-type: $node_instance_type/" \
  -e "s/storageClassName: gp2 # NEEDS-CUSTOMER-INPUT.*/storageClassName: $storage_class # NEEDS-CUSTOMER-INPUT/" \
  -e "s|autoUpdateEnabled: false  # NEEDS-CUSTOMER-INPUT|autoUpdateEnabled: $enable_autoupdates # NEEDS-CUSTOMER-INPUT|" \
  -e "s|638117407428.dkr.ecr.eu-west-1.amazonaws.com/ai-service-on-premise|$ai_service_image_repo_url|" \
  -e "s|HF_ACCESS_TOKEN_PLACEHOLDER|$hf_access_token|" \
  "$ai_values_file"

echo "$ai_values_file has been updated with the provided values."
