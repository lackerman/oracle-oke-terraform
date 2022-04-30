data "oci_identity_availability_domains" "ads" {
  compartment_id = var.compartment_id
}

output "ads" {
  value = data.oci_identity_availability_domains.ads.availability_domains
}