#!/bin/bash

## Get the private ip of the first 'ACTIVE' cluster
oci_cluster_privateip() {
  oci ce cluster list --compartment-id "${OCI_VAR_compartment_id}" --lifecycle-state "ACTIVE" \
  | jq -r '.data[0].endpoints."private-endpoint"' \
  | cut -d ":" -f 1
}

## Get the ocid of the first 'ACTIVE' cluster
oci_cluster_id() {
  oci ce cluster list --compartment-id "${OCI_VAR_compartment_id}" --lifecycle-state "ACTIVE" \
  | jq -r '.data[0].id'
}

## Generate a kubeconfig file (~/.kube/ociconfig) based on the cluster id provided
oci_cluster_kubeconfig() {
  oci ce cluster create-kubeconfig \
    --cluster-id "$(oci_cluster_id)" \
    --file ~/.kube/ociconfig \
    --region "${OCI_VAR_region}" \
    --token-version 2.0.0 \
    --kube-endpoint PRIVATE_ENDPOINT
}
