# Devops tooling for homelab

This repo holds the operations related tooling for the homelab. Right now, it creates an instance on Hetzner Cloud with Docker installed using Terraform.

# Terraform stuff

- You can import resources defined online. e.g define a firewall in hetzner cloud UI, look at its ID, then do:

`tf import hcloud_firewall.default 1707990`

this imports it into state but not the definition. then do `terraform show` to show the copyable definitions for this new firewall

# TODO

- Get Traefik setup as reverse proxy. Maybe consider private setup with tailscale:
https://medium.com/@svenvanginkel/your-homelab-behind-tailscale-with-wildcard-dns-and-certificates-c68a881900bf

- Set up Pinokio like thing to easily spin up AI models?

## Dependencies

- [Terraform](https://developer.hashicorp.com/terraform/install?product_intent=terraform)

## Setup

- Install dependencies above

- Generate an API key from your Hetzner cloud console. Create a new file named `secrets.auto.tfvars` containing the API token like this:
```
hcloud_token = "<token here>"
```

- Create a `keys` folder, and put the private SSH key in `keys/dev.pem` with `600` permissions.

- Run `terraform init` to setup terraform and install the hetzner providers

- Install [pre-commit](https://pre-commit.com/) and run `pre-commit install` to automatically run pre-commit checks on each git commit

## Usage

To bring up an instance and connect to it:

```
> terraform plan
> terraform apply
...
Outputs:

server_ip = "<server_ip>"
server_status = "running"
ssh_command = "ssh -o StrictHostKeyChecking=no -i keys/deadlock.pem dev@<server_ip>"
> ssh -o StrictHostKeyChecking=no -i keys/deadlock.pem dev@<server_ip>
```

To destroy the instance:
```
terraform destroy
```
