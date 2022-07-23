locals {
  subnets = {
    vcn     = "192.168.100.0/23"
    public  = "192.168.100.0/24"
    private = "192.168.101.0/24"
  }

  cluster = {
    name    = "k8s"
    version = "v1.23.4"

    api = {
      is_public = false
    }

    nodes = {
      count  = 2
      config = {
        ocpus         = 2
        memory_in_gbs = 12
        # https://docs.oracle.com/en-us/iaas/images/oracle-linux-8x/
        # Architecture: aarch64
        shape         = "VM.Standard.A1.Flex"
        image_id      = "ocid1.image.oc1.eu-amsterdam-1.aaaaaaaag2tvqc3bzz24effe6zt6whn7ylej4esbgtklczmjqodvcprux6eq"
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
    # https://docs.oracle.com/en-us/iaas/images/oracle-linux-8x/
    # Architecture: AMD64
    shape    = "VM.Standard.E2.1.Micro"
    image_id = "ocid1.image.oc1.eu-amsterdam-1.aaaaaaaaod4dkc5kjoyptn7tcrxjmqkceibbfjmbs33kznypwddkf7vbgwyq"
  }

  tags = {
    "Terraformed" : "true"
  }
}
