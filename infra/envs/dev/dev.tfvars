aws_region  = "us-east-1"
project     = "lab"
environment = "dev"

vpc_cidr = "10.40.0.0/16"

azs = ["us-east-1a", "us-east-1b"]

public_subnet_cidrs  = ["10.40.10.0/24", "10.40.11.0/24"]
private_subnet_cidrs = ["10.40.20.0/24", "10.40.21.0/24"]
