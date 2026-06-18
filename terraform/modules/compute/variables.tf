variable "project_name" {
  description = "Nombre del proyecto"
  type        = string
}

variable "vpc_id" {
  description = "ID de la VPC donde se desplegará el compute"
  type        = string
}

variable "public_subnet_ids" {
  description = "IDs de las subnets públicas (para el ALB)"
  type        = list(string)
}

variable "private_app_subnet_ids" {
  description = "IDs de las subnets privadas de aplicación (para las EC2)"
  type        = list(string)
}

variable "instance_type" {
  description = "Tipo de instancia EC2"
  type        = string
  default     = "t3.micro"
}

variable "instance_count" {
  description = "Número de instancias EC2 a desplegar"
  type        = number
  default     = 3
}

variable "key_name" {
  description = "Nombre del key pair SSH"
  type        = string
}