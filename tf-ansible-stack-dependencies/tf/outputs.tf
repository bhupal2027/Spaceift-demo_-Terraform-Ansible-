output "instance_ips" {
  description = "Public IPs of EC2 instances"
  value       = aws_instance.example[*].public_ip
}

output "instance_ids" {
  description = "Instance IDs"
  value       = aws_instance.example[*].id
}
