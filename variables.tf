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

variable "ssh_public_key_file" {
  type        = string
  description = "The SSH public key to use for connecting to the worker nodes"
}

variable "public_ip" {
  type        = string
  description = "The public IP of the client machine needing to use the bastion"
}

variable "enable_pubvm" {
  default     = false
  type        = string
  description = "Whether or not to enable the publicly accessible VM"
}