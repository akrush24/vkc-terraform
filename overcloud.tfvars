networks = {
  vkc01_int = {
    cidr            = "192.168.1.0/24"
    gateway_ip      = ""
    admin_state_up  = true
    dns_nameservers = ["10.255.1.111", "10.255.2.3"]
    enable_dhcp     = true
    routed          = false
    mtu             = 1450
  }
}

vip = {
  ### Плавающие адреса для VRRP
  ext = {
    net                   = "shared"
    subnet                = "shared-subnet"
    ip                    = ""
    port_security_enabled = false
    security_group        = []
    fip                   = true
  }
  int = {
    net                   = "vkc01_int"
    subnet                = "vkc01_int_subnet"
    ip                    = ""
    port_security_enabled = false
    security_group        = []
    fip                   = false
  }
}

# specification for all instances
instances = {
  deploy = {
    fip         = true
    flavor_name = "dev.deploy"
    user_data   = <<-EOF
#!/bin/bash
sudo ln -s /home/centos /home/kolla
sed -E -i 's/^SELINUX=.+/SELINUX=disabled/' /etc/selinux/config
reboot
EOF
    interfaces = {
      eth0 = {
        name                  = "shared"
        subnet                = "shared-subnet"
        ip                    = ""
        port_security_enabled = false
        security_group        = []
        allowed_address_pairs = []
      }
      eth1 = {
        name                  = "vkc01_int"
        subnet                = "vkc01_int_subnet"
        ip                    = ""
        port_security_enabled = false
        security_group        = []
        allowed_address_pairs = []
      }
    }
    volumes = {
      root = {
        type       = "ceph"
        size       = 250
        from_image = true
      }
    }
  }
  controller01 = {
    fip         = false
    flavor_name = "dev.controller"
    user_data   = <<-EOF
#!/bin/bash
sed -E -i 's/^SELINUX=.+/SELINUX=disabled/' /etc/selinux/config
reboot
EOF
    interfaces = {
      eth0 = {
        name                  = "shared"
        subnet                = "shared-subnet"
        ip                    = ""
        port_security_enabled = false
        security_group        = []
        allowed_address_pairs = []
      }
      eth1 = {
        name                  = "vkc01_int"
        subnet                = "vkc01_int_subnet"
        ip                    = ""
        port_security_enabled = false
        security_group        = []
        allowed_address_pairs = []
      }
      eth2 = {
        name                  = "vkc01_int"
        subnet                = "vkc01_int_subnet"
        ip                    = ""
        port_security_enabled = false
        security_group        = []
        allowed_address_pairs = []
      }
    }
    volumes = {
      root = {
        type       = "ceph"
        size       = 50
        from_image = true
      }
    }
  }
  controller02 = {
    fip         = false
    flavor_name = "dev.controller"
    user_data   = <<-EOF
#!/bin/bash
sed -E -i 's/^SELINUX=.+/SELINUX=disabled/' /etc/selinux/config
reboot
EOF
    interfaces = {
      eth0 = {
        name                  = "shared"
        subnet                = "shared-subnet"
        ip                    = ""
        port_security_enabled = false
        security_group        = []
        allowed_address_pairs = []
      }
      eth1 = {
        name                  = "vkc01_int"
        subnet                = "vkc01_int_subnet"
        ip                    = ""
        port_security_enabled = false
        security_group        = []
        allowed_address_pairs = []
      }
      eth2 = {
        name                  = "vkc01_int"
        subnet                = "vkc01_int_subnet"
        ip                    = ""
        port_security_enabled = false
        security_group        = []
        allowed_address_pairs = []
      }
    }
    volumes = {
      root = {
        type       = "ceph"
        size       = 50
        from_image = true
      }
    }
  }
  controller03 = {
    fip         = false
    flavor_name = "dev.controller"
    user_data   = <<-EOF
#!/bin/bash
sed -E -i 's/^SELINUX=.+/SELINUX=disabled/' /etc/selinux/config
reboot
EOF
    interfaces = {
      eth0 = {
        name                  = "shared"
        subnet                = "shared-subnet"
        ip                    = ""
        port_security_enabled = false
        security_group        = []
        allowed_address_pairs = []
      }
      eth1 = {
        name                  = "vkc01_int"
        subnet                = "vkc01_int_subnet"
        ip                    = ""
        port_security_enabled = false
        security_group        = []
        allowed_address_pairs = []
      }
      eth2 = {
        name                  = "vkc01_int"
        subnet                = "vkc01_int_subnet"
        ip                    = ""
        port_security_enabled = false
        security_group        = []
        allowed_address_pairs = []
      }
    }
    volumes = {
      root = {
        type       = "ceph"
        size       = 50
        from_image = true
      }
    }
  }
  compute01 = {
    fip         = false
    flavor_name = "dev.compute"
    user_data   = <<-EOF
#!/bin/bash
sed -E -i 's/^SELINUX=.+/SELINUX=disabled/' /etc/selinux/config
reboot
EOF
    interfaces = {
      eth0 = {
        name                  = "shared"
        subnet                = "shared-subnet"
        ip                    = ""
        port_security_enabled = false
        security_group        = []
        allowed_address_pairs = []
      }
      eth1 = {
        name                  = "vkc01_int"
        subnet                = "vkc01_int_subnet"
        ip                    = ""
        port_security_enabled = false
        security_group        = []
        allowed_address_pairs = []
      }
      eth2 = {
        name                  = "vkc01_int"
        subnet                = "vkc01_int_subnet"
        ip                    = ""
        port_security_enabled = false
        security_group        = []
        allowed_address_pairs = []
      }
    }
    volumes = {
      root = {
        type       = "ceph"
        size       = 50
        from_image = true
      }
      cinder = {
        type       = "ceph"
        size       = 50
        from_image = false
      }
    }
  }
}

availability_zone     = "nova"
external_network_name = "external"
router_name           = "router_vkc01"
image_name            = "centos7.9.2009min"
public_key            = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC4hChe9T6e1yu9L6Al+N10SQ+UrxEOCqOyzOgWyWhbti501UXylRoUzz+dmn/KBTfK/4eUxRjyHg5oVf7rf8hUkrXFVvS3KXADEeb9SQ1XLlHsd2mGOF46be8BTH/nqHn/I0SAMY22R/7ESVivMqbnvN7nSKyvcr5BmO7djhywB8r7X8F8RJi293E1dv2wcX5mSFQna37iMz1w70f13p7/3YT8KsfiybntcnB7K1DQDozwu6yyFnUS/fyl/5SS28Srero6k1T7XtxQkhvlRHJ3JK/sZFmmanpum5B5GH4WcmY1fVGbfFoQZtnCNoqDYObHhvm9PCnI2qD5fB/DtYn3"
public_key_name       = "vkc01autodeploy"
