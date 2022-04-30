resource "oci_bastion_bastion" "bastion" {
  name                         = "k8s-cluster-bastion"
  bastion_type                 = "standard"
  compartment_id               = var.compartment_id
  target_subnet_id             = oci_core_subnet.private_subnet.id
  max_session_ttl_in_seconds   = 180 * 60 # 3 hours
  client_cidr_block_allow_list = [var.public_ip]

  freeform_tags = local.tags
}
