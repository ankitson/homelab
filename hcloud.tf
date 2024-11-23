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

variable "tailscale_api_key" {
  sensitive = true
  type      = string
}

variable "tailscale_token" {
  sensitive = true
  type      = string
}

variable "cloudflare_token" {
  sensitive = true
  type      = string
}

variable "tailscale_hostname" {
  type = string
}

variable "ssh_authorized_key" {
  description = "The public key to be added to the SSH authorized keys on the server"
  type        = string
}

variable "access_ips" {
  type = list(string)
}

variable "cloudflare_ips" {
  type = list(string)
}

variable "deploy_domain" {
  sensitive = true
  type      = string
}

# RESOURCES

resource "hcloud_firewall" "default" {
  labels = {}
  name   = "firewall-1"

  rule {
    description     = "HTTP"
    destination_ips = []
    direction       = "in"
    port            = "80"
    protocol        = "tcp"
    source_ips      = concat(var.access_ips, var.cloudflare_ips)
  }
  rule {
    description     = "HTTPS"
    destination_ips = []
    direction       = "in"
    port            = "443"
    protocol        = "tcp"
    source_ips      = concat(var.access_ips, var.cloudflare_ips)
  }
  rule {
    description     = "HTTPS/UDP"
    destination_ips = []
    direction       = "in"
    port            = "443"
    protocol        = "udp"
    source_ips      = concat(var.access_ips, var.cloudflare_ips)
  }
  rule {
    description     = "PING"
    destination_ips = []
    direction       = "in"
    port            = null
    protocol        = "icmp"
    source_ips      = concat(var.access_ips, var.cloudflare_ips)
  }
  rule {
    description     = "SSH"
    destination_ips = []
    direction       = "in"
    port            = "22"
    protocol        = "tcp"
    source_ips      = concat(var.access_ips, var.cloudflare_ips)
  }
}

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
  firewall_ids       = [hcloud_firewall.default.id]
  ssh_keys           = [hcloud_ssh_key.dev_key.id]
  user_data = templatefile("${path.module}/user_data.yaml.tpl", {
    ssh_authorized_key = var.ssh_authorized_key
    tailscale_token    = var.tailscale_token
    tailscale_hostname = var.tailscale_hostname
    tailscale_api_key  = var.tailscale_api_key
  })

  public_net {
    ipv4_enabled = true
    ipv6_enabled = true
  }

  connection {
    type        = "ssh"
    user        = "dev"
    private_key = file("./keys/dev.pem")
    host        = self.ipv4_address
  }

  # First create directories
  provisioner "remote-exec" {
    inline = [
      "mkdir -p /home/dev/code/docker-data/actual-budget/data",
      "mkdir -p /home/dev/code/docker-data/caddy/data",
      "mkdir -p /home/dev/code/docker-data/caddy/config",
      "chown -R dev:users /home/dev"
    ]
  }
  # docker env
  provisioner "file" {
    content = templatefile("${path.module}/docker.env.tpl", {
      cloudflare_token = var.cloudflare_token,
      deploy_domain    = var.deploy_domain
    })
    destination = "/home/dev/code/.env"
  }
  provisioner "file" {
    source      = "docker-compose.yaml"
    destination = "/home/dev/code/docker-compose.yaml"
  }
  provisioner "file" {
    source      = "Caddyfile"
    destination = "/home/dev/code/Caddyfile"
  }
}

# OUTPUTS

output "server_ipv4" {
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

# output "rendered_user_data" {
# value = hcloud_server.backend.user_data
# sensitive = true
# }
