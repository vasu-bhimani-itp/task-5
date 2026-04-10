module "vpc" {
  source = "./modules/vpc"
}

module "ec2" {
  source = "./modules/ec2"
  main_vpc_id = module.vpc.aws_vpc_id
  public_subnet_id = module.vpc.main_public_subnet_id
}