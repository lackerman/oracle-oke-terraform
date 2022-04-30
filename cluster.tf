data "oci_identity_availability_domains" "ads" {
  compartment_id = var.compartment_id
}

resource "oci_artifacts_container_repository" "container_registry" {
  compartment_id = var.compartment_id
  display_name   = "container-registry"

  is_immutable = false
  is_public    = false
}

resource "oci_containerengine_cluster" "k8s_cluster" {
  compartment_id     = var.compartment_id
  kubernetes_version = local.cluster.version
  name               = "${local.cluster.name}-cluster"
  vcn_id             = module.vcn.vcn_id

  endpoint_config {
    is_public_ip_enabled = false
    subnet_id            = oci_core_subnet.private_subnet.id
    nsg_ids = [
      oci_core_network_security_group.cluster_api.id
    ]
  }

  options {
    add_ons {
      is_kubernetes_dashboard_enabled = false
      is_tiller_enabled               = false
    }
    kubernetes_network_config {
      pods_cidr     = local.cluster.subnets.pods
      services_cidr = local.cluster.subnets.services
    }
    service_lb_subnet_ids = [oci_core_subnet.public_subnet.id]
  }
  freeform_tags = local.tags
}

resource "oci_containerengine_node_pool" "k8s_node_pool" {
  cluster_id         = oci_containerengine_cluster.k8s_cluster.id
  compartment_id     = var.compartment_id
  kubernetes_version = local.cluster.version
  name               = "${local.cluster.name}-node-pool"

  node_config_details {
    dynamic "placement_configs" {
      for_each = [for ad in data.oci_identity_availability_domains.ads.availability_domains : ad.name]

      content {
        availability_domain = placement_configs.value
        subnet_id           = oci_core_subnet.private_subnet.id
      }
    }
    size = local.cluster.nodes.count
    nsg_ids = [
      oci_core_network_security_group.internet_access.id,
      oci_core_network_security_group.cluster_workers.id
    ]
  }

  node_shape = local.cluster.nodes.config.shape

  node_shape_config {
    memory_in_gbs = local.cluster.nodes.config.memory_in_gbs
    ocpus         = local.cluster.nodes.config.ocpus
  }

  node_source_details {
    image_id    = local.cluster.nodes.config.image_id
    source_type = "image"
  }

  initial_node_labels {
    key   = "name"
    value = "${local.cluster.name}-cluster"
  }

  ssh_public_key = file(var.ssh_public_key_file)
  freeform_tags  = local.tags
}
