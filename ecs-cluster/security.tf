#
# VPC data
data "aws_vpc" "main" {
  id = var.vpc_id
}


#
# Security group for ECS EC2 instances
resource "aws_security_group" "ec2_security_group" {
  count = var.capacity_provider_ec2 == "true" ? 1 : 0

  name        = format("%s-%s", var.ecs_cluster_name, "ecs-ec2-sg")
  vpc_id      = data.aws_vpc.main.id
  description = format("ECS %s EC2 Security Group", var.ecs_cluster_name)

  ingress {
    from_port = 22
    protocol  = "tcp"
    to_port   = 22
  }
  ingress {
    security_groups = [aws_security_group.alb_security_group.id]
    from_port = 0
    protocol  = "-1"
    to_port   = 0
  }
  egress {
    from_port = 0
    protocol  = "-1"
    to_port   = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}


#
# Security group for ECS Application Load Balancer
resource "aws_security_group" "alb_security_group" {

  name        = format("%s-%s", var.ecs_cluster_name, "ecs-alb-sg")
  vpc_id      = data.aws_vpc.main.id
  description = format("ECS %s ALB Security Group", var.ecs_cluster_name)
}


#
# Inbound rules
# Allow only ports are in variables ports_ingress & default_ports_ingress
resource "aws_security_group_rule" "alb_security_group_ingress" {
  for_each = toset(concat(var.ports_ingress, var.default_ports_ingress))

  from_port         = tonumber(each.key)
  to_port           = tonumber(each.key)
  protocol          = "tcp"
  security_group_id = aws_security_group.alb_security_group.id
  type              = "ingress"
  cidr_blocks       = ["0.0.0.0/0"]
}
