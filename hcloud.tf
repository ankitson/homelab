terraform {
  required_version = ">= 1.9.6"
  required_providers {
    hcloud = {
      source  = "hetznercloud/hcloud"
      version = "~> 1.45"
    }
    tailscale = {
      source  = "tailscale/tailscale"
      version = ">= 0.17.2"
    }
  }
}

# PROVIDERS

provider "hcloud" {
  token = var.hcloud_token
}

provider "tailscale" {
  api_key = var.tailscale_token
}

# VARS

variable "hcloud_token" {
  sensitive = true
  type      = string
}

variable "tailscale_token" {
  sensitive = true
  type      = string
}

variable "ssh_authorized_key" {
  description = "The public key to be added to the SSH authorized keys on the server"
  type        = string
}

# RESOURCES

resource "hcloud_ssh_key" "dev_key" {
  name       = "dev_key"
  public_key = var.ssh_authorized_key
}

resource "hcloud_server" "backend" {
  name               = "homelab"
  image              = "docker-ce"
  server_type        = "cpx11"
  location           = "hil"
  delete_protection  = false
  rebuild_protection = false
  ssh_keys           = [hcloud_ssh_key.dev_key.id]
  user_data = templatefile("${path.module}/user_data.yaml.tpl", {
    ssh_authorized_key = var.ssh_authorized_key
    tailscale_token    = var.tailscale_token
  })
  # Only needed for provisioners
  # connection {
  #   type        = "ssh"
  #   user        = "dev"
  #   private_key = file("./keys/dev.pem")
  #   host        = self.ipv4_address
  # }

  public_net {
    ipv4_enabled = true
    ipv6_enabled = false
  }
}

# OUTPUTS

output "server_ip" {
  value       = hcloud_server.backend.ipv4_address
  description = "The public IP address of the server"
}

output "server_status" {
  value       = hcloud_server.backend.status
  description = "The status of the server"
}

output "ssh_command" {
  value       = "ssh -o StrictHostKeyChecking=no -i keys/dev.pem dev@${hcloud_server.backend.ipv4_address}"
  description = "SSH command to connect to the server"
}
