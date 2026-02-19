variable "name_prefix" {
  description = "Prefix used for Name tags (e.g., lab-dev)"
  type        = string
}

variable "cidr" {
  description = "VPC CIDR"
  type        = string
}

variable "azs" {
  description = "List of AZs (must match subnet cidr list lengths)"
  type        = list(string)
}

variable "public_subnet_cidrs" {
  description = "Public subnet CIDRs, one per AZ"
  type        = list(string)
}

variable "private_subnet_cidrs" {
  description = "Private subnet CIDRs, one per AZ"
  type        = list(string)
}

variable "tags" {
  description = "Common tags applied to resources"
  type        = map(string)
  default     = {}
}
