#!/bin/bash

# All region IDs can be found at
# https://docs.oracle.com/en-us/iaas/Content/General/Concepts/regions.htm
# or you can use the command below which uses your your OCI config.
[[ -z "${OCI_VAR_region}" ]] && \
    OCI_VAR_region="$(grep region= "${HOME}/.oci/config" | tr '=' ' ' | awk '{print $2}')"
# This is assuming you only have 1 compartment ID
[[ -z "${OCI_VAR_compartment_id}" ]] && \
    OCI_VAR_compartment_id="$(oci iam compartment list | jq -r '.data[0]."compartment-id"')"
# Change this if you want to use a different public key for connecting to instances
[[ -z "${OCI_VAR_ssh_public_key_file}" ]] && \
    OCI_VAR_ssh_public_key_file="${HOME}/.ssh/id_rsa.pub"
# Change this if you use a different key and want to connect to a bastion session
[[ -z "${OCI_VAR_ssh_private_key_file}" ]] && \
    OCI_VAR_ssh_private_key_file="${HOME}/.ssh/id_rsa"
# Use ipify to get curent public IP
[[ -z "${OCI_VAR_public_ip}" ]] && \
    OCI_VAR_public_ip="$(curl --silent 'https://api.ipify.org?format=json' | jq -r .ip)/32"

TF_VAR_region="${OCI_VAR_region}"
TF_VAR_compartment_id="${OCI_VAR_compartment_id}"
TF_VAR_ssh_public_key_file="${OCI_VAR_ssh_public_key_file}"
TF_VAR_public_ip="${OCI_VAR_public_ip}"

export OCI_VAR_region
export OCI_VAR_compartment_id
export OCI_VAR_ssh_public_key_file
export OCI_VAR_ssh_private_key_file
export OCI_VAR_public_ip
env | grep OCI_VAR_

export TF_VAR_region
export TF_VAR_compartment_id
export TF_VAR_ssh_public_key_file
export TF_VAR_public_ip
env | grep TF_VAR_

# Regardless of where the script is called from, source the bin/*.sh files
script_dir=$(dirname "${BASH_SOURCE[0]}")   # Get the directory name
script_dir=$(realpath "${script_dir}")      # Resolve its full path if need be

source "${script_dir}/oci_common.sh"
source "${script_dir}/oci_cluster.sh"
source "${script_dir}/oci_bastion.sh"
