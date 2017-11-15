resource "aws_security_group" "general" {
  name        = "${var.cluster_name}-general-sg"
  description = "security group for ${var.cluster_name} - general ingress and egress"
  vpc_id      = "${var.vpc_id}"

  ingress {
    description = "SSH Inbound"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "All TCP Outbound"
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "nomad" {
  name        = "${var.cluster_name}-nomad-sg"
  description = "security group for ${var.cluster_name} - nomad specific ports"
  vpc_id      = "${var.vpc_id}"

  ingress {
    description = "Nomad HTTP Internal"
    from_port   = 4646
    to_port     = 4646
    protocol    = "tcp"
    self        = true
  }

  ingress {
    description = "Nomad RPC Internal"
    from_port   = 4647
    to_port     = 4647
    protocol    = "tcp"
    self        = true
  }

  ingress {
    description = "Nomad Serf UDP Internal"
    from_port   = 4648
    to_port     = 4648
    protocol    = "udp"
    self        = true
  }

  ingress {
    description = "Nomad Serf TCP Internal"
    from_port   = 4648
    to_port     = 4648
    protocol    = "tcp"
    self        = true
  }
}
