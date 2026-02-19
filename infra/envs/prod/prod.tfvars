aws_region  = "us-east-1"
project     = "lab"
environment = "prod"

vpc_cidr = "10.30.0.0/16"

azs = ["us-east-1a", "us-east-1b"]

public_subnet_cidrs  = ["10.30.10.0/24", "10.30.11.0/24"]
private_subnet_cidrs = ["10.30.20.0/24", "10.30.21.0/24"]
