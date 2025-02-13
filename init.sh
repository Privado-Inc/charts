#!/bin/bash

# Function to prompt the user for input with a default value
prompt() {
  local prompt_text=$1
  local default_value=$2
  read -p "$prompt_text ($default_value): " input
  echo "${input:-$default_value}"
}

# Function to validate non-empty input
validate_non_empty() {
  local input=$1
  local error_message=$2
  if [[ -z "$input" || "$input" == "None" ]]; then
    echo "$error_message"
    exit 1
  fi
}

# File to update
BASE_PATH=$(pwd)
values_file=$BASE_PATH/code-analysis/values.yaml

# Prompt the user for each value
customer_host_name=$(prompt "Enter the host name for Privado dashboard (example: privado.customer.com)" "None")
validate_non_empty "$customer_host_name" "Host name cannot be empty."
if [[ "$customer_host_name" == "http"* ]]; then
  echo "Please remove http/https from host name"
  exit 1
fi

andro_cluster_domain=$(prompt "Enter the cluster domain for code-analysis module" "cluster.local")
validate_non_empty "$andro_cluster_domain" "code-analysis module cluster domain cannot be empty."

ai_cluster_domain=$(prompt "Enter the cluster domain for ai-service module" "$andro_cluster_domain")
validate_non_empty "$ai_cluster_domain" "ai-service module cluster domain cannot be empty."

andro_k8s_namespace=$(prompt "Enter the k8s namespace for the deployment" "default")
validate_non_empty "$andro_k8s_namespace" "code-analysis module namespace cannot be empty."

ai_k8s_namespace=$(prompt "Enter the k8s namespace for the deployment" "$andro_k8s_namespace")
validate_non_empty "$ai_k8s_namespace" "ai-service module namespace cannot be empty."

andromeda_storage_class=$(prompt "Enter the storage class name that supports RWX access mode" "None")
validate_non_empty "$andromeda_storage_class" "Storage class name for RWX access mode cannot be empty."

mongo_storage_class=$(prompt "Enter the storage class name that supports RWO access mode" "gp2")
validate_non_empty "$mongo_storage_class" "Storage class name for RWO access mode cannot be empty."

ingress_class_name=$(prompt "Enter the ingress class name" "alb")
validate_non_empty "$ingress_class_name" "Ingress class name cannot be empty."

ai_enabled=$(prompt "Enable AI Service? (true/false)" "false")
enable_auto_updates=$(prompt "Enable auto-updates cronjob? (true/false)" "true")
enable_mastervendor=$(prompt "Enable Master Vendor? (true/false)" "false")

mongo_username=$(prompt "Enter the MongoDB username" "None")
validate_non_empty "$mongo_username" "MongoDB username cannot be empty."

mongo_password=$(prompt "Enter the MongoDB password" "None")
validate_non_empty "$mongo_password" "MongoDB password cannot be empty."

use_privado_registry=$(prompt "Use Privado ECR to pull container images? (true/false)" "true")
if [[ "$use_privado_registry" == "false" ]]; then
  echo "Using Privado ECR is disabled. This requires pre-emptively copying service images to a private repository."
  echo "Please provide the repository URLs as asked below."
  andromeda_image_repo_url=$(prompt "Enter the Andromeda image repository URL" "None")
  validate_non_empty "$andromeda_image_repo_url" "Andromeda image repository URL cannot be empty."
  bishamonten_image_repo_url=$(prompt "Enter the Bishamonten image repository URL" "None")
  validate_non_empty "$bishamonten_image_repo_url" "Bishamonten image repository URL cannot be empty."
  ai_service_image_repo_url=$(prompt "Enter the AI Service image repository URL" "None")
  validate_non_empty "$ai_service_image_repo_url" "AI Service image repository URL cannot be empty."
  if [[ "$enable_mastervendor" == "true" ]]; then
    mastervendor_repo_url=$(prompt "Enter the Mastervendor image repository URL" "None")
    validate_non_empty "$mastervendor_repo_url" "Mastervendor image repository URL cannot be empty."
  fi
  secret_access_key_id=""
  secret_access_key=""
  echo "Access credentials will not be configured in scope of this initialization. Review the values.yaml files to configure them manually."
else
  andromeda_image_repo_url="638117407428.dkr.ecr.eu-west-1.amazonaws.com/andromeda"
  bishamonten_image_repo_url="638117407428.dkr.ecr.eu-west-1.amazonaws.com/bishamonten"
  ai_service_image_repo_url="638117407428.dkr.ecr.eu-west-1.amazonaws.com/ai-service-on-premise"
  mastervendor_repo_url="638117407428.dkr.ecr.eu-west-1.amazonaws.com/master-vendor-base-image"
  secret_access_key_id=$(prompt "Enter the AWS Secret Access Key ID (required since useECR:true)" "None")
  validate_non_empty "$secret_access_key_id" "AWS Secret Access Key ID cannot be empty."
  secret_access_key=$(prompt "Enter the AWS Secret Access Key (required since useECR:true)" "None")
  validate_non_empty "$secret_access_key" "AWS Secret Access Key cannot be empty."
fi

