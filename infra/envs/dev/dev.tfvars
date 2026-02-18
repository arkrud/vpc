aws_region  = "us-east-1"
project     = "lab"
environment = "dev"

vpc_cidr = "10.10.0.0/16"

azs = ["us-east-1a", "us-east-1b"]

public_subnet_cidrs  = ["10.10.10.0/24", "10.10.11.0/24"]
private_subnet_cidrs = ["10.10.20.0/24", "10.10.21.0/24"]
