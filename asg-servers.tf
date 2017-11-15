data "template_file" "init_server" {
  template = "${file("${path.module}/user-data.tpl")}"

  vars = {
    agent_type       = "server"
    bootstrap_expect = "${var.server_instance_count}"
    region           = "${var.region}"
    server_asg_name  = "${var.cluster_name}-servers"
  }
}

resource "aws_launch_configuration" "server" {
  associate_public_ip_address = false
  ebs_optimized               = false
  iam_instance_profile        = "${aws_iam_instance_profile.nomad_instance_profile.id}"
  image_id                    = "ami-785db401"
  instance_type               = "${var.instance_type}"
  user_data                   = "${data.template_file.init_server.rendered}"
  key_name                    = "${var.ssh_key_name}"

  security_groups = [
    "${aws_security_group.general.id}",
    "${aws_security_group.nomad.id}",
  ]

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "server" {
  launch_configuration = "${aws_launch_configuration.server.id}"
  vpc_zone_identifier  = ["${var.subnet_ids}"]
  name                 = "${var.cluster_name}-servers"
  max_size             = "${var.server_instance_count}"
  min_size             = "${var.server_instance_count}"
  desired_capacity     = "${var.server_instance_count}"
  default_cooldown     = 30
  force_delete         = true

  tag {
    key                 = "Name"
    value               = "${var.cluster_name}-server"
    propagate_at_launch = true
  }
}
