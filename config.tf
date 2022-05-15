locals {
  subnets = {
    vcn     = "192.168.100.0/23"
    public  = "192.168.100.0/24"
    private = "192.168.101.0/24"
  }

  cluster = {
    name    = "k8s"
    version = "v1.22.5"

    api = {
      is_public = false
    }

    nodes = {
      count = 2
      config = {
        ocpus         = 2
        memory_in_gbs = 12
        shape         = "VM.Standard.A1.Flex"
        image_id      = "ocid1.image.oc1.eu-amsterdam-1.aaaaaaaai36djewxxe6o4w7pubx2m45zjcy2uba3hvohkytlnyuydwoctubq"
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
    shape    = "VM.Standard.E2.1.Micro"
    image_id = "ocid1.image.oc1.eu-amsterdam-1.aaaaaaaajru7svi5fneczeqs23632tazdtthlxwkvzelwzl43esuixofbabq"
  }

  tags = {
    "Terraformed" : "true"
  }
}
