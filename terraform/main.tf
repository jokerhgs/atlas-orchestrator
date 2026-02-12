module "network" {
  source               = "./modules/network"
  project_name         = var.project_name
  vpc_cidr             = var.vpc_cidr
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  availability_zones   = var.availability_zones
}

module "iam" {
  source       = "./modules/iam"
  project_name = var.project_name
}

module "s3" {
  source       = "./modules/s3"
  project_name = var.project_name
}

module "ec2" {
  count                = 4
  source               = "./modules/ec2"
  aws_region           = var.aws_region
  instance_name        = count.index == 0 ? "${var.project_name}-control-plane" : (count.index == 3 ? "${var.project_name}-monitoring" : "${var.project_name}-worker-${count.index}")
  instance_type        = count.index == 3 ? "t4g.medium" : "t4g.small" # Monitoring node gets 4GB RAM
  subnet_id            = module.network.private_subnet_ids[count.index % length(module.network.private_subnet_ids)]
  security_group_ids   = [module.network.private_security_group_id]
  iam_instance_profile = module.iam.instance_profile_name
  root_volume_size     = 30

  tags = {
    Role    = count.index == 0 ? "control-plane" : (count.index == 3 ? "monitoring" : "worker")
    Project = var.project_name
  }
}
