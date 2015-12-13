#!/bin/bash
set -e

function display_usage() {
    echo -e "Creates a CA with a root and an intermediate certificate"
    echo -e "\nUsage:\n$0 <name> <crl_uri> <ocsp_uri>\n"
}

# Function that replaces a template config with the appropriate values
# $1 : the template file to use
# $2 : the location of the ca dir
# $3 : the crl uri
# $4 : the ocsp uri
function replace_config() {
sed s%REPLACE_ME__MY_CA_DIR%$2% $1 | \
    sed s%REPLACE_ME__MY_CRL_URI%$3% | \
    sed s%REPLACE_ME__MY_OCSP_URI%$4% > openssl.cnf
}

COLOR_YELLOW=$(tput setaf 3)
TEXT_RESET=$(tput sgr0)
function info() {
    printf "$COLOR_YELLOW*** $1$TEXT_RESET\n\n"
}

##
## Start Execution
##

if [[ $# -le 2 ]]
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
#     Root Cert     #
#####################

# setup ca directory
ROOT_DIR=`pwd`/cas/$1
info "Setting up directory for your root ca at $ROOT_DIR"
mkdir -p $ROOT_DIR
cd $ROOT_DIR
mkdir certs crl newcerts private
chmod 700 private
touch index.txt
echo 1000 > serial
echo 1000 > crlnumber

# add template root config
replace_config ../../root_config.template.cnf $ROOT_DIR $2 $3

# create root key
info "Creating your root key. You'll be prompted to create a passphrase for it."
openssl genrsa -aes256 -out private/root.key.pem 4096
chmod 400 private/root.key.pem

# create root cert
info "Creating your root certificate. You'll be prompted for the root key's passphrase and subject information for the root CA."
openssl req -config openssl.cnf \
	-key private/root.key.pem \
	-new -x509 -days 7300 -sha256 -extensions v3_ca \
	-out certs/root.cert.pem
chmod 444 certs/root.cert.pem

# verify root cert
read -p "$COLOR_YELLOW*** Would you like to verify the root certificate? [Y/n]: $TEXT_RESET" verify

if [[ $verify != 'n' ]]
then
    openssl x509 -noout -text -in certs/root.cert.pem | less
    read -p "$COLOR_YELLOW*** Did everything look correct? [Y/n]: $TEXT_RESET" correct

    if [[ $correct == 'n' ]]
    then
	info "Removing $ROOT_DIR"
	cd $ROOT_DIR/../..
	rm -rf $ROOT_DIR
	exit 1
    fi
fi

#####################
# Intermediate Cert #
#####################

# setup intermediate directory
INTERMEDIATE_DIR=$ROOT_DIR/intermediate
info "Setting up directory for your intermediate ca at $INTERMEDIATE_DIR"
mkdir -p $INTERMEDIATE_DIR
cd $INTERMEDIATE_DIR
mkdir certs crl csr newcerts private
chmod 700 private
touch index.txt
echo 1000 > serial
echo 1000 > crlnumber

# add template intermediate config
replace_config ../../../intermediate_config.template.cnf $INTERMEDIATE_DIR $2 $3

# create intermediate key
info "Creating your intermediate key. You'll be prompted to create a passphrase for it."
openssl genrsa -aes256 -out private/intermediate.key.pem 4096
chmod 400 private/intermediate.key.pem

# create intermediate csr
info "Creating your intermediate CSR. You'll be prompted for the intermediate key's passphrase and subject information for the intermediate CA."
openssl req -config openssl.cnf \
	-key private/intermediate.key.pem \
	-new -sha256 \
	-out csr/intermediate.csr.pem

# sign intermediate csr
info "Signing your intermediate CSR with the root CA. You'll be prompted for the root key's passphrase and asked to verify the intermediate's information."
openssl ca -config $ROOT_DIR/openssl.cnf -extensions v3_intermediate_ca \
	-days 3650 -notext -md sha256 \
	-in csr/intermediate.csr.pem \
	-out certs/intermediate.cert.pem
chmod 444 certs/intermediate.cert.pem

# verify intermediate cert
read -p "$COLOR_YELLOW*** Would you like to verify the intermediate certificate? [Y/n]: $TEXT_RESET" verify

if [[ $verify != 'n' ]]
then
    openssl x509 -noout -text -in certs/intermediate.cert.pem | less
    read -p "$COLOR_YELLOW*** Did everything look correct? [Y/n]: $TEXT_RESET" correct

    if [[ $correct == 'n' ]]
    then
	info "Removing $ROOT_DIR"
	cd $ROOT_DIR/../..
	rm -rf $ROOT_DIR
	exit 1
    fi
fi

info "Verifying your intermediate cert's validity."
openssl verify -CAfile $ROOT_DIR/certs/root.cert.pem \
	$INTERMEDIATE_DIR/certs/intermediate.cert.pem

# create intermediate cert chain
info "Creating intermediate ca cert chain at $INTERMEDIATE_DIR/certs/intermediate-chain.cert.pem"
cat $INTERMEDIATE_DIR/certs/intermediate.cert.pem $ROOT_DIR/certs/root.cert.pem > $INTERMEDIATE_DIR/certs/intermediate-chain.cert.pem
