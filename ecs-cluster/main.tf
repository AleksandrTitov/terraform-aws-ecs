#
# ECS Cluster
resource "aws_ecs_cluster" "ecs_cluster" {
  name = var.ecs_cluster_name

  capacity_providers  = concat(
  var.capacity_provider_ec2     == "true" ? [aws_ecs_capacity_provider.ecs_cluster_capacity.0.name] : [],
  var.capacity_provider_fargate == "true" ? ["FARGATE"] : []
  )
}


#
# ECS Capacity provider
resource "aws_ecs_capacity_provider" "ecs_cluster_capacity" {
  count = var.capacity_provider_ec2 == "true" ? 1 : 0

  name = format("%s-%s-%s", var.ecs_cluster_name, "cluster-capacity", random_string.capacity_provider_postfix.0.result)

  auto_scaling_group_provider {
    auto_scaling_group_arn         = aws_autoscaling_group.ecs_autoscaling_group.0.arn
    managed_termination_protection = "ENABLED"

    managed_scaling {
      status  = "ENABLED"
    }
  }
}

/*
 The AWS API does not currently support deleting ECS cluster capacity providers.
 Removing this Terraform resource will only remove the Terraform state for it.
 So to avoid duplicate, when you run deploy/destroy of, for each capacity provider
 add the random postfix.
 https://github.com/aws/containers-roadmap/issues/632
 https://www.terraform.io/docs/providers/aws/r/ecs_capacity_provider.html
*/
resource "random_string" "capacity_provider_postfix" {
  count = var.capacity_provider_ec2 == "true" ? 1 : 0

  length  = 5
  special = false
  upper   = false
}

#
# Autoscaling group
resource "aws_autoscaling_group" "ecs_autoscaling_group" {
  count = var.capacity_provider_ec2 == "true" ? 1 : 0

  lifecycle {
    create_before_destroy = true
  }

  name                      = format("%s-%s", var.ecs_cluster_name, "autoscaling-group")
  max_size                  = var.asg_max_size
  min_size                  = var.asg_min_size
  desired_capacity          = var.asg_desired_capacity
  health_check_grace_period = 300
  health_check_type         = "EC2"
  /* To enable managed termination protection for a capacity provider,
  the Auto Scaling group must have instance protection from scale in enabled. */
  protect_from_scale_in     = true

  launch_template {
    id      = aws_launch_template.ecs_launch_template.0.id
    version = aws_launch_template.ecs_launch_template.0.latest_version
  }

  tag {
    /* ECS Capacity Providers automatically adding the AmazonECSManaged tag.
    Github issue https://github.com/terraform-providers/terraform-provider-aws/issues/12582 */
    key                 = "AmazonECSManaged"
    propagate_at_launch = true
    value               = ""
  }
  vpc_zone_identifier       = var.vpc_subnets
}


#
# Launch template
resource "aws_launch_template" "ecs_launch_template" {
  count = var.capacity_provider_ec2 == "true" ? 1 : 0

  name          = format("%s-%s", var.ecs_cluster_name, "launch-template")
  image_id      = data.aws_ami.ecs_ami.image_id

  block_device_mappings {
    device_name = "/dev/sda1"
    ebs {
      volume_size = var.volume_size
      volume_type = "gp2"
    }
  }

  user_data = base64encode(
  /*
  ECS Agent configuration   https://docs.aws.amazon.com/AmazonECS/latest/developerguide/ecs-agent-config.html
  User Data by cloud-init   https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/user-data.html#user-data-cloud-init
  cloud-init docs           https://cloudinit.readthedocs.io/en/latest/index.html
  */
  templatefile(
  "${path.module}/data/user_data.yaml",{
    ecs_cluster_name = var.ecs_cluster_name
  }
  )
  )

  network_interfaces {
    device_index                = 0
    associate_public_ip_address = false
    security_groups             = [aws_security_group.ec2_security_group.0.id]
    delete_on_termination       = true
  }

  #TODO: remove a key, for now, it's for a test purposes
  key_name                = "atitov"
  instance_type           = var.instance_type

  iam_instance_profile {
    name = var.ecs_ec2_role
  }
}


#
# Get the latest AWS ECS optimized AMI
data "aws_ami" "ecs_ami" {

  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn-ami-*-amazon-ecs-optimized"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}


#
# Application Load Balancer
resource "aws_lb" "ecs_alb" {
  name               = format("%s-%s", var.ecs_cluster_name, "ecs-alb")
  internal           = true
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_security_group.id]
  subnets            = var.vpc_subnets

  //enable_deletion_protection = true
}
