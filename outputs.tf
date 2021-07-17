output "instance" {
  value     = aws_instance.node[*]
}

output "tg_port" {
  value = var.enable_lb_tg_group_attachment ? aws_alb_target_group_attachment.tg_attach[0].port : ""
}
