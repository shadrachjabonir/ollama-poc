variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "g5.2xlarge"
}

variable "spot_price" {
  description = "Maximum hourly price you're willing to pay for the Spot Instance"
  type        = string
  default     = "0.752" # Misalnya, $0.30 per jam
}

variable "public_key_path" {
  description = "Path to public key file (e.g., ~/.ssh/poc-mcp.pub)"
  type        = string
  default     = "~/.ssh/poc-mcp.pub"
}
