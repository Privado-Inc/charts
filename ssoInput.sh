#!/bin/bash

#arguments
ENTERPRISE_CONF_FILE="$1"


# Variable to store user's responses
use_sso=false
okta_client_id=""
okta_domain=""
super_admin_email=""

prompt_yes_no() {
    while true; do
        read -p "$1 (y/n): " yn
        case $yn in
            [Yy]* ) return 0;;
            [Nn]* ) return 1;;
            * ) echo "Please answer yes or no.";;
        esac
    done
}

prompt_okta_azure() {
    while true; do
        read -p "$1 (okta/azure): " yn
        case $yn in
            [oO][kK][tT][aA]* ) echo "okta"; return;;
            [aA][zZ][uU][rR][eE]* ) echo "azure"; return;;
            * )
        esac
    done
}

validate_okta_client_id() {
    local client_id=$1
    if [[ ${#client_id} -lt 5 ]] || [[ ! $client_id =~ ^[[:alnum:]-]+$ ]]; then
        echo "Invalid Okta Client ID. It should be at least 5 characters long, alphanumeric, and may include hyphens."
        return 1
    fi
    return 0
}

validate_okta_domain() {
    local domain=$1
    if [[ ! $domain =~ ^http ]]; then
        echo "Invalid Okta Domain. It should start with 'http'."
        return 1
    fi
    if [[ $domain =~ /$ ]]; then
        echo "Invalid Okta Domain. It should not have a trailing slash."
        return 1
    fi
    return 0
}

validate_email() {
    local email=$1
    if [[ ! $email =~ ^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$ ]]; then
        echo "Invalid email address."
        return 1
    fi
    return 0
}

if prompt_yes_no "Does your company use either Okta or Azure for Identity and Access Management?"; then
    use_sso=true
    ssoType=$(prompt_okta_azure "Which Identity and Access Management (IAM) system does your company use, okta or azure?")
    echo "Selected IAM system: $ssoType"

    if [ "$ssoType" = "okta" ]; then
        if prompt_yes_no "Do you have the Okta Domain and Okta Client ID?"; then
            while true; do
                read -p "Please enter your Okta Client ID: " okta_client_id
                okta_client_id=$(echo "$okta_client_id" | awk '{$1=$1};1') # Trim leading/trailing spaces
                validate_okta_client_id "$okta_client_id" && break
            done
            
            while true; do
                read -p "Please enter your Okta Domain (e.g., http://your-okta-domain.com): " okta_domain
                okta_domain=$(echo "$okta_domain" | awk '{$1=$1};1') # Trim leading/trailing spaces
                validate_okta_domain "$okta_domain" && break
            done

            while true; do
                read -p "Please provide the employee email who is going to be the Super Admin for the Privado application: " super_admin_email
                super_admin_email=$(echo "$super_admin_email" | awk '{$1=$1};1') # Trim leading/trailing spaces
                if validate_email "$super_admin_email"; then
                    break
                fi
            done
        else
            echo "Please contact your Azure admin to create a custom application in Azure Console by following the document provided by us."
            exit 0
        fi
    elif [ "$ssoType" = "azure" ]; then
        if prompt_yes_no "Do you have the Azure Client ID?"; then
            while true; do
                read -p "Please enter your Azure Client ID: " okta_client_id
                okta_client_id=$(echo "$okta_client_id" | awk '{$1=$1};1') # Trim leading/trailing spaces
                validate_okta_client_id "$okta_client_id" && break
            done
            okta_domain="https://login.microsoftonline.com/common/v2.0"

            while true; do
                read -p "Please provide the employee email who is going to be the Super Admin for the Privado application: " super_admin_email
                super_admin_email=$(echo "$super_admin_email" | awk '{$1=$1};1') # Trim leading/trailing spaces
                if validate_email "$super_admin_email"; then
                    break
                fi
            done
        else
            echo "Please contact your Okta admin to create a custom application in Okta by following the document provided by us."
            exit 0
        fi
    else
        exit 0
    fi
fi

if [ "$use_sso" = true ]; then
    echo ""
    echo "SSO Client ID: $okta_client_id"
    echo "SSO Domain: $okta_domain"
    echo "Super Admin User Email: $super_admin_email"

    sed -i -e "s/__OKTA_ENABLED__/$use_sso/g" $ENTERPRISE_CONF_FILE
    sed -i -e "s#__CUSTOMER_SSO_DOMAIN__#$okta_domain#g" $ENTERPRISE_CONF_FILE
    sed -i -e "s/__CUSTOMER_SSO_CLIENT_ID__/$okta_client_id/g" $ENTERPRISE_CONF_FILE
    sed -i -e "s/__CUSTOMER_SSO_TYPE__/$ssoType/g" $ENTERPRISE_CONF_FILE
    sed -i -e "s/__CUSTOMER_OKTA_SUPER_ADMIN__/$super_admin_email/g" $ENTERPRISE_CONF_FILE
fi
