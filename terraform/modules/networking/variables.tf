variable "project_name" {
  description = "Nombre del proyecto, usado como prefijo en los nombres de recursos"
  type        = string
}

variable "vpc_cidr" {
  description = "Rango de IPs para toda la VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "Lista de AZs donde desplegar las subnets"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
}