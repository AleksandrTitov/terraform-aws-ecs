#
# VPC data
data "aws_vpc" "main" {
  id = var.vpc_id
}


#
# Security group for ECS instances
resource "aws_security_group" "ecs_security_group" {
  name        = format("%s-%s", var.ecs_cluster_name, "security-group")
  vpc_id      = data.aws_vpc.main.id
  description = "ECS EC2 Security Group"
}


#
# Inbound rules
# Allow only ports are in variables ports_ingress & default_ports_ingress
resource "aws_security_group_rule" "ecs_security_group_ingress" {
  for_each = toset(concat(var.ports_ingress, var.default_ports_ingress))

  from_port         = tonumber(each.key)
  to_port           = tonumber(each.key)
  protocol          = "tcp"
  security_group_id = aws_security_group.ecs_security_group.id
  type              = "ingress"
  cidr_blocks       = ["0.0.0.0/0"]
}


#
# Outbound rules
# Allow all egress connections
resource "aws_security_group_rule" "ecs_security_group_egress" {
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  security_group_id = aws_security_group.ecs_security_group.id
  type              = "egress"
  cidr_blocks       = ["0.0.0.0/0"]
}
