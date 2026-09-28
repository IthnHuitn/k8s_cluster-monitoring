# ==================== Cloud Credentials ====================
variable "cloud_id" {
  description = "Yandex Cloud ID"
  type        = string
}

variable "folder_id" {
  description = "Yandex Cloud Folder ID"
  type        = string
}

variable "yc_token" {
  description = "Yandex Cloud OAuth token"
  type        = string
  sensitive   = true
  default     = ""
}

variable "yc_sa_key_file" {
  description = "Path to service account key JSON file"
  type        = string
  default     = ""
}

variable "default_zone" {
  description = "Default availability zone"
  type        = string
  default     = "ru-central1-a"
}

# ==================== Service Account ====================
variable "sa_name" {
  description = "Name of the service account for Terraform"
  type        = string
  default     = "diplom-terraform-sa"
}

variable "sa_description" {
  description = "Description for the service account"
  type        = string
  default     = "Service account for Terraform infrastructure management"
}

variable "sa_roles" {
  description = "List of roles assigned to the service account"
  type        = list(string)
  default = [
    "admin",
    "editor",
    "vpc.admin",
    "compute.admin",
    "iam.serviceAccounts.user",
    "storage.admin",
    "storage.configViewer",
    "k8s.admin",
    "container-registry.admin",
    "logging.writer",
    "kms.keys.encrypterDecrypter",
  ]
}

variable "key_description" {
  description = "Description for the static access key"
  type        = string
  default     = "Static access key for S3 backend"
}

# ==================== Kubernetes Service Account ====================
variable "k8s_sa_name" {
  description = "Service account name for Kubernetes"
  type        = string
  default     = "diplom-k8s-sa"
}

# ==================== Container Registry ====================
variable "registry_name" {
  description = "Container registry name"
  type        = string
  default     = "diplom-registry"
}

# ==================== S3 Bucket ====================
variable "bucket_name" {
  description = "Name of the S3 bucket for Terraform state"
  type        = string
  default     = "diplom-terraform-state"
}

variable "enable_versioning" {
  description = "Enable versioning for state bucket"
  type        = bool
  default     = true
}

variable "lifecycle_days" {
  description = "Days to keep non-current versions"
  type        = number
  default     = 30
}

variable "force_destroy" {
  description = "Allow destroying bucket with objects"
  type        = bool
  default     = false
}

# ==================== KMS Settings ====================
variable "kms_algorithm" {
  description = "KMS encryption algorithm"
  type        = string
  default     = "AES_256"
}

variable "kms_rotation_period" {
  description = "KMS key rotation period"
  type        = string
  default     = "8760h"
}
