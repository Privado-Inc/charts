#!/bin/bash

BASE_PATH=$(pwd)
ENTERPRISE_CONF_FILE=$BASE_PATH/code-analysis/values.yaml

echo "Please enter host name for the server ...."
echo "ex. privado.company.com "
read applicationHostName
if [[ "$applicationHostName" == "http"* ]]; then
echo "Please remove http/https from host name"
exit 1
fi


sed -i -e "s/_CUSTOMER_HOST_NAME_/$applicationHostName/g" $ENTERPRISE_CONF_FILE

source ssoInput.sh $ENTERPRISE_CONF_FILE


echo "creating secret to encrypt mongo db" 
secret=$(openssl rand -base64 32)
sed -i -e "s#_CUSTOMER_MONGO_ENCRYPTION_KEY_#$secret#g" $ENTERPRISE_CONF_FILE

echo "Secret created successfully."
echo "Please copy the secret below to a secure location. The secret is also replaced in values.yaml at mongo.encryptionSecret.MONGO_ENCRYPTION_KEY."
echo '--------------------'
echo $secret
echo '--------------------'
echo "This secret is used to encrypt the database, and its loss or modification or deletion will render the database unusable."
while true; do
    read -p "Did you save the secret ? (y/n): " yn
    case $yn in
        [Yy]* ) break;;
        * ) echo "Please save the secret";;
    esac
done

source email.sh $ENTERPRISE_CONF_FILE
