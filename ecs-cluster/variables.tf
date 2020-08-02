#
# ECS configuration
variable "ecs_cluster_name" {
  description = "AWS ECS cluster name"
}


#
# VPC configuration
variable "vpc_subnets" {
  description = "A list of subnet IDs, at least two subnets in two different Availability Zones must be specified"
  type        = list(string)
}

variable "vpc_id" {
  description = "AWS VPC ID"
}

variable "region" {
  description = "AWS region"
}


#
# EC2 configuration
variable "instance_type" {
  description = "EC2 instance type"
  default     = "t3.small"
}

variable "ecs_ec2_role" {
  description = "AMI role for ECS EC2"
}
variable "default_ports_ingress" {
  description = "Default list of ingress ports for security group"
  type        = list(string)
  default     = ["80", "443", "22"]
}

variable "ports_ingress" {
  description = "List of an additional ingress ports for security group"
  type        = list(string)
  default     = []
}

variable "volume_size" {
  description = "The size of the volume in gigabytes"
  default     = 30
}
variable "asg_max_size" {
  description = "The maximum size of the autoscale group"
  default     = 1
}
variable "asg_min_size" {
  description = "The minimum size of the autoscale group"
  default     = 1
}
variable "asg_desired_capacity" {
  description = "The number of Amazon EC2 instances that should be running in the group"
  default     = 1
}

variable "capacity_provider_fargate" {
  description = "Enable of ECS capacity provider Fargate"
  default     = "true"
}

variable "capacity_provider_ec2" {
  description = "Enable of ECS capacity provider EC2"
  default     = "false"
}
