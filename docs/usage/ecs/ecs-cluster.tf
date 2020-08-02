#
# ECS module
module "ecs_cluster" {
  source = "git@github.com:AleksandrTitov/terraform-aws-ecs.git//ecs-cluster?ref=v0.1.0"

  ecs_cluster_name     = var.ecs_cluster_name
  vpc_subnets          = var.vpc_subnets
  vpc_id               = var.vpc_id
  region               = var.region
  instance_type        = var.instance_type
  ports_ingress        = var.ports_ingress
  ecs_ec2_role         = var.ecs_ec2_role
  volume_size          = var.volume_size
  asg_desired_capacity = var.asg_desired_capacity
  asg_max_size         = var.asg_max_size
  asg_min_size         = var.asg_min_size
}
