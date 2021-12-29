variable "fip" { type = bool }
variable "ip" { type = string }
variable "net" { type = string }
variable "port_security_enabled" { type = bool }
variable "security_group" { type = list(string) }
variable "external_network_name" { type = string }
