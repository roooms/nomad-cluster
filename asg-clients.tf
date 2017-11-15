data "template_file" "init_client" {
  template = "${file("${path.module}/user-data.tpl")}"

  vars = {
    agent_type       = "client"
    bootstrap_expect = 0 # not applicable for client asg
    region           = "${var.region}"
    server_asg_name  = "${var.cluster_name}-servers"
  }
}

resource "aws_launch_configuration" "client" {
  associate_public_ip_address = false
  ebs_optimized               = false
  iam_instance_profile        = "${aws_iam_instance_profile.nomad_instance_profile.id}"
  image_id                    = "ami-785db401"
  instance_type               = "${var.instance_type}"
  user_data                   = "${data.template_file.init_client.rendered}"
  key_name                    = "${var.ssh_key_name}"

  security_groups = [
    "${aws_security_group.general.id}",
    "${aws_security_group.nomad.id}",
  ]

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "client" {
  launch_configuration = "${aws_launch_configuration.client.id}"
  vpc_zone_identifier  = ["${var.subnet_ids}"]
  name                 = "${var.cluster_name}-clients"
  max_size             = "${var.client_instance_count}"
  min_size             = "${var.client_instance_count}"
  desired_capacity     = "${var.client_instance_count}"
  default_cooldown     = 30
  force_delete         = true

  tag {
    key                 = "Name"
    value               = "${var.cluster_name}-client"
    propagate_at_launch = true
  }
}
