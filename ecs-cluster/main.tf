#
# ECS Cluster
resource "aws_ecs_cluster" "ecs_cluster" {
  name = var.ecs_cluster_name
  default_capacity_provider_strategy {
    capacity_provider = aws_ecs_capacity_provider.ecs_cluster_capacity.name
  }
  capacity_providers  = [
    aws_ecs_capacity_provider.ecs_cluster_capacity.name
  ]
}


#
# ECS Capacity provider
resource "aws_ecs_capacity_provider" "ecs_cluster_capacity" {
  name = format("%s-%s-%s", var.ecs_cluster_name, "cluster-capacity", random_string.capacity_provider_postfix.result)

  auto_scaling_group_provider {
    auto_scaling_group_arn         = aws_autoscaling_group.ecs_autoscaling_group.arn
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
  length  = 5
  special = false
  upper   = false
}

#
# Autoscaling group
resource "aws_autoscaling_group" "ecs_autoscaling_group" {
  lifecycle {
    create_before_destroy = true
  }

  name                      = format("%s-%s", var.ecs_cluster_name, "autoscaling-group")
  max_size                  = var.asg_max_size
  min_size                  = var.asg_min_size
  desired_capacity          = var.asg_desired_capacity
  health_check_grace_period = 300
  health_check_type         = "EC2"
  /*To enable managed termination protection for a capacity provider,
  the Auto Scaling group must have instance protection from scale in enabled.*/
  protect_from_scale_in     = true

  launch_template {
    id      = aws_launch_template.ecs_launch_template.id
    version = aws_launch_template.ecs_launch_template.latest_version
  }

  vpc_zone_identifier       = var.vpc_subnet
}


#
# Launch template
resource "aws_launch_template" "ecs_launch_template" {

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
    security_groups             = [aws_security_group.ecs_security_group.id]
    delete_on_termination       = true
  }

  instance_type           = "t3.small"

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