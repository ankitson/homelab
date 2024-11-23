# Terraform stuff

- You can import resources defined online. e.g define a firewall in hetzner cloud UI, look at its ID, then do:

  `tf import hcloud_firewall.default 1707990`

  this imports it into state but not the definition. then do `terraform show` to show the copyable definitions for this new firewall

## debug
I setup the cloudflare dns plugin and can see some caddy logs saying it solved the DNS challenge. But visiting DOMAIN.com just hangs, error code 522 connection timed out.

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
}
```
