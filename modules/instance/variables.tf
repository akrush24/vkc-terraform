variable "instance_name" { type = string }
variable "key_pair" { type = string }
variable "flavor_name" { type = string }
variable "image_name" { type = string }
variable "availability_zone" { type = string }
variable "volumes" { type = map(any) }
variable "interfaces" { type = map(any) }
variable "networks" { type = map(any) }