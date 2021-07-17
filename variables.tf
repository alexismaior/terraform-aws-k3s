variable "aws_region" {}
variable "instance_count" {
  type    = number
  default = 1
}
variable "instance_type" {
  type    = string
  default = "t2.micro"
}
variable "public_sg" {}
variable "public_subnets" {}
variable "vol_size" {
  type    = number
  default = 10
}
variable "key_name" {}
variable "public_key_path" {}
variable "user_data_path" {}
variable "dbuser" {}
variable "dbpassword" {}
variable "dbendpoint" {}
variable "dbname" {}
variable "enable_lb_tg_group_attachment" {
  type    = bool
  default = false
}
variable "lb_target_group_arn" {
  type    = string
  default = ""
}
variable "tg_port" {
  type    = number
  default = 80
}
