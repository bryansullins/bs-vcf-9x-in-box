terraform {
  required_version = ">= 1.5.0"

  required_providers {
    nsxt = {
      source  = "vmware/nsxt"
      version = ">= 3.10.0"
    }
    vsphere = {
      source  = "hashicorp/vsphere"
      version = ">= 2.6.0"
    }
  }
}

############################
# Providers
############################

provider "nsxt" {
  host                 = var.nsx_manager
  username             = var.nsx_username
  password             = var.nsx_password
  allow_unverified_ssl = true
}

provider "vsphere" {
  user                 = var.vc_username
  password             = var.vc_password
  vsphere_server       = var.vc_server
  allow_unverified_ssl = true
}

############################
# vSphere lookups
############################

data "vsphere_datacenter" "dc" {
  name = var.vc_datacenter
}

data "vsphere_compute_cluster" "edge_cluster" {
  name          = var.vc_compute_cluster
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_datastore" "edge_datastore" {
  name          = var.vc_datastore
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_network" "edge_mgmt_pg" {
  name          = var.edge_mgmt_portgroup
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_network" "edge_data_pg_1" {
  name          = var.edge_data_portgroup_1
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_network" "edge_data_pg_2" {
  name          = var.edge_data_portgroup_2
  datacenter_id = data.vsphere_datacenter.dc.id
}

############################
# NSX lookups (Policy objects)
############################

# vCenter registered in NSX as a Compute Manager
data "nsxt_compute_manager" "vc" {
  display_name = var.nsx_compute_manager_name
}

# Transport Zones (overlay + vlan)
data "nsxt_policy_transport_zone" "overlay_tz" {
  display_name = var.overlay_tz_name
}

data "nsxt_policy_transport_zone" "vlan_tz" {
  display_name = var.vlan_tz_name
}

# Uplink Host Switch Profile for the Edge host switch
data "nsxt_policy_uplink_host_switch_profile" "edge_uplink_profile" {
  display_name = var.edge_uplink_profile_name
}

# Static IP Pool for TEPs (your "ip_pool_id" equivalent)
# If you already have the pool, look it up:
data "nsxt_policy_ip_pool" "tep_pool" {
  display_name = var.tep_ip_pool_name
}

############################
# Edge definitions
############################

locals {
  edges = {
    edge01a = {
      hostname   = "edge01a.${var.dns_domain}"
      mgmt_ip    = "172.30.0.17"
      mgmt_gw    = "172.30.0.1"
      # If you want per-edge data portgroups, put overrides here.
      # Otherwise both edges use the same two data pgs.
      data_pgs = [
        data.vsphere_network.edge_data_pg_1.id,
        data.vsphere_network.edge_data_pg_2.id
      ]
    }
    edge01b = {
      hostname = "edge01b.${var.dns_domain}"
      mgmt_ip  = "172.30.0.18"
      mgmt_gw  = "172.30.0.1"
      data_pgs = [
        data.vsphere_network.edge_data_pg_1.id,
        data.vsphere_network.edge_data_pg_2.id
      ]
    }
  }
}

############################
# Deploy Edge VMs + convert to Edge Transport Nodes
############################
# This resource example mirrors common working configs used in the provider community
# (two standard_host_switch blocks, vm_deployment_config, node_settings). :contentReference[oaicite:2]{index=2}

