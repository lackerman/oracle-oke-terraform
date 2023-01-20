locals {
  subnets = {
    vcn     = "192.168.100.0/23"
    public  = "192.168.100.0/24"
    private = "192.168.101.0/24"
  }

  cluster = {
    name    = "k8s"
    version = "v1.25.4"

    api = {
      is_public = false
    }

    nodes = {
      count = 2
      config = {
        ocpus         = 2
        memory_in_gbs = 12
        # oci_region_images | grep aarch | grep 'Oracle-Linux-8.6'
        shape    = "VM.Standard.A1.Flex"
        image_id = "ocid1.image.oc1.eu-amsterdam-1.aaaaaaaavmra3s4va4fqd4vlcrqc5v5jyqov5vdla3x3b6gzc64n6dkpuqua"
      }
    }

    subnets = {
      pods     = "10.1.0.0/16"
      services = "10.2.0.0/16"
    }

    nodePorts = [
      { type = "http", port = 30477 },
      { type = "https", port = 32425 },
    ]
  }

  vm = {
    # https://docs.oracle.com/en-us/iaas/images/oracle-linux-9x/
    # Architecture: AMD64
    shape    = "VM.Standard.E2.1.Micro"
    image_id = "ocid1.image.oc1.eu-amsterdam-1.aaaaaaaat7ehm5owaapzbnyzaifm6227wexqf3npx7ynh44mg64i73nhaela"
  }

  tags = {
    "Terraformed" : "true"
  }
}
