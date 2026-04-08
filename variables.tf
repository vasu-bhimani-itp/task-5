variable "aws_region" {
  default = "us-east-1"
}
variable "Owner" {
  default = "vasu.bhimani@intuitive.ai"
}

variable "Project" {
  default = "task-5"
}

variable "Name" {
  default = "vasu-task-5"
}

variable "vpc_cidr" {
  default = "10.0.0.0/16"
}

variable "public_subnets_cicr" {
  default = [
    "10.0.1.0/24",
    "10.0.2.0/24"
  ]
}

variable "private_subnets_cicr" {
  default = [
    "10.0.101.0/24",
    "10.0.102.0/24"
  ]
}