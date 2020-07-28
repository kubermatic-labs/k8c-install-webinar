#!/usr/bin/env bash

# Download the Kubermatic tarball from the following link:
# https://github.com/kubermatic/kubermatic/releases/download/v2.14.3/kubermatic-ce-v2.14.3.tar.gz
#
# This script is intended to ease the deployment of a minimal Kubermatic
# Kubernetes Platform for demonstrative purposes.
# It is not intended for a production setup where it is recommended to
# follow the official documentation read and understand all the possible
# configuration options.
set -eo pipefail

log() {
    command echo $(date) "I: $@"
}

fatal(){
    echo $(date) "F: $@" >>/dev/stderr
    usage
}

function generate_secret {
    cat /dev/urandom | LC_ALL=C tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1; \
    echo ''
}

function usage {
    cat << EOF
Usage: $0 [-f root folder] [-k kubeconfig path] [-l [y/n]] [-d kubermatic domain]

Flags:
  -f, --folder='.': Folder where the kubermatic tarball has been extracted.
  -k, --kubeconfig: Path to the kubeconfig file of the Seed Kubernetes cluster.
  -d, --kubermatic-domain: Domain to be used for the Kubermatic Kubernetes platform installation
  -p, --letsencrypt-prod='n': Flag saying whether the production Let's Encrypt environment should be used.
When not specified or set to 'n' staging environment is used, if set to 'y' or specified withoug a value production environment is used instead.
EOF
    exit 1
}

function validate {
    [[ -r "${SEED_KUBECONFIG}" ]] || \
        fatal "Please provide a valid path to Seed kubeconfig. Given: ${SEED_KUBECONFIG}"
    if command -v kubectl > /dev/null; then
        kubectl --kubeconfig "${SEED_KUBECONFIG}" config current-context > /dev/null || \
                fatal "Please provide a valid Seed kubeconfig file: ${SEED_KUBECONFIG}"
    fi
    [[ -r "${ROOT_FOLDER}/examples/kubermatic.example.ce.yaml" && \
       -r "${ROOT_FOLDER}/examples/seed.example.yaml" && \
       -r "${ROOT_FOLDER}/examples/values.example.yaml" ]] || \
        fatal "Please provide a valid folder wher Kubermatic tarball was extracted"
    [[ "${DOMAIN}" =~ ^([a-z0-9]+(-[a-z0-9]+)*\.)+[a-z]{2,} ]] || \
        fatal "Please provide a valid domain name. Given: ${DOMAIN}"
}

ROOT_FOLDER="$(pwd)"
while [[ $# -gt 0 ]]
do
key="$1"

case $key in
    -h)
    usage
    ;;
    -f|--folder)
    ROOT_FOLDER="$2"
    shift # past argument
    shift # past value
    ;;
    -k|--kubeconfig)
    SEED_KUBECONFIG="$2"
    shift # past argument
    shift # past value
    ;;
    -p|--letsencrypt-prod)
    PROD_CERT="${2:-y}"
    shift # past argument
    [[ "$1" =~ "^-" ]] || shift # past value
    ;;
    -d|--kubermatic-domain)
    DOMAIN="$2"
    shift # past argument
    shift # past value
    ;;
    *)    # unknown option
    fatal "Unexpected argument: $1"
    ;;
esac
done

# Ask for Seed kubeconfig path if not given in input.
if [[ -z "${SEED_KUBECONFIG}" ]]; then
    read -e -p "Enter the path to the seed Kubeconfig file: " -r SEED_KUBECONFIG
fi
# Expand ~
SEED_KUBECONFIG="${SEED_KUBECONFIG/#\~/${HOME}}"
# Ask for domain if not given in input.
if [[ -z "${DOMAIN}" ]]; then
    read -e -p "Please provide the domain you want to use for Kubermatic: " -r DOMAIN
fi

validate

# Copy the template files
log "Copying template files from ${ROOT_FOLDER}/examples"
cp "${ROOT_FOLDER}/examples/seed.example.yaml" \
    "${ROOT_FOLDER}/seed.yaml"
cp "${ROOT_FOLDER}/examples/kubermatic.example.ce.yaml" \
    "${ROOT_FOLDER}/kubermatic.yaml"
cp "${ROOT_FOLDER}/examples/values.example.yaml" \
    "${ROOT_FOLDER}/values.yaml"

# Generate Oauth secret and replace it in templates
log "Setting values"
oauth_secret=$(generate_secret)
sed -i'.bkp' -e "s/<a-random-key>/${oauth_secret}/g" "${ROOT_FOLDER}/values.yaml"
sed -i'.bkp' -e "s/<dex-kubermatic-oauth-secret-here>/${oauth_secret}/g" \
    "${ROOT_FOLDER}/kubermatic.yaml"

issuer_cookie_key=$(generate_secret)
sed -i".bkp" -e "s/<a-random-key>/${issuer_cookie_key}/g" \
    "${ROOT_FOLDER}/kubermatic.yaml"

service_account_key=$(generate_secret)
sed -i'.bkp' -e "s/<another-random-key>/${service_account_key}/g" \
    "${ROOT_FOLDER}/kubermatic.yaml"

sed -i'.bkp' -e "s/cluster.example.dev/${DOMAIN}/g" \
    "${ROOT_FOLDER}/values.yaml"
sed -i'.bkp' -e "s/cluster.example.dev/${DOMAIN}/g" \
    "${ROOT_FOLDER}/kubermatic.yaml"

if [[ "${PROD_CERT}" == "y" ]]; then
    sed -i'.bkp' -e "s/letsencrypt-staging/letsencrypt-prod/g" \
        "${ROOT_FOLDER}/kubermatic.yaml"
    sed -i'.bkp' -e "s/letsencrypt-staging/letsencrypt-prod/g" \
        "${ROOT_FOLDER}/values.yaml"
    sed -i'.bkp' -e "s/skipTokenIssuerTLSVerify:\s\+true/skipTokenIssuerTLSVerify: false/g" \
        "${ROOT_FOLDER}/kubermatic.yaml"
fi

kubeconfig_base64="$(cat "${SEED_KUBECONFIG}" | base64 | tr -d '\n\r')"
sed -i'.bkp' -e "s/<base64 encoded kubeconfig>/${kubeconfig_base64}/g" \
    "${ROOT_FOLDER}/seed.yaml"
log "Finished"
