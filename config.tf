locals {
  subnets = {
    vcn     = "192.168.100.0/23"
    public  = "192.168.100.0/24"
    private = "192.168.101.0/24"
  }

  cluster = {
    name    = "k8s"
    version = "v1.26.2"

    api = {
      is_public = false
    }

    nodes = {
      count = 2
      config = {
        ocpus         = 2
        memory_in_gbs = 12
        # run 'oci_node_images' to get the latest image id
        shape    = "VM.Standard.A1.Flex"
        image_id = "ocid1.image.oc1.eu-amsterdam-1.aaaaaaaa5u5fv5jyoz75av6i54yujanrehv4uwnrtkqnftqip2pu5a645aha"
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
    # oci_region_images | grep -v aarch | grep 'Oracle-Linux-9'
    enabled  = var.enable_pubvm
    shape    = "VM.Standard.E2.1.Micro"
    image_id = "ocid1.image.oc1.eu-amsterdam-1.aaaaaaaalskzsfibjqlsiphzuqp6s54met74vxnusxroffaxvhhb25tyx47q"
  }

  tags = {
    "Terraformed" : "true"
  }
}
