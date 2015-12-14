#!/bin/bash
set -e

function display_usage() {
    echo -e "Creates a server certificate signed by the given root CA's intermediate certificate"
    echo -e "\nUsage:\n$0 <ca_name> <server_name>\n"
}

COLOR_YELLOW=$(tput setaf 3)
TEXT_RESET=$(tput sgr0)
function info() {
    printf "$COLOR_YELLOW*** $1$TEXT_RESET\n\n"
}

##
## Start Execution
##

if [[ $# -le 1 ]]
then
    display_usage
    exit 1
fi

# check whether user had supplied -h or --help . If yes display usage
if [[ ( $# == "--help") || $# == "-h" ]]
then
    display_usage
    exit 0
fi
#####################
#    Server Cert    #
#####################

# setup
ROOT_DIR=`pwd`/cas/$1
INTERMEDIATE_DIR=$ROOT_DIR/intermediate
SERVER_NAME=$2
info "Creating a server certificate for $SERVER_NAME under the intermediate CA at $INTERMEDIATE_DIR"
cd $INTERMEDIATE_DIR

# create key
info "Creating the server's private key. You'll be prompted to create a passphrase."
openssl genrsa -aes256 -out private/$SERVER_NAME.key.pem 2048
chmod 400 private/$SERVER_NAME.key.pem

# create csr
info "Creating the server's csr to be signed. You'll be prompted for it's passphrase and subject information."
openssl req -config openssl.cnf -key private/$SERVER_NAME.key.pem \
	-new -sha256 -out csr/$SERVER_NAME.csr.pem

# signing the csr
info "Signing the server's cert. You'll be prompted for the intermediate passphrase and to verify the server's information."
openssl ca -config openssl.cnf -extensions server_cert -notext \
	-in csr/$SERVER_NAME.csr.pem \
	-out certs/$SERVER_NAME.cert.pem
chmod 444 certs/$SERVER_NAME.cert.pem

# verify the cert
info "Verifying your server cert's validity."
openssl verify -CAfile $INTERMEDIATE_DIR/certs/intermediate-chain.cert.pem \
	$INTERMEDIATE_DIR/certs/$SERVER_NAME.cert.pem

read -p "$COLOR_YELLOW*** Would you like to manually verify the server's certificate? [Y/n]: $TEXT_RESET" verify

if [[ $verify != 'n' ]]
then
    openssl x509 -noout -text -in certs/$SERVER_NAME.cert.pem | less
    read -p "$COLOR_YELLOW*** Did everything look correct? [Y/n]: $TEXT_RESET" correct

    if [[ $correct == 'n' ]]
    then
	info "Revoking this certificate. You'll be prompted for the intermediate passphrase"
	openssl ca -config openssl.cnf \
		-revoke certs/$SERVER_NAME.cert.pem
	info "Recreating CRL. You'll be prompted for the intermediate passphrase."
	openssl ca -config openssl.cnf -gencrl \
		-out crl/intermediate.crl.pem
	info "Removing files..."
	rm -f private/$SERVER_NAME.key.pem csr/$SERVER_NAME.csr.pem certs/$SERVER_NAME.cert.pem
	exit 1
    fi
fi

info "Server certificate created at $INTERMEDIATE_DIR/certs/$SERVER_NAME.cert.pem"
