# ==================== Service Account ====================
resource "yandex_iam_service_account" "terraform_sa" {
  name        = var.sa_name
  description = var.sa_description
  folder_id   = var.folder_id
}

# ==================== Kubernetes Service Account ====================
resource "yandex_iam_service_account" "k8s_sa" {
  name        = var.k8s_sa_name
  description = "Service account for Kubernetes cluster"
  folder_id   = var.folder_id
}

resource "yandex_resourcemanager_folder_iam_member" "k8s_sa_roles" {
  for_each = toset([
    "k8s.clusters.agent",
    "vpc.publicAdmin",
    "container-registry.images.puller",
    "kms.keys.encrypterDecrypter",
    "logging.writer",
  ])

  folder_id = var.folder_id
  role      = each.value
  member    = "serviceAccount:${yandex_iam_service_account.k8s_sa.id}"
}

# ==================== IAM Roles ====================
resource "yandex_resourcemanager_folder_iam_member" "terraform_sa_roles" {
  for_each = toset(var.sa_roles)

  folder_id = var.folder_id
  role      = each.value
  member    = "serviceAccount:${yandex_iam_service_account.terraform_sa.id}"
}

# ==================== Static Access Key for S3 ====================
resource "yandex_iam_service_account_static_access_key" "terraform_sa_key" {
  service_account_id = yandex_iam_service_account.terraform_sa.id
  description        = var.key_description

  depends_on = [yandex_resourcemanager_folder_iam_member.terraform_sa_roles]
}

# ==================== Authorized Key for SA ====================
resource "yandex_iam_service_account_key" "terraform_sa_authorized_key" {
  service_account_id = yandex_iam_service_account.terraform_sa.id
  description        = "Authorized key for Terraform service account"
  key_algorithm      = "RSA_4096"
}

resource "local_file" "sa_key_json" {
  content = jsonencode({
    id                 = yandex_iam_service_account_key.terraform_sa_authorized_key.id
    service_account_id = yandex_iam_service_account_key.terraform_sa_authorized_key.service_account_id
    created_at         = yandex_iam_service_account_key.terraform_sa_authorized_key.created_at
    key_algorithm      = yandex_iam_service_account_key.terraform_sa_authorized_key.key_algorithm
    public_key         = yandex_iam_service_account_key.terraform_sa_authorized_key.public_key
    private_key        = yandex_iam_service_account_key.terraform_sa_authorized_key.private_key
  })
  filename        = "/tmp/.authorized_key_diplom.json"
  file_permission = "0600"
}

# ==================== Generate .env for all layers ====================
resource "local_file" "env_file" {
  filename        = "/tmp/.env"
  content         = <<-EOT
    # S3 backend (для terraform init во всех слоях)
    export AWS_ACCESS_KEY_ID="${yandex_iam_service_account_static_access_key.terraform_sa_key.access_key}"
    export AWS_SECRET_ACCESS_KEY="${yandex_iam_service_account_static_access_key.terraform_sa_key.secret_key}"

    # Для terraform_remote_state (чтение state других слоёв)
    export TF_VAR_network_state_access_key="$AWS_ACCESS_KEY_ID"
    export TF_VAR_network_state_secret_key="$AWS_SECRET_ACCESS_KEY"
  EOT
  file_permission = "0600"
}

# ==================== Container Registry ====================
resource "yandex_container_registry" "main" {
  name      = var.registry_name
  folder_id = var.folder_id

  labels = {
    environment = "prod"
    project     = "diplom"
  }
}

resource "yandex_container_registry_iam_binding" "scanner" {
  registry_id = yandex_container_registry.main.id
  role        = "container-registry.images.scanner"
  members     = ["serviceAccount:${yandex_iam_service_account.k8s_sa.id}"]
}

# ==================== KMS Key for Bucket Encryption ====================
resource "yandex_kms_symmetric_key" "state_bucket_key" {
  name              = "${var.bucket_name}-kms-key"
  description       = "KMS key for encrypting Terraform state bucket"
  folder_id         = var.folder_id
  default_algorithm = var.kms_algorithm
  rotation_period   = var.kms_rotation_period

  lifecycle {
    prevent_destroy = false
  }
}

# ==================== S3 Bucket for Terraform State ====================
resource "yandex_storage_bucket" "terraform_state" {
  bucket        = var.bucket_name
  folder_id     = var.folder_id
  force_destroy = var.force_destroy

  access_key = yandex_iam_service_account_static_access_key.terraform_sa_key.access_key
  secret_key = yandex_iam_service_account_static_access_key.terraform_sa_key.secret_key

  depends_on = [
    yandex_kms_symmetric_key.state_bucket_key,
    yandex_iam_service_account_static_access_key.terraform_sa_key,
  ]

  versioning {
    enabled = var.enable_versioning
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        kms_master_key_id = yandex_kms_symmetric_key.state_bucket_key.id
        sse_algorithm     = "aws:kms"
      }
    }
  }

  lifecycle_rule {
    id      = "cleanup-old-state-versions"
    enabled = true

    noncurrent_version_expiration {
      days = var.lifecycle_days
    }
  }
}
