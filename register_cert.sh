#! /bin/bash

if [ $1 = "-h" ]; then echo <<HELPTXT
usage: register_cert.sh <email> <domain>

Parameters:

- <email>: the email address with which to register with LetsEncrypt
- <domain>: the domain for which we are requesting a certificate
HELPTXT
exit 0
fi

if [ ! `command -v certbot` ]; then echo "certbot is not in your PATH"; exit -1; fi

echo "Registering $2 with LetsEncrypt using email address $1..."
mkdir -p "/var/www/$2-acme"
sudo certbot certonly --webroot -m $1 -d $2 -w "/var/www/$2-acme"
