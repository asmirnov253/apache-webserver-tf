output "bucket_names" {
  description = "Names of the created S3 buckets"
  value       = length(var.bucket_names)
}