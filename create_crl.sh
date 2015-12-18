#/bin/bash
set -e

function display_usage() {
    echo -e "Creates or recreates the crl for the CA in the given path."
    echo -e "\nUsage:\n$0 <ca_path>\n"
}

COLOR_YELLOW=$(tput setaf 3)
TEXT_RESET=$(tput sgr0)
function info() {
    printf "$COLOR_YELLOW*** $1$TEXT_RESET\n\n"
}

##
## Start Execution
##

if [[ $# -le 0 ]]
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

##################
#   Create CRL   #
##################

# setup
CA_DIR=$1

if [[ ! -f $CA_DIR/openssl.cnf ]]
then
    info "Did not find an openssl.cnf in $CA_DIR ... Exiting."
    exit 1
fi

if [[ ! -d $CA_DIR/crl ]]
then
    info "Did not find a crl directory in $CA_DIR ... Exiting."
    exit 1
fi

info "Creating crl in $CA_DIR/crl/crl.pem. You will be prompted for a passphrase."
openssl ca -config $CA_DIR/openssl.cnf -gencrl -out $CA_DIR/crl/crl.pem
