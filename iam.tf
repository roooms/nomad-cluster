data "aws_iam_policy_document" "assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "self_assembly" {
  statement {
    effect    = "Allow"
    resources = ["*"]

    actions = [
      "autoscaling:DescribeAutoScalingGroups",
      "autoscaling:DescribeAutoScalingInstances",
      "ec2:DescribeAvailabilityZones",
      "ec2:DescribeInstanceAttribute",
      "ec2:DescribeInstanceStatus",
      "ec2:DescribeInstances",
      "ec2:DescribeTags",
    ]
  }
}

resource "aws_iam_role" "nomad_role" {
  name               = "${var.cluster_name}-iam-role"
  assume_role_policy = "${data.aws_iam_policy_document.assume_role.json}"
}

resource "aws_iam_role_policy" "nomad_policy" {
  role   = "${aws_iam_role.nomad_role.id}"
  policy = "${data.aws_iam_policy_document.self_assembly.json}"
}

resource "aws_iam_instance_profile" "nomad_instance_profile" {
  name = "${var.cluster_name}-instance-profile"
  role = "${aws_iam_role.nomad_role.name}"
}