resource "nsxt_edge_transport_node" "edge" {
  for_each = local.edges

  display_name = each.key
  description  = "Terraform deployed Edge Transport Node ${each.key}"

  # Host switch #1 (typically Overlay/Geneve TEP)
  standard_host_switch {
    host_switch_name = "nsxDefaultHostSwitch" # optional; can also use "Overlay" naming if desired
    host_switch_id   = "nsxDefaultHostSwitch" # leave out if you prefer provider to manage; keep consistent per your design

    # TEP assignment via static pool
    ip_assignment {
      static_ip_pool = data.nsxt_policy_ip_pool.tep_pool.realized_id
    }

    vlan = var.tep_vlan_id # e.g. 60

    transport_zone_endpoint {
      transport_zone = data.nsxt_policy_transport_zone.overlay_tz.id
      # Optional TZ profiles, e.g. BFD HM profile IDs, if you have them:
      # transport_zone_profiles = [var.bfd_profile_id]
    }

    host_switch_profile = [
      data.nsxt_policy_uplink_host_switch_profile.edge_uplink_profile.id
    ]

    pnic {
      device_name = "fp-eth0"
      uplink_name = "uplink-1"
    }

    pnic {
      device_name = "fp-eth1"
      uplink_name = "uplink-2"
    }
  }

  # Host switch #2 (often VLAN TZ attachment)
  # If you don't want a second switch, remove this whole block.
  standard_host_switch {
    host_switch_name = "nsxDefaultHostSwitch" # if your NSX uses one NVDS; otherwise name it distinctly (e.g. "VLAN")
    host_switch_id   = "nsxDefaultHostSwitch"

    # Typically no TEP needed for pure VLAN TZ usage; you can DHCP or omit
    ip_assignment {
      assigned_by_dhcp = true
    }

    transport_zone_endpoint {
      transport_zone = data.nsxt_policy_transport_zone.vlan_tz.id
      # transport_zone_profiles = [var.bfd_profile_id]
    }

    host_switch_profile = [
      data.nsxt_policy_uplink_host_switch_profile.edge_uplink_profile.id
    ]

    # If you want to dedicate a pNIC for VLAN TZ, specify it here.
    # If you prefer same pNIC mapping model as above, keep consistent.
    pnic {
      device_name = "fp-eth1"
      uplink_name = "uplink-2"
    }
  }

  deployment_config {
    form_factor = var.edge_form_factor # SMALL/MEDIUM/LARGE

    node_user_settings {
      cli_password  = var.edge_cli_password
      root_password = var.edge_root_password
    }

    vm_deployment_config {
      vc_id      = data.nsxt_compute_manager.vc.id
      compute_id = data.vsphere_compute_cluster.edge_cluster.id
      storage_id = data.vsphere_datastore.edge_datastore.id

      management_network_id = data.vsphere_network.edge_mgmt_pg.id
      data_network_ids      = each.value.data_pgs

      management_port_subnet {
        ip_addresses  = [each.value.mgmt_ip]
        prefix_length = var.edge_mgmt_prefix
      }

      default_gateway_address = [each.value.mgmt_gw]

      # Optional: target a specific host
      # host_id = data.vsphere_host.some_host.id

      # Optional reservations (if you want 100% mem, etc.)
      # reservation_info {
      #   memory_reservation { reservation_percentage = 100 }
      #   cpu_reservation    { reservation_in_shares  = "HIGH_PRIORITY" }
      # }
    }
  }

  node_settings {
    hostname             = each.value.hostname
    enable_ssh           = var.edge_enable_ssh
    allow_ssh_root_login = var.edge_allow_root_ssh

    dns_servers    = var.edge_dns_servers
    ntp_servers    = var.edge_ntp_servers
    search_domains = [var.dns_domain]
  }
}

############################
# Variables
############################

variable "nsx_manager" {}
variable "nsx_username" {}
variable "nsx_password" {}

variable "vc_server" {}
variable "vc_username" {}
variable "vc_password" {}
variable "vc_datacenter" {}
variable "vc_compute_cluster" {}
variable "vc_datastore" {}

variable "nsx_compute_manager_name" {
  description = "Display name of the vCenter compute manager object in NSX"
}

variable "overlay_tz_name" {}
variable "vlan_tz_name" {}
variable "edge_uplink_profile_name" {}
variable "tep_ip_pool_name" {}

variable "tep_vlan_id" {
  type    = number
  default = 60
}

variable "edge_form_factor" {
  default = "MEDIUM"
}

variable "edge_mgmt_portgroup" {}
variable "edge_data_portgroup_1" {}
variable "edge_data_portgroup_2" {}

variable "edge_mgmt_prefix" {
  type    = number
  default = 24
}

variable "dns_domain" {}
variable "edge_dns_servers" {
  type = list(string)
}
variable "edge_ntp_servers" {
  type = list(string)
}

variable "edge_cli_password" { sensitive = true }
variable "edge_root_password" { sensitive = true }

variable "edge_enable_ssh" {
  type    = bool
  default = false
}
variable "edge_allow_root_ssh" {
  type    = bool
  default = false
}
