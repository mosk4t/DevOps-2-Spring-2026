terraform {
  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
    }
  }
}

provider "yandex" {
  endpoint = "api.yandexcloud.kz:443" 
  zone     = "kz1-a"                  
}

resource "yandex_vpc_network" "k8s_net" {
  name = "k8s-network-kz"
}

resource "yandex_vpc_subnet" "k8s_subnet" {
  name           = "k8s-subnet-karaganda"
  zone           = "kz1-a"
  network_id     = yandex_vpc_network.k8s_net.id
  v4_cidr_blocks = ["10.10.0.0/24"]
}

data "yandex_compute_image" "ubuntu" {
  family = "ubuntu-2204-lts"
}

resource "yandex_compute_instance" "k8s_nodes" {
  count = 3
  name  = "node-${count.index}"
  hostname = "node-${count.index}"
  platform_id = "standard-v3" # Ice Lake

  resources {
    cores  = 2
    memory = 4
    core_fraction = 20
  }

  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.ubuntu.id
      size     = 30
    }
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.k8s_subnet.id
    nat       = true
  }

  metadata = {
    ssh-keys = "ubuntu:${file("/home/moskat/.ssh/yandex_key.pub")}"
  }
}

output "ips" {
  value = yandex_compute_instance.k8s_nodes[*].network_interface.0.nat_ip_address
}
