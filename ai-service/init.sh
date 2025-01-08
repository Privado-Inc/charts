#!/bin/bash

# Function to prompt the user for input with a default value
prompt() {
  local var_name=$1
  local prompt_text=$2
  local default_value=$3
  read -p "$prompt_text ($default_value): " input
  echo "${input:-$default_value}"
}

# File to update
values_file="values.yaml"

# Prompt the user for each value
ai_service_andromeda_host=$(prompt "AI_SERVICE_ANDROMEDA_HOST" "Enter the AI Service Andromeda Host URL" "http://andromeda-service.privado.svc.cluster.local:6001")
chroma_host=$(prompt "CHROMA_HOST" "Enter the Chroma Host (without 'http://' prefix)" "ai-service-chroma-chromadb.privado.svc.cluster.local")
use_ecr=$(prompt "Use ECR to pull AiService container image? (true/false)" "false")
secret_access_key_id=$(prompt "secretAccessKeyId" "Enter the AWS Secret Access Key ID (required if useECR:true)" "None")
secret_access_key=$(prompt "secretAccessKey" "Enter the AWS Secret Access Key (required if useECR:true)" "None")
node_instance_type=$(prompt "node.kubernetes.io/instance-type" "Enter the node instance type" "g5.xlarge")
models_storage_class=$(prompt "aiServiceModelsPvc.storageClassName" "Enter the storage class name for models PVC" "gp2")
log_storage_class=$(prompt "aiServiceLogPvc.storageClassName" "Enter the storage class name for log PVC" "gp2")
enable_autoupdates=$(prompt "Enable auto-updates cronjob? (true/false)" "false")
hf_access_token=$(prompt "Enter the Huggingface access token (provided by privado)" "None")


# Update the values.yaml file
sed -i.bak -e "s/secretAccessKeyId: .*/secretAccessKeyId: \"$secret_access_key_id\"/" \
           -e "s/secretAccessKey: .*/secretAccessKey: \"$secret_access_key\"/" \
           -e "s/node.kubernetes.io\/instance-type: .*/node.kubernetes.io\/instance-type: $node_instance_type/" \
           -e "s/storageClassName: gp2 # NEEDS-CUSTOMER-INPUT.*/storageClassName: $models_storage_class # NEEDS-CUSTOMER-INPUT/" \
           -e "s/storageClassName: gp2 # NEEDS-CUSTOMER-INPUT.*/storageClassName: $log_storage_class # NEEDS-CUSTOMER-INPUT/" \
           -e "s|value: \"http://andromeda-service.privado.svc.cluster.local:6001\" # NEEDS-CUSTOMER-INPUT|value: \"$ai_service_andromeda_host\" # NEEDS-CUSTOMER-INPUT|" \
           -e "s|value: \"ai-service-chroma-chromadb.privado.svc.cluster.local\"  # NEEDS-CUSTOMER-INPUT \[without 'http://'\ prefix\]|value: \"$chroma_host\"  # NEEDS-CUSTOMER-INPUT \[without 'http://'\ prefix\]|" \
           -e "s|autoUpdateEnabled: false  # NEEDS-CUSTOMER-INPUT|autoUpdateEnabled: $enable_autoupdates # NEEDS-CUSTOMER-INPUT|" \
           -e "s|HF_ACCESS_TOKEN_PLACEHOLDER|$hf_access_token|" \
           -e "s|useECR: false  # NEEDS-CUSTOMER-INPUT|useECR: $use_ecr|" \
           "$values_file"

echo "values.yaml has been updated with the provided values."