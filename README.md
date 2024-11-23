# Devops tooling for homelab

This repo holds the operations related tooling for the homelab. Right now, it creates an instance on Hetzner Cloud with Docker installed using Terraform.

# Terraform stuff

- You can import resources defined online. e.g define a firewall in hetzner cloud UI, look at its ID, then do:

`tf import hcloud_firewall.default 1707990`

this imports it into state but not the definition. then do `terraform show` to show the copyable definitions for this new firewall

# TODO

- Get Traefik setup as reverse proxy. Maybe consider private setup with tailscale:
https://medium.com/@svenvanginkel/your-homelab-behind-tailscale-with-wildcard-dns-and-certificates-c68a881900bf

- Need a strategy to persist data when recreating server. Cheap way is to backup on local machine on destroy and upload on create, or maybe persistent volume, or use backups?

- Set up Pinokio like thing to easily spin up AI models?


## Things

- Building a custom caddy image with the cloudflare and nginx modules included. The `ankit/caddy-cloudflare` repo is set up on dockerhub.
```
bash
cd caddy
docker build . -t ankit/caddy-cloudflare:0.x
docker push ankit/caddy-cloudflare:0.x
```
Then this repo can be pulled on the terraform host

I setup the cloudflare dns plugin and can see some caddy logs saying it solved the DNS challenge. But visiting nopeslide.com just hangs, error code 522 connection timed out.

Fixed this by adding cloudflare IPs to allowed list in Hetzner.

Now, we get a redirect loop. This is because of [this](https://developers.cloudflare.com/ssl/troubleshooting/.too-many-redirects/). Cloudflare terminates TLS and forwards HTTP request to caddy. Caddy redirects HTTP to HTTPS, go back to cloudflare.

Disabled caddy redirects and it worsk:
```
{
    debug
    admin :2019 {
      origins 0.0.0.0
    }
    log {
        output stdout
        format console
        level DEBUG
    }
    auto_https disable_redirects
}

DOMAIN.com {
  tls {
    dns cloudflare CLOUDFLARE-TOKEN
  }
  log {
        output stdout
        format console
        level DEBUG
  }
  respond "Hello DOMAIN.com"
}

:80, :443 {
  respond "Hello, world change!"
}
```

Now however, it outputs hello world change instead of hello DOMAIN.com

I fixed this by just removing the 2nd block its more specific than the first.

Now this:
```
{
    debug
    admin :2019 {
      origins 0.0.0.0
    }
    log {
        output stdout
        format console
        level DEBUG
    }
    auto_https disable_redirects
}

DOMAIN.com {
  tls {
    dns cloudflare CLOUDFLARE-TOKEN
  }
  log {
        output stdout
        format console
        level DEBUG
  }
  reverse_proxy /actual/* localhost:5006
  respond "Hello DOMAIN.com"
}
```

returns 521 when visting any URL


had 502 errors visiting anything. if you point to localhost, its routing back inside teh caddy container!!! DUH!!

```
*.DOMAIN.com {
  tls {
    dns cloudflare CLOUDFLARE-TOKEN
  }
  log {
        output stdout
        format console
        level DEBUG
  }
  @actual host actual.DOMAIN.com
  handle @actual {
    encode gzip zstd
    reverse_proxy actualbudget
  }
  @whoami host whoami.DOMAIN.com
  handle @whoami {
    reverse_proxy whoami
  }
  handle {
    respond "Hello!"
  }
}```



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
