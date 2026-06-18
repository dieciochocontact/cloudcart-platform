variable "project_name" {
  description = "Nombre del proyecto"
  type        = string
}

variable "vpc_id" {
  description = "ID de la VPC"
  type        = string
}

variable "private_data_subnet_ids" {
  description = "IDs de las subnets privadas de datos"
  type        = list(string)
}

variable "app_security_group_id" {
  description = "Security group de las EC2 de aplicación, para permitirles acceso a la BD"
  type        = string
}

variable "db_username" {
  description = "Usuario administrador de la base de datos"
  type        = string
  default     = "vaultpayadmin"
}

variable "db_instance_class" {
  description = "Tamaño de la instancia RDS"
  type        = string
  default     = "db.t3.micro"
}