# Introduction
This repository has a collection of scripts to make creating a CA easier.

# Overview
Using openssl, the following scripts chain some commands together to make
configuring a CA of your own easier.
- create_ca.sh
- create_server_cert.sh
- create_crl.sh

The CA data is stored in a directory called `cas` which is created by the
`create_ca.sh` script.

Edit the templates below to suit your needs.
- root_config.template.cnf
- intermediate_config.template.cnf

They will become the openssl configuration files. They each have lines for
CRL and OCSP revocation options. The strings `REPLACE_ME__MY_CRL_URI` and
`REPLACE_ME__MY_OCSP_URI` will be replaced by the script automatically with
a default URIs of `<root|intermediate>.<ca-domain>/crls/crl.pem` and
`<root|intermediate>.<ca-domain>/ocsp` respectively.
