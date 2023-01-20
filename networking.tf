module "vcn" {
  source  = "oracle-terraform-modules/vcn/oci"
  version = "3.5.3"

  compartment_id = var.compartment_id
  region         = var.region

  vcn_name      = "${local.cluster.name}-vcn"
  vcn_dns_label = "${local.cluster.name}vcn"

  internet_gateway_route_rules = null
  local_peering_gateways       = null
  nat_gateway_route_rules      = null

  vcn_cidrs = [
    local.subnets.vcn,
  ]

  create_internet_gateway = true
  create_nat_gateway      = true
  create_service_gateway  = true
  freeform_tags           = local.tags
}

resource "oci_core_security_list" "private_subnet" {
  compartment_id = var.compartment_id
  vcn_id         = module.vcn.vcn_id

  display_name = "${local.cluster.name}-private-subnet"

  egress_security_rules {
    description      = "Allow Internet access to everything in the private subnet"
    stateless        = false
    destination      = "0.0.0.0/0"
    destination_type = "CIDR_BLOCK"
    protocol         = "all"
  }

  ingress_security_rules {
    description = "Allow ingress from anywhere within the private subnet"
    stateless   = false
    source      = local.subnets.private
    source_type = "CIDR_BLOCK"
    protocol    = "all"
  }

  dynamic "ingress_security_rules" {
    for_each = local.cluster.nodePorts

    content {
      description = "Allow ${ingress_security_rules.value.type} access from the public subnet to the Node port ${ingress_security_rules.value.port}"
      stateless   = false
      source      = local.subnets.public
      source_type = "CIDR_BLOCK"
      protocol    = "6" # ICMP: 1 | TCP: 6 | UDP: 17 | ICMPv6: 58
      tcp_options {
        min = ingress_security_rules.value.port
        max = ingress_security_rules.value.port
      }
    }
  }

  ingress_security_rules {
    protocol    = "6"
    source      = "192.168.100.0/24"
    source_type = "CIDR_BLOCK"
    stateless   = false

    tcp_options {
      max = 10256
      min = 10256
    }
  }
}

resource "oci_core_security_list" "public_subnet" {
  compartment_id = var.compartment_id
  vcn_id         = module.vcn.vcn_id

  display_name = "${local.cluster.name}-public-subnet"

  egress_security_rules {
    description      = "Allow Internet access to everything in the public subnet"
    stateless        = false
    destination      = "0.0.0.0/0"
    destination_type = "CIDR_BLOCK"
    protocol         = "all"
  }

  ingress_security_rules {
    description = "Allow HTTP access from the Internet"
    stateless   = false
    source      = "0.0.0.0/0"
    source_type = "CIDR_BLOCK"
    protocol    = "6" # ICMP: 1 | TCP: 6 | UDP: 17 | ICMPv6: 58
    tcp_options {
      min = 80
      max = 80
    }
  }

  ingress_security_rules {
    description = "Allow HTTPS access from the Internet"
    stateless   = false
    source      = "0.0.0.0/0"
    source_type = "CIDR_BLOCK"
    protocol    = "6" # ICMP: 1 | TCP: 6 | UDP: 17 | ICMPv6: 58
    tcp_options {
      min = 443
      max = 443
    }
  }

  dynamic "egress_security_rules" {
    for_each = local.cluster.nodePorts

    content {
      description      = "Allow ${egress_security_rules.value.type} access to the private subnet to the Node port ${egress_security_rules.value.port}"
      stateless        = false
      destination      = local.subnets.private
      destination_type = "CIDR_BLOCK"
      protocol         = "6"
      tcp_options {
        min = egress_security_rules.value.port
        max = egress_security_rules.value.port
      }
    }
  }

  egress_security_rules {
    destination      = "192.168.101.0/24"
    destination_type = "CIDR_BLOCK"
    protocol         = "6"
    stateless        = false

    tcp_options {
      max = 10256
      min = 10256
    }
  }
}

