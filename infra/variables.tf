variable "aws_region" {
  default = "us-east-1"
}
variable "Owner" {
  default = "vasu.bhimani@intuitive.ai"
}
variable "Name" {
  default = "Task-6-cicd"
}
variable "Project" {
  default = "Task-6"
}

variable "ec2_ami" {
  default = "ami-0ea87431b78a82070"
}

variable "ec2_instance_type" {
  default = "t3.micro"

}

variable "key_pair" {
  default = "vasu-master"
}

variable "security_group_allow_port" {
  default = [80, 5000, 22]
}

variable "repo_name" {
  default = "vasu/task-6"
}
