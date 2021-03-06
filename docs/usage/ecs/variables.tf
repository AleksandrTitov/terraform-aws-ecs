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
}

variable "ecs_ec2_role" {
  description = "AMI role for ECS EC2"
}

variable "ports_ingress" {
  description = "List of an additional ingress ports for security group"
  type        = list(string)
  default     = []
}

variable "volume_size" {
  description = "The size of the volume in gigabytes"
}

variable "asg_max_size" {
  description = "The maximum size of the autoscale group"
}

variable "asg_min_size" {
  description = "The minimum size of the autoscale group"
}

variable "asg_desired_capacity" {
  description = "The number of Amazon EC2 instances that should be running in the group"
}
