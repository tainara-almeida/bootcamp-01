# variables.tf

variable "project_id" {
  description = "O ID do projeto GCP onde os recursos serão criados."
  type        = string
}

variable "region" {
  description = "A região GCP para provisionar os recursos."
  type        = string
  default     = "us-central1"
}

variable "cluster_name_prefix" {
  description = "Prefixo para o nome do cluster GKE."
  type        = string
  default     = "modern-app"
}
