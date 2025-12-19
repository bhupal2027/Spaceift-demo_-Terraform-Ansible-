output "aws_instances" {
  value = {
    for name, instance in aws_instance.this :
    name => instance.public_ip
  }
}
