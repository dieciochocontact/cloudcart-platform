output "alb_dns_name" {
  value = aws_lb.main.dns_name
}

output "app_security_group_id" {
  value = aws_security_group.app.id
}

output "alb_arn_suffix" {
  value = aws_lb.main.arn_suffix
}

output "target_group_arn_suffix" {
  value = aws_lb_target_group.app.arn_suffix
}

output "asg_name" {
  value = aws_autoscaling_group.app.name
}