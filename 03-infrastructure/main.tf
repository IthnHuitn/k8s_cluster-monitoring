# ==================== Read Network State from Layer 2 ====================
data "terraform_remote_state" "network" {
  backend = "s3"

  config = {
    bucket     = var.network_state_bucket
    key        = var.network_state_key
    region     = var.network_state_region
    access_key = var.network_state_access_key
    secret_key = var.network_state_secret_key

    endpoints = {
      s3 = "https://storage.yandexcloud.net"
    }

    skip_region_validation      = true
    skip_credentials_validation = true
    skip_requesting_account_id  = true
    skip_metadata_api_check     = true
    skip_s3_checksum            = true
  }
}

# ==================== Master Node ====================
resource "yandex_compute_instance" "master" {
  name        = var.master_config.name
  zone        = var.master_config.zone
  folder_id   = var.folder_id
  platform_id = "standard-v3"

  resources {
    cores         = var.master_config.cores
    memory        = var.master_config.memory
    core_fraction = 50
  }

  boot_disk {
    initialize_params {
      image_id = var.master_config.image_id
      size     = var.master_config.disk_size
      type     = "network-hdd"
    }
  }

  network_interface {
    subnet_id          = data.terraform_remote_state.network.outputs.subnet_ids[var.master_config.zone]
    nat                = true
    security_group_ids = [data.terraform_remote_state.network.outputs.security_group_id]
  }

  metadata = {
    ssh-keys = "debian:${file(var.public_key_path)}"
  }

  scheduling_policy {
    preemptible = var.master_config.preemptible
  }

  labels = {
    role    = "master"
    cluster = "diplom"
  }
}

# ==================== Worker Nodes ====================
resource "yandex_compute_instance" "worker" {
  count = var.worker_config.count

  name        = "${var.worker_config.name_prefix}-${count.index + 1}"
  zone        = var.worker_config.zones[count.index % length(var.worker_config.zones)]
  folder_id   = var.folder_id
  platform_id = "standard-v3"

  resources {
    cores         = var.worker_config.cores
    memory        = var.worker_config.memory
    core_fraction = 20
  }

  boot_disk {
    initialize_params {
      image_id = var.worker_config.image_id
      size     = var.worker_config.disk_size
      type     = "network-hdd"
    }
  }

  network_interface {
    subnet_id          = data.terraform_remote_state.network.outputs.subnet_ids[var.worker_config.zones[count.index % length(var.worker_config.zones)]]
    nat                = false
    security_group_ids = [data.terraform_remote_state.network.outputs.security_group_id]
  }

  metadata = {
    ssh-keys = "debian:${file(var.public_key_path)}"
  }

  scheduling_policy {
    preemptible = var.worker_config.preemptible
  }

  labels = {
    role    = "worker"
    cluster = "diplom"
  }
}

# ==================== Load Balancer Target Group ====================
resource "yandex_lb_target_group" "k8s_workers" {
  name      = "k8s-workers-tg"
  folder_id = var.folder_id

  dynamic "target" {
    for_each = yandex_compute_instance.worker
    content {
      subnet_id = target.value.network_interface[0].subnet_id
      address   = target.value.network_interface[0].ip_address
    }
  }
}

# ==================== Network Load Balancer ====================
resource "yandex_lb_network_load_balancer" "k8s_lb" {
  name      = "k8s-load-balancer"
  folder_id = var.folder_id

  listener {
    name        = "http"
    port        = 80
    target_port = 30080
    external_address_spec {
      ip_version = "ipv4"
    }
  }

  listener {
    name        = "https"
    port        = 443
    target_port = 30443
    external_address_spec {
      ip_version = "ipv4"
    }
  }

  attached_target_group {
    target_group_id = yandex_lb_target_group.k8s_workers.id

    healthcheck {
      name                = "http-health"
      interval            = 5
      timeout             = 3
      unhealthy_threshold = 3
      healthy_threshold   = 2

      tcp_options {
        port = 30080
      }
    }
  }
}

# ==================== Generate Ansible Inventory ====================
resource "local_file" "ansible_inventory" {
  filename = "${path.module}/../ansible-k8s/inventory/hosts.yml"
  content = templatefile("${path.module}/templates/inventory.tpl", {
    master_public_ip   = yandex_compute_instance.master.network_interface[0].nat_ip_address
    master_internal_ip = yandex_compute_instance.master.network_interface[0].ip_address
    workers = [
      for idx, w in yandex_compute_instance.worker : {
        name        = "k8s-worker-${idx + 1}"
        public_ip   = ""
        internal_ip = w.network_interface[0].ip_address
      }
    ]
    control_plane_endpoint = "${yandex_compute_instance.master.network_interface[0].ip_address}:6443"
  })
}

# ==================== Run Ansible Provisioner ====================
resource "null_resource" "ansible_provision" {
  count = var.enable_ansible_provisioner ? 1 : 0

  triggers = {
    master_ip    = yandex_compute_instance.master.network_interface[0].nat_ip_address
    workers_hash = sha256(join(",", [for w in yandex_compute_instance.worker : w.network_interface[0].ip_address]))
    inventory    = local_file.ansible_inventory.content
  }

  provisioner "local-exec" {
    working_dir = "${path.module}/../ansible-k8s"
    command     = <<-EOT
      set -e

      echo "Waiting 30 seconds for SSH to start on all nodes..."
      sleep 30

      if [ ! -d .git ]; then
        git clone --branch ${var.ansible_repo_branch} ${var.ansible_repo_url} .
      else
        git pull origin ${var.ansible_repo_branch}
      fi
      ansible-playbook -i inventory/hosts.yml ${var.ansible_playbook}
    EOT
  }

  depends_on = [
    local_file.ansible_inventory,
    yandex_compute_instance.master,
    yandex_compute_instance.worker
  ]
}
