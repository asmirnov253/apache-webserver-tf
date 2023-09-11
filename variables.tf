variable "region" {
  description = "The AWS region where resources will be provisioned."
  default     = "eu-west-3" # You can set your default region here or override it when running Terraform.
}

variable "shared_credentials_file" {
  description = "The path to the shared AWS credentials file."
  default     = "~/.aws/credentials" # You can set your default credentials file location here.
}

variable "profile" {
  description = "The AWS profile to use for authentication."
  default     = "default" # You can set your default AWS profile name here.
}