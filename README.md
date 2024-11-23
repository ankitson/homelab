# Devops tooling for homelab

This repo holds the operations related tooling for the homelab. It creates an instance on Hetzner Cloud with Docker installed using Terraform, then sets up a Caddy reverse proxy and some basic services. Automatically fetches SSL certs and backs them up to avoid rate-limiting, sets up tailscale access.

## Dependencies

- [Terraform](https://developer.hashicorp.com/terraform/install?product_intent=terraform)

- Docker

## Setup

- Install dependencies above

- Create a new file named `secrets.auto.tfvars` containing the secrets - hetzner, tailscale, cloudflare, access IPs etc.

- Create a `keys` folder, and put the private SSH key in `keys/dev.pem` with `600` permissions.

- Run `terraform init` to setup terraform and install the hetzner providers

- Install [pre-commit](https://pre-commit.com/) and run `pre-commit install` to automatically run pre-commit checks on each git commit

- I'm building a custom caddy image with the cloudflare and nginx modules included. It's pushed to `ankit/caddy-cloudflare` on dockerhub because remote host needs to pull.

  May need to occasionally rebuild image:
```bash
$ cd caddy
$ docker build . -t ankit/caddy-cloudflare:0.x
$ docker push ankit/caddy-cloudflare:0.x
```


## Usage

To bring up an instance and connect to it:

```
> terraform plan
> terraform apply
...
Outputs:

server_ip = "<server_ip>"
server_status = "running"
ssh_command = "ssh -o StrictHostKeyChecking=no -i keys/dev.pem dev@<server_ip>"
> ssh -o StrictHostKeyChecking=no -i keys/dev.pem dev@<server_ip>
```

To destroy the instance:
```
terraform destroy
```

# TODO

- [ ] Set up Pinokio like thing to easily spin up AI models?

- [ ] Setup caddy to work with tailscale hostnames - ability to host private and public services.

- [ ] Need a strategy to persist data when recreating server. Currently just copying files like with Caddystore. Maybe use S3/K2

- [x] ~~Subdomains on localhost like "whoami.localhost" dont work with HTTPS on Caddy.~~ [wildcard certificates are not allowed for localhost](https://stackoverflow.com/questions/68514712/what-is-the-correct-way-to-generate-a-selfsigned-cert-for-localhost-wildcard)

- [x] ~~Get Traefik setup as reverse proxy. Maybe consider private setup with tailscale:
https://medium.com/@svenvanginkel/your-homelab-behind-tailscale-with-wildcard-dns-and-certificates-c68a881900bf~~. Got Caddy working.

- [x] ~~Deploy server automatically with Terraform~~