###
### Internet access security group
###

resource "oci_core_network_security_group" "internet_access" {
  compartment_id = var.compartment_id
  vcn_id         = module.vcn.vcn_id

  display_name = "Internet Access"

  freeform_tags = local.tags
}

resource "oci_core_network_security_group_security_rule" "internet_access" {
  network_security_group_id = oci_core_network_security_group.internet_access.id
  description               = "Allow all traffic out to the internet"
  protocol                  = "all"
  destination               = "0.0.0.0/0"
  destination_type          = "CIDR_BLOCK"
  stateless                 = false
  direction                 = "EGRESS"
}

###
### Internet access security group
###

resource "oci_core_network_security_group" "pubvms" {
  compartment_id = var.compartment_id
  vcn_id         = module.vcn.vcn_id

  display_name = "Public VMs Security Group"
}

resource "oci_core_network_security_group_security_rule" "pubvms_ssh_access" {
  network_security_group_id = oci_core_network_security_group.pubvms.id
  description               = "Allow ssh traffic from the internet"
  protocol                  = 6 # ICMP: 1 | TCP: 6 | UDP: 17 | ICMPv6: 58
  source                    = "0.0.0.0/0"
  source_type               = "CIDR_BLOCK"
  destination               = local.subnets.public
  destination_type          = "CIDR_BLOCK"
  stateless                 = false
  direction                 = "INGRESS"

  tcp_options {
    destination_port_range {
      max = 22
      min = 22
    }
  }
}

resource "oci_core_network_security_group_security_rule" "pubvms_http_access" {
  network_security_group_id = oci_core_network_security_group.pubvms.id
  description               = "Allow http traffic from the internet"
  protocol                  = 6 # ICMP: 1 | TCP: 6 | UDP: 17 | ICMPv6: 58
  source                    = "0.0.0.0/0"
  source_type               = "CIDR_BLOCK"
  destination               = local.subnets.public
  destination_type          = "CIDR_BLOCK"
  stateless                 = false
  direction                 = "INGRESS"

  tcp_options {
    destination_port_range {
      max = 80
      min = 80
    }
  }
}

###
### API nodes security group
### https://docs.oracle.com/en-us/iaas/Content/ContEng/Concepts/contengnetworkconfig.htm#securitylistconfig
###

resource "oci_core_network_security_group" "cluster_api" {
  compartment_id = var.compartment_id
  vcn_id         = module.vcn.vcn_id

  display_name  = "Cluster API endpoint"
  freeform_tags = local.tags
}

resource "oci_core_network_security_group_security_rule" "cluster_api_from_workers" {
  network_security_group_id = oci_core_network_security_group.cluster_api.id
  description               = "Kubernetes worker to Kubernetes API endpoint communication."
  protocol                  = 6
  source                    = local.subnets.private
  source_type               = "CIDR_BLOCK"
  stateless                 = false
  direction                 = "INGRESS"

  tcp_options {
    destination_port_range {
      max = 6443
      min = 6443
    }
  }
}

resource "oci_core_network_security_group_security_rule" "cluster_api_from_workers_to_control_plane" {
  network_security_group_id = oci_core_network_security_group.cluster_api.id
  description               = "Kubernetes worker to control plane communication."
  protocol                  = 6
  source                    = local.subnets.private
  source_type               = "CIDR_BLOCK"
  stateless                 = false
  direction                 = "INGRESS"

  tcp_options {
    destination_port_range {
      max = 12250
      min = 12250
    }
  }
}

resource "oci_core_network_security_group_security_rule" "cluster_api_traffic_mtu_neg_ingress" {
  network_security_group_id = oci_core_network_security_group.cluster_api.id
  description               = "Path discovery."
  protocol                  = 1 # ICMP: 1 | TCP: 6 | UDP: 17 | ICMPv6: 58
  source                    = local.subnets.private
  source_type               = "CIDR_BLOCK"
  stateless                 = false
  direction                 = "INGRESS"

  icmp_options {
    type = 3
    code = 4
  }
}

