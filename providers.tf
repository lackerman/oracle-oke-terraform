terraform {
  required_providers {
    # https://registry.terraform.io/providers/oracle/oci/latest/docs
    oci = {
      source  = "oracle/oci"
      version = "4.104.0"
    }
  }
}

provider "oci" {
  region = var.region
}