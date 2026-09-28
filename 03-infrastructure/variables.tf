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

variable "service_account_key_file" {
  description = "Path to authorized key file"
  type        = string
  default     = "/tmp/.authorized_key_diplom.json"
}

variable "default_zone" {
  description = "Default availability zone"
  type        = string
  default     = "ru-central1-a"
}

variable "public_key_path" {
  description = "Path to SSH public key for VM access"
  type        = string
  default     = "/tmp/id_rsa.pub"
}

# ==================== References to Layer 1 ====================
variable "state_bucket_name" {
  description = "S3 bucket name for Terraform state (from Layer 1)"
  type        = string
  default     = "diplom-terraform-state"
}

# ==================== Reference to Layer 2 (Network) ====================
variable "network_state_bucket" {
  description = "S3 bucket name for network state"
  type        = string
  default     = "diplom-terraform-state"
}

variable "network_state_key" {
  description = "S3 key for network state"
  type        = string
  default     = "02-network/terraform.tfstate"
}

variable "network_state_region" {
  description = "S3 region for network state"
  type        = string
  default     = "ru-central1"
}

variable "network_state_access_key" {
  description = "Access key for reading network state"
  type        = string
  sensitive   = true
  default     = ""
}

variable "network_state_secret_key" {
  description = "Secret key for reading network state"
  type        = string
  sensitive   = true
  default     = ""
}

# ==================== Master Node ====================
variable "master_config" {
  description = "Master node configuration"
  type = object({
    name        = string
    zone        = string
    cores       = number
    memory      = number
    disk_size   = number
    image_id    = string
    preemptible = bool
  })
  default = {
    name        = "k8s-master"
    zone        = "ru-central1-b"
    cores       = 2
    memory      = 4
    disk_size   = 30
    image_id    = "fd8pqsf3t7qajl8fhq9o"
    preemptible = true
  }
}

# ==================== Worker Nodes ====================
variable "worker_config" {
  description = "Worker nodes configuration"
  type = object({
    name_prefix = string
    zones       = list(string)
    cores       = number
    memory      = number
    disk_size   = number
    image_id    = string
    preemptible = bool
    count       = number
  })
  default = {
    name_prefix = "k8s-worker"
    zones       = ["ru-central1-a", "ru-central1-b", "ru-central1-d"]
    cores       = 2
    memory      = 2
    disk_size   = 20
    image_id    = "fd8pqsf3t7qajl8fhq9o"
    preemptible = true
    count       = 3
  }
}

# ==================== Ansible Integration ====================
variable "ansible_repo_url" {
  description = "Git repository URL with Ansible playbooks"
  type        = string
  default     = "https://github.com/IthnHuitn/ansible-k8s"
}

variable "ansible_repo_branch" {
  description = "Branch of Ansible repository"
  type        = string
  default     = "master"
}

variable "ansible_playbook" {
  description = "Ansible playbook to run"
  type        = string
  default     = "playbooks/site.yml"
}

variable "enable_ansible_provisioner" {
  description = "Enable Ansible provisioner after VM creation"
  type        = bool
  default     = true
}
