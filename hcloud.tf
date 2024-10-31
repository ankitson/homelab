terraform {
  required_providers {
    hcloud = {
      source  = "hetznercloud/hcloud"
      version = "~> 1.45"
    }
  }
}

variable "hcloud_token" {
  sensitive = true
}

variable "ssh_authorized_key" {
  description = "The public key to be added to the SSH authorized keys on the server"
  type        = string
}

provider "hcloud" {
  token = var.hcloud_token
}

resource "hcloud_ssh_key" "dev_key" {
  name       = "dev_key"
  public_key = var.ssh_authorized_key
}



# data "template_file" "user_data" {
#   template = file("user_data.yaml.tpl")
#   vars = {
#     ssh_authorized_key = var.ssh_authorized_key
#   }
# }

resource "hcloud_server" "backend" {
  name               = "homelab"
  image              = "docker-ce"
  server_type        = "cpx11"
  location           = "hil"
  delete_protection  = false
  rebuild_protection = false
  ssh_keys           = [data.hcloud_ssh_key.dev_key.id]
  user_data = templatefile("${path.module}/user_data.yaml.tpl", {
    ssh_authorized_key = var.ssh_authorized_key
  })
  connection {
    type        = "ssh"
    user        = "dev"
    private_key = file("./keys/dev.pem")
    host        = self.ipv4_address
  }

  public_net {
    ipv4_enabled = true
    ipv6_enabled = false
  }
}

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
