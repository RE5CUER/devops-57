terraform {
  required_providers {
    yandex = {
      source  = "yandex-cloud/yandex"
      version = "0.133.0"
    }
  }
}

provider "yandex" {
  cloud_id  = "b1gophec4tfv8sar6590"
  folder_id = "b1grpu8ht5p4p9pj4bkd"
  zone      = "ru-central1-a"
  token     = "y0__xDe867PBxjB3RMgk7nQ1xIwl7CKhwg5bNAGNCci-DUeMNGhZ43i24VaiA"
}

# Создаю VPC (Virtual Private Cloud)
resource "yandex_vpc_network" "main_network" {
  name        = "main-network"
  description = "Main VPC network for our resources"
}

# Создаю Subnet (субсети) в созданной сети
resource "yandex_vpc_subnet" "main_subnet" {
  name           = "default-subnet"
  zone           = "ru-central1-a"
  network_id     = yandex_vpc_network.main_network.id
  v4_cidr_blocks = ["10.0.0.0/24"]
}

# Создаю Compute Instance для k8s-master с публичным IP
resource "yandex_compute_instance" "k8s_master" {
  name        = "k8s-master"
  zone        = "ru-central1-a"
  platform_id = "standard-v2"

  resources {
    cores  = 2
    memory = 4
  }

  boot_disk {
    initialize_params {
      image_id = "fd80bm0rh4rkepi5ksdi"
      size     = 50
      type     = "network-hdd"
    }
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.main_subnet.id
    nat       = true  # Включает публичный IP
  }

  metadata = {
  ssh-keys = "grid:${file("/root/.ssh/id_rsa.pub")}"  }
}

# Создаю Compute Instance для k8s-app с публичным IP
resource "yandex_compute_instance" "k8s_app" {
  name        = "k8s-app"
  zone        = "ru-central1-a"
  platform_id = "standard-v2"

  resources {
    cores  = 2
    memory = 4
  }

  boot_disk {
    initialize_params {
      image_id = "fd80bm0rh4rkepi5ksdi"
      size     = 50
      type     = "network-hdd"
    }
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.main_subnet.id
    nat       = true  # Включает публичный IP
  }

  metadata = {
  ssh-keys = "grid:${file("/root/.ssh/id_rsa.pub")}"
  }
}

# Создаю Compute Instance для srv с публичным IP
resource "yandex_compute_instance" "srv" {
  name        = "srv"
  zone        = "ru-central1-a"
  platform_id = "standard-v2"

  resources {
    cores  = 2
    memory = 8
  }

  boot_disk {
    initialize_params {
      image_id = "fd80bm0rh4rkepi5ksdi"
      size     = 50
      type     = "network-hdd"
    }
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.main_subnet.id
    nat       = true  # Включает публичный IP
  }

  metadata = {
  ssh-keys = "grid:${file("/root/.ssh/id_rsa.pub")}"
  }
}
# Output блок для записи IP-адресов
output "instance_ips" {
  value = {
    "k8s-master" = yandex_compute_instance.k8s_master.network_interface[0].nat_ip_address
    "k8s-app"    = yandex_compute_instance.k8s_app.network_interface[0].nat_ip_address
    "srv"        = yandex_compute_instance.srv.network_interface[0].nat_ip_address
  }
  description = "Public IP addresses of all instances"
}

# Провизионер для записи в inventory.ini
resource "null_resource" "write_inventory" {
  depends_on = [yandex_compute_instance.k8s_master, yandex_compute_instance.k8s_app, yandex_compute_instance.srv]

  provisioner "local-exec" {
    command = <<EOT
    echo "[k8s-master]" > /dip/ansible/inventory.ini
    echo "${yandex_compute_instance.k8s_master.network_interface[0].nat_ip_address} ansible_user=ubuntu ansible_ssh_private_key_file=/root/.ssh/id_rsa" >> /dip/ansible/inventory.ini
    echo "[k8s-app]" >> /dip/ansible/inventory.ini
    echo "${yandex_compute_instance.k8s_app.network_interface[0].nat_ip_address} ansible_user=ubuntu ansible_ssh_private_key_file=/root/.ssh/id_rsa" >> /dip/ansible/inventory.ini
    echo "[srv]" >> /dip/ansible/inventory.ini
    echo "${yandex_compute_instance.srv.network_interface[0].nat_ip_address} ansible_user=ubuntu ansible_ssh_private_key_file=/root/.ssh/id_rsa" >> /dip/ansible/inventory.ini
    echo "************************************************************************************"
    echo "==== SSH Commands to connect to servers ===="
    echo "k8s-master:			 ssh ubuntu@${yandex_compute_instance.k8s_master.network_interface[0].nat_ip_address}"
    echo "k8s-app:			 ssh ubuntu@${yandex_compute_instance.k8s_app.network_interface[0].nat_ip_address}"
    echo "srv:			 ssh ubuntu@${yandex_compute_instance.srv.network_interface[0].nat_ip_address}"
    EOT
  }
}
