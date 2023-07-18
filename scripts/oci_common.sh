#!/bin/bash

## Lists the OCI compute instance images for the specific region
oci_region_images() {
  ## Images based on your region can be found at:
  ## https://docs.oracle.com/en-us/iaas/images/
  ## or by using oci check the `region_images` make directive.
  oci compute image list --all \
  		--compartment-id "${OCI_VAR_compartment_id}" \
  		--region "${OCI_VAR_region}" \
  		--query "data[*]".\{'name:"display-name",id:id'\} \
  		| jq -r '.[] | [.name, .id] | join(", ")'
}

oci_node_images() {
  oci ce node-pool-options get --node-pool-option-id all \
      | jq -r '[.data.sources[] | {name:."source-name", id:."image-id"}] | sort_by(.name)'
}

## List terraformed resources ('Terraformed' freeform tag is present)
oci_list_terraform_resources() {
  # OCI Search Docs
  # https://docs.oracle.com/en-us/iaas/Content/Search/Concepts/samplequeries.htm
  oci search resource structured-search \
    --query-text "query all resources where (freeformTags.key = 'Terraformed')" \
    | jq -r '.data.items[] | [."resource-type", ."display-name", ."lifecycle-state"] | @csv' \
    | column -t -s','
}

## List non-terraform resources (No 'Terraformed' freeform tag)
oci_list_non_terraform_resources() {
  # OCI Search Docs
  # https://docs.oracle.com/en-us/iaas/Content/Search/Concepts/samplequeries.htm
  oci search resource structured-search \
    --query-text "query all resources where (freeformTags.key != 'Terraformed')" \
    | jq -r '.data.items[] | [."resource-type", ."display-name", ."lifecycle-state"] | @csv' \
    | column -t -s','
}