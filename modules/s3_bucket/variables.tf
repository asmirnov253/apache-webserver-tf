variable "bucket_names" {
  description = "List of S3 bucket names to create"
  type        = list(string)
  default     = []
}