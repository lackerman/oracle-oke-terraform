variable "compartment_id" {
  type        = string
  description = "The compartment to create the resources in"
}

# All region IDs can be found https://docs.oracle.com/en-us/iaas/Content/General/Concepts/regions.htm
# or you can use `grep region= "${HOME}/.oci/config" | tr '=' ' ' | awk '{print $2}'` to get it from
# your OCI config
variable "region" {
  type        = string
  description = "The region to provision the resources in"
}

terraform {
  required_providers {
    oci = {
      source  = "oracle/oci"
      version = "4.71.0"
    }
  }
}

provider "oci" {
  region = var.region
}