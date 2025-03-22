output "elasticsearch_instance_ids" {
  value = aws_instance.elasticsearch_servers[*].id
}
