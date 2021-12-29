terraform {
  required_providers {
    openstack = {
      source  = "terraform-provider-openstack/openstack"
      version = "1.45.0"
    }
  }
}

data "openstack_images_image_v2" "image" {
  name = var.image_name
}

resource "openstack_blockstorage_volume_v3" "volumes" {
  for_each = var.volumes

  image_id             = each.value.from_image ? data.openstack_images_image_v2.image.id : ""
  name                 = "${each.key}-${var.instance_name}"
  size                 = each.value.size
  volume_type          = each.value.type
  availability_zone    = var.availability_zone
  enable_online_resize = true
}

# data "openstack_networking_network_v2" "networks" {
#   for_each = var.networks

#   name = each.key
# }

data "openstack_networking_subnet_v2" "subnets" {
  for_each = var.interfaces

  name = "${each.value.name}_subnet"
}


resource "openstack_networking_port_v2" "ports" {
  for_each = var.interfaces

  name       = each.value.name
  network_id = var.networks[each.value.name].networks.id
  #admin_state_up = var.admin_state_up
  fixed_ip {
    subnet_id  = data.openstack_networking_subnet_v2.subnets[each.key].id
    ip_address = each.value.ip
  }
  no_security_groups    = each.value.port_security_enabled ? false : true
  port_security_enabled = each.value.port_security_enabled
  security_group_ids    = each.value.port_security_enabled ? each.value.security_group : []

  dynamic "allowed_address_pairs" {
    for_each = each.value.port_security_enabled ? each.value.allowed_address_pairs : []

    content {
      ip_address = allowed_address_pairs.value
    }
  }

}

# create instance
resource "openstack_compute_instance_v2" "instance" {
  name         = var.instance_name
  key_pair     = var.key_pair
  flavor_name  = var.flavor_name
  config_drive = true

  dynamic "network" {
    for_each = var.interfaces

    content {
      name = network.value.name
      port = openstack_networking_port_v2.ports[network.key].id
    }
  }

  dynamic "block_device" {
    for_each = var.volumes

    content {
      uuid                  = openstack_blockstorage_volume_v3.volumes[block_device.key].id
      source_type           = "volume"
      destination_type      = "volume"
      delete_on_termination = true
      boot_index            = block_device.value.from_image == true ? 0 : 1
    }

  }

  #user_data = each.value.user_data != "" ? file(each.value.user_data) : null

  # do not delete the instance if the user_data has changed
  lifecycle {
    ignore_changes = [
      user_data
    ]
  }
}

output "volumes" {
  value = openstack_blockstorage_volume_v3.volumes
}

output "port" {
  value = openstack_networking_port_v2.ports
}

