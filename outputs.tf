output "subnet_ids" {
  description = "List of subnet IDs created"
  value       = aws_subnet.subnets[*].id
}
# Create an output for the security group ID
output "webserver_security_group_id" {
  value = aws_security_group.webserver_sg.id
}

output "site_vpc" { 
  value = aws_vpc.site_vpc.id
  }
