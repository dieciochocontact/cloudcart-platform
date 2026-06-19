variable "project_name" {
  description = "Nombre del proyecto"
  type        = string
}

variable "alb_arn_suffix" {
  description = "ARN suffix del ALB para las métricas de CloudWatch"
  type        = string
}

variable "target_group_arn_suffix" {
  description = "ARN suffix del target group para las métricas de CloudWatch"
  type        = string
}

variable "alert_email" {
  description = "Email para recibir las alarmas"
  type        = string
}