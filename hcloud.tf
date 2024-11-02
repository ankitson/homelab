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
  # sensitive = true
  type = string
}

variable "tailscale_api_key" {
  # sensitive = true
  type = string
}

variable "tailscale_token" {
  # sensitive = true
  type = string
}

variable "tailscale_hostname" {
  type = string
}

variable "ssh_authorized_key" {
  description = "The public key to be added to the SSH authorized keys on the server"
  type        = string
}

# locals {
#   tailscale_api_key  = var.tailscale_api_key
#   tailscale_hostname = "homelab"
# }

# locals {
#   cleanup_tailscale_sh = templatefile("${path.module}/cleanup-tailscale.sh.tpl", {
#     tailscale_api_key  = var.tailscale_api_key
#     tailscale_hostname = var.tailscale_hostname
#   })
#   rendered_user_data = templatefile("${path.module}/user_data.yaml.tpl", {
#     ssh_authorized_key           = var.ssh_authorized_key
#     tailscale_token              = var.tailscale_token
#     tailscale_hostname           = var.tailscale_hostname
#     cleanup_tailscale_sh_content = local.cleanup_tailscale_sh
#   })
# }

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
    tailscale_hostname = var.tailscale_hostname
    tailscale_api_key  = var.tailscale_api_key
    # cleanup_tailscale_sh_content = local.cleanup_tailscale_sh
  })
  # user_data = local.rendered_user_data

  # Only needed for provisioners
  # connection {
  #   type        = "ssh"
  #   user        = "dev"
  #   private_key = file("./keys/dev.pem")
  #   host        = self.ipv4_address
  # }
  # provisioner "file" {
  #   source      = "cleanup.sh"
  #   destination = "/home/dev/cleanup-tailscale.sh"
  # }
  # provisioner "remote-exec" {
  #   inline = [
  #     # "sudo mv /home/dev/cleanup-tailscale.sh /usr/local/bin/cleanup-tailscale.sh",
  #     "sudo cloud-init status --wait",
  #     "sudo apt update",
  #     "sudo apt install -y jq",
  #     "export TAILSCALE_API_KEY=${var.tailscale_api_key}",
  #     "export TAILSCALE_HOSTNAME=${var.tailscale_hostname}",
  #     "sudo chmod +x /home/dev/cleanup-tailscale.sh",
  #     "TAILSCALE_API_KEY=${var.tailscale_api_key} TAILSCALE_HOSTNAME=${var.tailscale_hostname} /home/dev/cleanup-tailscale.sh"
  #   ]
  # }
  # Add destroy-time provisioner
  # provisioner "remote-exec" {
  #   when = destroy
  #   inline = [
  #     "sudo tailscale logout", # This will unregister the node from Tailscale
  #   ]
  #   on_failure = continue # Optional: continue even if the logout fails
  # }
  # provisioner "remote-exec" {
  #   when = destroy
  #   inline = [
  #     "echo 'Starting Tailscale cleanup...'",
  #     "sudo tailscale status", # Show current status
  #     "echo 'Running tailscale logout...'",
  #     "sudo tailscale logout", # More thorough logout
  #     "echo 'Tailscale logout complete'",
  #     "sudo tailscale status", # Verify status after logout
  #   ]
  #   on_failure = continue
  # }
  # provisioner "local-exec" {
  #   when    = destroy
  #   command = <<-EOT
  #   curl -X DELETE \
  #   -H "Authorization: Bearer ${local.tailscale_api_key}" \
  #   "https://api.tailscale.com/api/v2/device/homelab"
  # EOT
  #   # command = "curl -X DELETE -H 'Authorization: Bearer ${self.provisioner.local-exec.environment.TAILSCALE_API_KEY}' 'https://api.tailscale.com/api/v2/device/homelab'"
  #   # environment = {
  #   #   TAILSCALE_API_KEY  = var.tailscale_api_key
  #   #   TAILSCALE_HOSTNAME = var.tailscale_hostname
  #   # }
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

output "rendered_user_data" {
  value = hcloud_server.backend.user_data
  # sensitive = true
}
