# nomad-cluster

Builds a nomad cluster and joins all clients and servers using awscli commands
rather than depending on consul.

Requires a pre-existing VPC, subnet(s) and SSH key.

Defaults to 3 nomad servers and 5 nomad clients of the t2.micro instance type.
