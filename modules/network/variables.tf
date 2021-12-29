variable "network_name" { type = string }
variable "cidr" { type = string }
variable "enable_dhcp" { type = bool }
variable "admin_state_up" { type = bool }
variable "routed" { type = bool }
variable "dns_nameservers" { type = list(string) }
variable "gateway_ip" { type = string }
variable "router_id" { type = string }
