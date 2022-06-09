#!/bin/bash

oci_bastion_id() {
  oci bastion bastion list --compartment-id "${OCI_VAR_compartment_id}" --bastion-lifecycle-state "ACTIVE" 2> /dev/null \
  | jq -r '.data[0].id'
}

_replace_client_ips() {
  oci bastion bastion get --bastion-id "${OCI_VAR_bastion_id}" \
    | jq --arg ip "${OCI_VAR_public_ip}" '.data["client-cidr-block-allow-list"] = [$ip]'
}

oci_bastion_add_client_ip() {
  oci bastion bastion update --bastion-id "$(oci_bastion_id)" \
    --from-json "$(_replace_client_ips)"
}

oci_bastion_session_active_id() {
  oci bastion session list --bastion-id "${OCI_VAR_bastion_id}" --session-lifecycle-state "ACTIVE" \
  | jq -r '.data[0].id'
}

oci_bastion_session_create() {
  oci bastion session create-port-forwarding \
    --bastion-id "${OCI_VAR_bastion_id}" \
    --session-ttl 10800 \
    --display-name oke-tunnel \
    --ssh-public-key-file ~/.ssh/id_rsa.pub \
    --key-type PUB \
    --target-private-ip "$(oci_cluster_privateip)" \
    --target-port 6443
}

oci_bastion_session_state() {
  session_id="$1"
  oci bastion session get --session-id "${session_id}" \
  | jq -r '.data."lifecycle-state"'
}

oci_bastion_session_sshcommand() {
  session_id="$1"
  oci bastion session get --session-id "${session_id}" \
  | jq -r '.data."ssh-metadata".command'
}

oci_bastion_session_init() {
  session_id="$(oci_bastion_session_create | jq -r .data.id)"

  while [ "$(oci_bastion_session_state "${session_id}")" != "ACTIVE" ]; do
    >&2 echo "Current state: $(oci_bastion_session_state "${session_id}"). Sleeping for 1 second"
    sleep 1
  done

  echo "${session_id}"
}

## Connects to a bastion session, creating one if one does not exist,
## and sets up a port forward session to the kubernetes cluster api.
oci_bastion_session_kube_api() {
  debug="$1"

  OCI_VAR_bastion_id="${oci_bastion_id}"
  [ -z "${OCI_VAR_bastion_id}" ] && echo "Bastion ID is empty. Does the bastion exist?" && return 1
  export OCI_VAR_bastion_id

  session_id="$(oci_bastion_session_active_id)"
  if [[ -z "${session_id}" ]]; then
    session_id="$(oci_bastion_session_init)"
  fi

  ssh_command="$(oci_bastion_session_sshcommand "${session_id}")"
  ssh_command="${ssh_command/<localPort>/6443}"
  ssh_command="${ssh_command/<privateKey>/${OCI_VAR_ssh_private_key_file} ${debug}}"

  echo "$ssh_command"
  $ssh_command
}
