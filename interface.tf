locals {
  GITLAB_PROJECT_PATH_UNDERSCORE = replace(var.gitlab_project_path, "/", "_")
}

variable "gitlab_project_path" {
  description = "A path to project"
}

variable "cluster" {
  description = "A cluster in which operator is running"
}

variable "disable_iss_validation" {
  type        = bool
  default     = false
  description = "disable ISS validation (bandaid workaround for 'claim iss is invalid')"
}