# nomad-cluster

Builds a nomad cluster and joins all clients and servers using awscli commands
rather than depending on consul.

Requires a pre-existing VPC, subnet(s) and SSH key.

Defaults to 3 nomad servers and 5 nomad clients of the t2.micro instance type.

![Architecture Diagram](nomad-cluster.png "Architecture Diagram")

The following resources are created:

  + aws_autoscaling_group.client
  + aws_autoscaling_group.server
  + aws_iam_instance_profile.nomad_instance_profile
  + aws_iam_role.nomad_role
  + aws_iam_role_policy.nomad_policy
  + aws_launch_configuration.client
  + aws_launch_configuration.server
  + aws_security_group.client
  + aws_security_group.server
