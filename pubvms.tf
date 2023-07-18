resource "oci_core_instance" "pubvm" {
  count = local.vm.enabled ? 1 : 0

  display_name        = "pubvm"
  availability_domain = data.oci_identity_availability_domains.ads.availability_domains[0].name
  compartment_id      = var.compartment_id
  shape               = local.vm.shape

  source_details {
    source_id   = local.vm.image_id
    source_type = "image"
  }

  create_vnic_details {
    assign_public_ip = true
    subnet_id        = oci_core_subnet.public_subnet.id
    nsg_ids = [
      oci_core_network_security_group.internet_access.id,
      oci_core_network_security_group.pubvms.id
    ]
  }

  metadata = {
    ssh_authorized_keys = file(var.ssh_public_key_file)
  }

  preserve_boot_volume = false
  freeform_tags        = local.tags
}