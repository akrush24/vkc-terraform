networks = {
  vkc01_portal = {
    # доступ к порталу наружу (nginx, haproxy)
    cidr            = "192.168.24.0/24"
    gateway_ip      = "192.168.24.1"
    admin_state_up  = true
    dns_nameservers = ["192.168.26.19"]
    enable_dhcp     = false
    routed          = true
  }
  vkc01_int = {
    # резерв (не используется), нужно ее под storage сеть пустить, 
    cidr            = "192.168.25.0/24"
    gateway_ip      = "192.168.25.1"
    admin_state_up  = true
    dns_nameservers = ["192.168.26.19"]
    enable_dhcp     = false
    routed          = false
  }
  vkc01_app = {
    # сеть для локальных сервисов стека (db, rabbit и т.п.)
    cidr            = "192.168.26.0/24"
    gateway_ip      = "192.168.26.1"
    admin_state_up  = true
    dns_nameservers = ["192.168.26.19"]
    enable_dhcp     = false
    routed          = false
  }
  vkc01_ext = {
    # FIP 
    cidr            = "192.168.27.0/24"
    gateway_ip      = "192.168.27.1"
    admin_state_up  = true
    dns_nameservers = ["192.168.26.19"]
    enable_dhcp     = false
    routed          = true
  }
}

# security group list
# 7654de6f-e7d3-4fe7-982a-080c5892f7af - web_ssh
# cb6f1529-22f6-49c3-bc01-50f3627bff3d - all-to-all
vip = {
  # Плавающие адреса для VRRP
  portal = {
    net                   = "vkc01_portal"
    ip                    = "192.168.24.20"
    port_security_enabled = false
    security_group        = ["cb6f1529-22f6-49c3-bc01-50f3627bff3d"]
    fip                   = false
  }
  int = {
    net                   = "vkc01_app"
    ip                    = "192.168.26.20"
    port_security_enabled = false
    security_group        = []
    fip                   = false
  }
}

