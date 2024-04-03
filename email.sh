#!/bin/bash

#arguments
ENTERPRISE_CONF_FILE="$1"

# Function to read a specific value from the conf file
get_conf_value() {
    local key="$1"
    local value=$(grep "^$key" "$ENTERPRISE_CONF_FILE" | awk -F '=' '{print $2}' | tr -d '"')
    echo "$value"
}

# Read specific values from the conf file
hasInternetDisabled=$(get_conf_value "HAS_NO_INTERNET_CONNECTION")

# Check if hasInternetDisabled is "false" and exit the script
if [[ "$hasInternetDisabled" == "false" ]]; then
    return
fi

# Prompt the user for input
read -p "Enter emailHost (e.g., example.yourdomain.com): " emailHost
while [[ -z "$emailHost" ]]; do
    echo "Email host cannot be empty. Please provide a valid email host."
    read -p "Enter emailHost (e.g., example.yourdomain.com): " emailHost
done

read -p "Enter emailPort (587 for TLS, 465 for SSL, or 25 for non-encrypted): " emailPort
while [[ -z "$emailPort" ]]; do
    echo "Email port cannot be empty. Please provide a valid email port."
    read -p "Enter emailPort (587 for TLS, 465 for SSL, or 25 for non-encrypted): " emailPort
done

while true; do
    read -p "SSL Mode Supported (0 for no, 1 for yes): " useSSL
    if [[ "$useSSL" == "0" || "$useSSL" == "1" ]]; then
        break
    else
        echo "Invalid input. Please enter 0 for no or 1 for yes."
    fi
done


if [[ "$useSSL" == "1" ]]; then
    echo "SSL mode is selected. SSL certificate and key paths are not mandatory."
    read -p "Enter SSL Certificate absolute Path (empty): " sslCertificate
    read -p "Enter SSL Key absolute Path (empty): " sslKeyFile
    useTLS="0"  # Disable TLS if SSL is enabled
else
    while true; do
        read -p "TLS Mode Supported (0 for no, 1 for yes): " useTLS
        if [[ "$useSSL" == "0" || "$useSSL" == "1" ]]; then
            break
        else
            echo "Invalid input. Please enter 0 for no or 1 for yes."
        fi
    done
fi

read -p "Enter username: " username
read -p "Enter password: " -s password
echo

read -p "Provide a source email  (e.g., yourname@example.com): " emailFrom
while [[ -z "$emailFrom" ]]; do
    echo "Source Email address cannot be empty. Please provide a valid email address."
    read -p "Provide a source email (e.g., yourname@example.com): " emailFrom
done

# This can uncomment if they want to specific their support
# read -p "Enter supportEmail (e.g., support@privado.ai): " supportEmail
# while [[ -z "$supportEmail" ]]; do
#     echo "You can leave this to privado support"
#     read -p "Enter supportEmail (e.g., support@privado.ai): " supportEmail
# done

supportEmail="support@privado.ai"
# Print entered values to confirm to the user
echo "==============================="
echo "Entered values:"
echo "Email Host: $emailHost"
echo "Email Port: $emailPort"
echo "SSL Supported: $useSSL"
echo "TLS Supported: $useTLS"
echo "Username: $username"
echo "Password: $password"
echo "Email From: $emailFrom"
echo "Support Email: $supportEmail"
if [[ "$useSSL" == "1" ]]; then
    echo "SSL Certificate Path: $sslCertificate"
    echo "SSL Key Path: $sslKeyFile"
fi
echo "==============================="

sed -i -e "s/__EMAIL_HOST__/$emailHost/g" $ENTERPRISE_CONF_FILE
sed -i -e "s#__EMAIL_PORT__#$emailPort#g" $ENTERPRISE_CONF_FILE
sed -i -e "s/__EMAIL_USE_TLS__/$useTLS/g" $ENTERPRISE_CONF_FILE
sed -i -e "s/__EMAIL_USE_SSL__/$useSSL/g" $ENTERPRISE_CONF_FILE
sed -i -e "s/__EMAIL_HOST_USER__/$username/g" $ENTERPRISE_CONF_FILE
sed -i -e "s/__EMAIL_HOST_PASSWORD__/$password/g" $ENTERPRISE_CONF_FILE
sed -i -e "s/__EMAIL_EMAIL_FROM__/$emailFrom/g" $ENTERPRISE_CONF_FILE
sed -i -e "s/__EMAIL_EMAIL_SUPPORT__/$supportEmail/g" $ENTERPRISE_CONF_FILE
sed -i -e "s#__EMAIL_SSL_CERT__#$sslCertificate#g" $ENTERPRISE_CONF_FILE
sed -i -e "s#__EMAIL_SSL_KEY__#$sslKeyFile#g" $ENTERPRISE_CONF_FILE
