module "vpc" {
  source = "./modules/vpc"
}

module "ec2" {
  source = "./modules/ec2"

  instance_type = var.instance_type
  vpc_id        = module.vpc.vpc_id
  subnet_id     = module.vpc.frontend_subnet_id
}


module "rds" {
  source = "./modules/rds"

  private_subnet_id     = module.vpc.backend_subnet_id
  private_subnet_2_id   = module.vpc.backend_subnet_2_id
  vpc_id                = module.vpc.vpc_id
  ec2_security_group_id = module.ec2.security_group_id
}

module "alb" {
  source = "./modules/alb"

  vpc_id             = module.vpc.vpc_id
  public_subnet_id   = module.vpc.frontend_subnet_id
  public_subnet_2_id = module.vpc.frontend_subnet_2_id
  ec2_id             = module.ec2.instance_id
}