# specification for all instances
instances = {
  "vkc01deploy" = {
    flavor_name = "Standard-4-4"
    interfaces = {
      vkc01_portal = {
        name                  = "vkc01_portal"
        ip                    = "192.168.24.19"
        port_security_enabled = false
        security_group        = ["cb6f1529-22f6-49c3-bc01-50f3627bff3d"]
        allowed_address_pairs = []
      }
      vkc01_int = {
        name                  = "vkc01_int"
        ip                    = "192.168.25.19"
        port_security_enabled = false
        security_group        = []
        allowed_address_pairs = []
      }
      vkc01_app = {
        name                  = "vkc01_app"
        ip                    = "192.168.26.19"
        port_security_enabled = false
        security_group        = []
        allowed_address_pairs = []
      }
    }
    volumes = {
      root = {
        type       = "ssd"
        size       = 150
        from_image = true
      }
    }
  }
  "vkc01ctrl01" = {
    flavor_name = "Advanced-8-24"
    interfaces = {
      vkc01_portal = {
        name                  = "vkc01_portal"
        ip                    = "192.168.24.21"
        port_security_enabled = false
        security_group        = ["cb6f1529-22f6-49c3-bc01-50f3627bff3d"]
        allowed_address_pairs = ["192.168.24.20", "192.168.24.21"]
      }
      vkc01_int = {
        name                  = "vkc01_int"
        ip                    = "192.168.25.21"
        port_security_enabled = false
        security_group        = []
        allowed_address_pairs = []
      }
      vkc01_app = {
        name                  = "vkc01_app"
        ip                    = "192.168.26.21"
        port_security_enabled = false
        security_group        = ["cb6f1529-22f6-49c3-bc01-50f3627bff3d"]
        allowed_address_pairs = ["192.168.26.20"]
      }
      vkc01_ext = {
        name                  = "vkc01_ext"
        ip                    = "192.168.27.21"
        port_security_enabled = false
        security_group        = []
        allowed_address_pairs = []
      }
    }
    volumes = {
      root = {
        type       = "high-iops"
        size       = 130
        from_image = true
      }
    }
  }
  "vkc01ctrl02" = {
    flavor_name = "Advanced-8-24"
    interfaces = {
      vkc01_portal = {
        name                  = "vkc01_portal"
        ip                    = "192.168.24.22"
        port_security_enabled = false
        security_group        = ["cb6f1529-22f6-49c3-bc01-50f3627bff3d"]
        allowed_address_pairs = ["192.168.24.20", "192.168.24.22"]
      }
      vkc01_int = {
        name                  = "vkc01_int"
        ip                    = "192.168.25.22"
        port_security_enabled = false
        security_group        = []
        allowed_address_pairs = []
      }
      vkc01_app = {
        name                  = "vkc01_app"
        ip                    = "192.168.26.22"
        port_security_enabled = false
        security_group        = ["cb6f1529-22f6-49c3-bc01-50f3627bff3d"]
        allowed_address_pairs = ["192.168.26.20"]
      }
      vkc01_ext = {
        name                  = "vkc01_ext"
        ip                    = "192.168.27.22"
        port_security_enabled = false
        security_group        = []
        allowed_address_pairs = []
      }
    }
    volumes = {
      root = {
        type       = "high-iops"
        size       = 130
        from_image = true
      }
    }
  }
  "vkc01ctrl03" = {
    flavor_name = "Advanced-8-24"
    interfaces = {
      vkc01_portal = {
        name                  = "vkc01_portal"
        ip                    = "192.168.24.23"
        port_security_enabled = false
        security_group        = ["cb6f1529-22f6-49c3-bc01-50f3627bff3d"]
        allowed_address_pairs = ["192.168.24.20", "192.168.24.23"]
      }
      vkc01_int = {
        name                  = "vkc01_int"
        ip                    = "192.168.25.23"
        port_security_enabled = false
        security_group        = []
        allowed_address_pairs = []
      }
      vkc01_app = {
        name                  = "vkc01_app"
        ip                    = "192.168.26.23"
        port_security_enabled = false
        security_group        = ["cb6f1529-22f6-49c3-bc01-50f3627bff3d"]
        allowed_address_pairs = ["192.168.26.20"]
      }
      vkc01_ext = {
        name                  = "vkc01_ext"
        ip                    = "192.168.27.23"
        port_security_enabled = false
        security_group        = []
        allowed_address_pairs = []
      }
    }
    volumes = {
      root = {
        type       = "high-iops"
        size       = 130
        from_image = true
      }
    }
  }
  "vkc01cmpt01" = {
    flavor_name = "VKCP_LAB-8-32"
    volumes = {
      root = {
        type       = "ceph-hdd"
        size       = 50
        from_image = true
      }
    }
    interfaces = {
      vkc01_app = {
        name                  = "vkc01_app"
        ip                    = "192.168.26.24"
        port_security_enabled = false
        security_group        = []
        allowed_address_pairs = []
      }
      vkc01_ext = {
        name                  = "vkc01_ext"
        ip                    = "192.168.27.24"
        port_security_enabled = false
        security_group        = []
        allowed_address_pairs = []
      }
    }
  }
  "vkc01cmpt02" = {
    flavor_name = "VKCP_LAB-8-32"
    volumes = {
      root = {
        type       = "ceph-hdd"
        size       = 50
        from_image = true
      }
    }
    interfaces = {
      vkc01_app = {
        name                  = "vkc01_app"
        ip                    = "192.168.26.25"
        port_security_enabled = false
        security_group        = []
        allowed_address_pairs = []
      }
      vkc01_ext = {
        name                  = "vkc01_ext"
        ip                    = "192.168.27.25"
        port_security_enabled = false
        security_group        = []
        allowed_address_pairs = []
      }
    }
  }

  "vkc01ceph01" = {
    flavor_name = "Standard-4-8-80"
    volumes = {
      root = {
        type       = "ceph-ssd"
        size       = 30
        from_image = true
      }
      ceph = {
        type       = "ceph-ssd"
        size       = 500
        from_image = false
      }
    }
    interfaces = {
      vkc01_app = {
        name                  = "vkc01_app"
        ip                    = "192.168.26.31"
        port_security_enabled = false
        security_group        = []
        allowed_address_pairs = []
      }
    }
  }

  "vkc01mon01" = {
    flavor_name = "Standard-2-6"
    volumes = {
      root = {
        type       = "ceph-ssd"
        size       = 50
        from_image = true
      }
    }
    interfaces = {
      vkc01_app = {
        name                  = "vkc01_app"
        ip                    = "192.168.26.35"
        port_security_enabled = false
        security_group        = []
        allowed_address_pairs = []
      }
    }
  }
}

availability_zone     = "DP1"
key_pair              = "workpc"
external_network_name = "ext-net"
router_name           = "router_vkc01"
image_name            = "CentOS-7.9-202107"
