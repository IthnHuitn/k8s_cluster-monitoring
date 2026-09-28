# ==================== VPC Network ====================
resource "yandex_vpc_network" "main" {
  name        = var.network_name
  description = "VPC for Kubernetes cluster"
  folder_id   = var.folder_id
}

# ==================== Subnets ====================
resource "yandex_vpc_subnet" "main" {
  for_each = { for s in var.subnets : s.name => s }

  name           = each.value.name
  zone           = each.value.zone
  network_id     = yandex_vpc_network.main.id
  v4_cidr_blocks = each.value.v4_cidr_blocks
  route_table_id = yandex_vpc_route_table.main.id
  folder_id      = var.folder_id
}

# ==================== NAT Gateway ====================
resource "yandex_vpc_gateway" "nat_gateway" {
  name      = "diplom-nat-gateway"
  folder_id = var.folder_id

  shared_egress_gateway {}
}

# ==================== Route Table ====================
resource "yandex_vpc_route_table" "main" {
  name       = "diplom-route-table"
  network_id = yandex_vpc_network.main.id
  folder_id  = var.folder_id

  static_route {
    destination_prefix = "0.0.0.0/0"
    gateway_id         = yandex_vpc_gateway.nat_gateway.id
  }
}

# ==================== Security Group ====================
resource "yandex_vpc_security_group" "k8s" {
  name        = "diplom-k8s-sg"
  description = "Security group for Kubernetes cluster"
  network_id  = yandex_vpc_network.main.id
  folder_id   = var.folder_id

  ingress {
    description    = "SSH access"
    protocol       = "TCP"
    port           = 22
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description    = "Kubernetes API"
    protocol       = "TCP"
    port           = 6443
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description    = "HTTP"
    protocol       = "TCP"
    port           = 80
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description    = "HTTPS"
    protocol       = "TCP"
    port           = 443
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description    = "NodePort services"
    protocol       = "TCP"
    from_port      = 30000
    to_port        = 32767
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description    = "Internal cluster communication"
    protocol       = "ANY"
    from_port      = 0
    to_port        = 65535
    v4_cidr_blocks = ["10.10.0.0/16"]
  }

  ingress {
    description    = "Flannel VXLAN"
    protocol       = "UDP"
    port           = 8472
    v4_cidr_blocks = ["10.10.0.0/16"]
  }

  ingress {
    description    = "Etcd"
    protocol       = "TCP"
    from_port      = 2379
    to_port        = 2380
    v4_cidr_blocks = ["10.10.0.0/16"]
  }

  egress {
    description    = "Allow all outbound"
    protocol       = "ANY"
    from_port      = 0
    to_port        = 65535
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}