# Update the values.yaml file
sed -i.bak -e "s|_CUSTOMER_HOST_NAME_|$customer_host_name|" \
  -e "s|__AWS_ACCESS_KEY_ID__|$secret_access_key_id|" \
  -e "s|__AWS_SECRET_ACCESS_KEY__|$secret_access_key|" \
  -e "s|clusterDomain: .*|clusterDomain: $andro_cluster_domain|" \
  -e "s|__AI_CLUSTER_DOMAIN__|$ai_cluster_domain|" \
  -e "s|__AI_NAMESPACE__|$ai_k8s_namespace|" \
  -e "s|storageClass: .* support RWX|storageClass: $andromeda_storage_class |" \
  -e "s|storageClass: .* # NEEDS-CUSTOMER-INPUT|storageClass: $mongo_storage_class |" \
  -e "s|ingressClassName: .* # NEEDS-CUSTOMER-INPUT|ingressClassName: $ingress_class_name |" \
  -e "s|CONFIG_AI_SERVICE_AVAILABLE: \"false\"|CONFIG_AI_SERVICE_AVAILABLE: \"$ai_enabled\" |" \
  -e "s|enable: true  # NEEDS-CUSTOMER-INPUT use_privado_registry|enable: $use_privado_registry|" \
  -e "s|enable: true  # NEEDS-CUSTOMER-INPUT enable_auto_updates|enable: $enable_auto_updates|" \
  -e "s|name: \"638117407428.dkr.ecr.*.amazonaws.com/andromeda\"|name: \"$andromeda_image_repo_url\"|" \
  -e "s|name: \"638117407428.dkr.ecr.*.amazonaws.com/bishamonten\"|name: \"$bishamonten_image_repo_url\"|" \
  -e "s|enable: false  # NEEDS-CUSTOMER-INPUT enable_master_vendor|enable: $enable_mastervendor|" \
  -e "s|MONGO_INITDB_ROOT_USERNAME: .*|MONGO_INITDB_ROOT_USERNAME: \"$mongo_username\"|" \
  -e "s|MONGO_INITDB_ROOT_PASSWORD: .*|MONGO_INITDB_ROOT_PASSWORD: \"$mongo_password\"|" \
  -e "s|_PSW: \"\"|_PSW: \"$mongo_password\"|" \
  "$values_file"

echo "$values_file has been updated with the provided values."
echo "Moving on to SSO configuration..."

configure_sso=$(prompt "Configure SSO? (true/false)" "false")
if [[ "$configure_sso" == "true" ]]; then
  echo "Configuring SSO"
  source ssoInput.sh "$values_file"
  echo "SSO configuration is done."
fi

echo "Creating an encryption secret for Mongo DB"
secret=$(openssl rand -base64 32)
sed -i -e "s#_CUSTOMER_MONGO_ENCRYPTION_KEY_#$secret#g" "$values_file"

echo "Secret created successfully."
echo "Please copy the secret below to a secure location."
echo "The secret is also placed in $values_file at mongo.encryptionSecret.MONGO_ENCRYPTION_KEY."
echo '--------------------'
echo "$secret"
echo '--------------------'
echo "This secret is used to encrypt the database, and its loss or modification or deletion will render the database unusable."
while true; do
  read -p "Did you save the secret ? (y/n): " yn
  case $yn in
  [Yy]*) break ;;
  *) echo "Please save the secret" ;;
  esac
done

configure_email_host=$(prompt "Configure email host? (true/false)" "false")
if [[ "$configure_email_host" == "true" ]]; then
  echo "Configuring Email host"
  source email.sh "$values_file"
  echo "Email host configuration is done."
fi

echo "Code Analysis Service configuration is done."
if [[ "$ai_enabled" == "false" ]]; then
  echo "AI Service is not enabled. Exiting..."
  exit 0
fi
echo "Moving on to AI Service configuration..."
ai_values_file=$BASE_PATH/ai-service/values.yaml

# Prompt the user for each value
node_instance_type=$(prompt "Enter the GPU node instance type" "g5.xlarge")
storage_class=$(prompt "Enter the storage class name that supports RWX" "efs-sc")
enable_autoupdates=$(prompt "Enable auto-updates cronjob? (true/false)" "false")
hf_access_token=$(prompt "Enter the Huggingface access token (provided by privado)" "None")
validate_non_empty "$hf_access_token" "Huggingface access token cannot be empty."

# Update the ai-service/values.yaml file
sed -i.bak -e "s|useECR: true  # NEEDS-CUSTOMER-INPUT|useECR: $use_privado_registry|" \
  -e "s/__ANDRO_CLUSTER_DOMAIN__/$andro_cluster_domain/" \
  -e "s|__ANDRO_NAMESPACE__|$andro_k8s_namespace|" \
  -e "s/__AI_CLUSTER_DOMAIN__/$ai_cluster_domain/" \
  -e "s|__AI_NAMESPACE__|$ai_k8s_namespace|" \
  -e "s/__AWS_ACCESS_KEY_ID__/$secret_access_key_id/" \
  -e "s/__AWS_SECRET_ACCESS_KEY__/$secret_access_key/" \
  -e "s/node.kubernetes.io\/instance-type: .*/node.kubernetes.io\/instance-type: $node_instance_type/" \
  -e "s/storageClassName: efs-sc # NEEDS-CUSTOMER-INPUT.*/storageClassName: $storage_class # NEEDS-CUSTOMER-INPUT/" \
  -e "s|autoUpdateEnabled: false  # NEEDS-CUSTOMER-INPUT|autoUpdateEnabled: $enable_autoupdates # NEEDS-CUSTOMER-INPUT|" \
  -e "s|638117407428.dkr.ecr.eu-west-1.amazonaws.com/ai-service-on-premise|$ai_service_image_repo_url|" \
  -e "s|HF_ACCESS_TOKEN_PLACEHOLDER|$hf_access_token|" \
  "$ai_values_file"

echo "$ai_values_file has been updated with the provided values."
