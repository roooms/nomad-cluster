terraform {
  required_version = ">= 0.9.3"
}

provider "aws" {
  region = "${var.region}"
}

# Required variables
variable "cluster_name" {
  description = "Specify a unique cluster name"
}

variable "region" {
  description = "Specify the region to launch the cluster in"
}

variable "ssh_key_name" {
  description = "Pre-existing AWS key name you will use to access the instance(s)"
}

variable "subnet_ids" {
  type        = "list"
  description = "Pre-existing Subnet ID(s) to use"
}

variable "vpc_id" {
  description = "Pre-existing VPC ID to use"
}

# Optional variables
variable "client_instance_count" {
  default     = "5"
  description = "Number of client instances to launch in the cluster"
}

variable "server_instance_count" {
  default     = "3"
  description = "Number of server instances to launch in the cluster"
}

variable "instance_type" {
  default     = "t2.micro"
  description = "AWS instance type to use eg m4.large"
}
