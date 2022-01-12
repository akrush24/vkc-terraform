
variable "instances" { type = map(any) }
variable "networks" { type = map(any) }
variable "external_network_name" { type = string }
variable "router_name" { type = string }

variable "availability_zone" { type = string }
variable "public_key" { type = string }
variable "public_key_name" { type = string }
variable "image_name" { type = string }
variable "vip" { type = map(any) }
