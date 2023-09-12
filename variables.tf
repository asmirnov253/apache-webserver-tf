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

variable "dynamodb_table_name" {
  description = "DynamoDB table name"
  type        = string
}

variable "vpc_cidr" {
  description = "Set your VPC IP range"
  type        = string
  default     = "10.0.0.0/16"
}

variable "subnet_count_per_vpc" {
  description = "Set the total number of subnets you want to create in the VPC"
  type        = number
  default     = 2
}

variable "bucket_names" {
  description = "Create yours buckets"
  type        = list(string)
}

