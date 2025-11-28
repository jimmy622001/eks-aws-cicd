variable "primary_region" {
  description = "The AWS region for the primary environment"
  type        = string
}

variable "dr_region" {
  description = "The AWS region for the DR environment"
  type        = string
}

variable "project_name" {
  description = "The name of the project"
  type        = string
}