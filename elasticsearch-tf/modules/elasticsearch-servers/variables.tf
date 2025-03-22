variable "private_subnet_ids" {
  description = "List of private subnet IDs where Elasticsearch servers will be created"
  type        = list(string)
}

variable "elasticsearch_sg_id" {
  description = "Security group ID for Elasticsearch servers"
  type        = string
}

variable "elasticsearch_ami" {
  description = "AMI ID for Elasticsearch servers"
  type        = string
  default     = "ami-0e1bed4f06a3b463d" #(us-east)
}

variable "elasticsearch_instance_type" {
  description = "Instance type for Elasticsearch servers"
  type        = string
  default     = "t2.medium"
}
variable "key_name" {
  description = "Name of the SSH key pair to use for Elasticsearch servers"
  type        = string
}
