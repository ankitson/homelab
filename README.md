# Devops tooling for homelab

This repo holds the operations related tooling for the homelab. Right now, it creates an instance on Hetzner Cloud with Docker installed using Terraform.

# TODO

- is cloud-init even running? directories not created, tailscale not installed, nginx doesnt seem to be running until i check the status with systemctl?


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
