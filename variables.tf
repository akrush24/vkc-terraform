
variable "instances" { type = map(any) }
variable "networks" { type = map(any) }
variable "external_network_name" { type = string }
variable "router_name" { type = string }

variable "availability_zone" { type = string }
variable "key_pair" { type = string }
variable "image_name" { type = string }
variable "vip" { type = map(any) }