resource "oci_core_network_security_group_security_rule" "cluster_api_to_workers" {
  network_security_group_id = oci_core_network_security_group.cluster_api.id
  description               = "All traffic to worker nodes."
  protocol                  = 6
  destination               = local.subnets.private
  destination_type          = "CIDR_BLOCK"
  stateless                 = false
  direction                 = "EGRESS"
}

resource "oci_core_network_security_group_security_rule" "cluster_api_traffic_mtu_neg_egress" {
  network_security_group_id = oci_core_network_security_group.cluster_workers.id
  description               = "Path discovery."
  protocol                  = 1 # ICMP: 1 | TCP: 6 | UDP: 17 | ICMPv6: 58
  destination               = local.subnets.private
  destination_type          = "CIDR_BLOCK"
  stateless                 = false
  direction                 = "EGRESS"

  icmp_options {
    type = 3
    code = 4
  }
}

###
### Worker nodes security rules
### https://docs.oracle.com/en-us/iaas/Content/ContEng/Concepts/contengnetworkconfig.htm#securitylistconfig
###

resource "oci_core_network_security_group" "cluster_workers" {
  compartment_id = var.compartment_id
  vcn_id         = module.vcn.vcn_id

  display_name  = "Worker nodes"
  freeform_tags = local.tags
}

resource "oci_core_network_security_group_security_rule" "cluster_worker_to_worker" {
  network_security_group_id = oci_core_network_security_group.cluster_workers.id
  description               = "Allow pods on one worker node to communicate with pods on other worker nodes"
  protocol                  = "all"
  source                    = local.subnets.private
  source_type               = "CIDR_BLOCK"
  destination               = local.subnets.private
  destination_type          = "CIDR_BLOCK"
  stateless                 = false
  direction                 = "INGRESS"
}

resource "oci_core_network_security_group_security_rule" "cluster_workers_public_subnet_https_access" {
  network_security_group_id = oci_core_network_security_group.cluster_workers.id
  description               = "Allow HTTPS traffic from the public subnet to the private subnet"
  protocol                  = 6 # ICMP: 1 | TCP: 6 | UDP: 17 | ICMPv6: 58
  source                    = local.subnets.public
  source_type               = "CIDR_BLOCK"
  stateless                 = false
  direction                 = "INGRESS"

  tcp_options {
    destination_port_range {
      max = 443
      min = 443
    }
  }
}

resource "oci_core_network_security_group_security_rule" "cluster_workers_traffic_mtu_neg_ingress" {
  network_security_group_id = oci_core_network_security_group.cluster_workers.id
  description               = "Path discovery"
  protocol                  = 1 # ICMP: 1 | TCP: 6 | UDP: 17 | ICMPv6: 58
  source                    = local.subnets.private
  source_type               = "CIDR_BLOCK"
  destination               = "0.0.0.0/0"
  destination_type          = "CIDR_BLOCK"
  stateless                 = false
  direction                 = "EGRESS"

  icmp_options {
    type = 3
    code = 4
  }
}

resource "oci_core_subnet" "private_subnet" {
  compartment_id = var.compartment_id
  vcn_id         = module.vcn.vcn_id
  cidr_block     = local.subnets.private

  route_table_id    = module.vcn.nat_route_id
  display_name      = "${local.cluster.name}-private-subnet"
  security_list_ids = [oci_core_security_list.private_subnet.id]

  prohibit_public_ip_on_vnic = true
  freeform_tags              = local.tags
}

resource "oci_core_subnet" "public_subnet" {
  compartment_id = var.compartment_id
  vcn_id         = module.vcn.vcn_id
  cidr_block     = local.subnets.public

  route_table_id    = module.vcn.ig_route_id
  display_name      = "${local.cluster.name}-public-subnet"
  security_list_ids = [oci_core_security_list.public_subnet.id]

  freeform_tags = local.tags
}
