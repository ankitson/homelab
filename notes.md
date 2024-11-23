## Terraform stuff

- You can import resources defined online. e.g define a firewall in hetzner cloud UI, look at its ID, then do:

  `tf import hcloud_firewall.default 1707990`

  this imports it into state but not the definition. then do `terraform show` to show the copyable definitions for this new firewall

## Tailscale

Tailscale does not support "releasing" a domain name using the tailscale CLI. If a host is brought up with name "ts-host" and then destroyed with terraform, the name is still in use. The new machine brought up with terraform will get the name "ts-host1", "ts-host2".. to avoid this we have a script in `user_data.yaml.tpl` that deletes any existing devices with the same hostname (device id in TS parlance) before bringing up the new machine. There was some trouble referencing all the variables we need if copying the script via terraform as a file, so it's embedded in the YAML.

## Cloudflare

If cloudflare is set to MIXED mode, it terminates SSL and forwards requests to Caddy as HTTP. Caddy by default uses automatic HTTPS, so it will forward the HTTP request back to the domain as HTTPS, which goes to Cloudflare.. creates a request loop.

To avoid this, Cloudflare is set to "Full (Strict)" encryption mode so it forwards traffic over HTTPs to the origin (Caddy) and validates the origin cert.

Cloudflare IPs must be allowed in the firewall.

## debug notes
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


## debug tailscale caddy

[should work without any config](https://tailscale.com/kb/1190/caddy-certificates)

1. added the TS_PERMIT_CERT_UID=dev in tailscaled conf.

See logs:
```
tls.get_certificate.tailscale   could not get status; will try to get certificate anyway   {"error": "Get \"http://local-tailscaled.sock/localapi/v0/status\": dial unix /var/run/tailscale/tailscaled.sock: connect: no such file or directory"}
caddy         | 2024/11/23 08:38:36.067 ERROR   tls.handshake   external certificate manager       {"remote_ip": "100.114.141.84", "remote_port": "53948", "sni": "TS-HOSTNAME.TS-NETWORK.ts.net", "cert_manager": "*caddytls.Tailscale", "cert_manager_idx": 0, "error": "Get \"http://local-tailscaled.sock/localapi/v0/cert/TS-HOSTNAME.TS-NETWORK.ts.net?type=pair\": dial unix /var/run/tailscale/tailscaled.sock: connect: no such file or directory"}
caddy         | 2024/11/23 08:38:36.067 DEBUG   http.stdlib     http: TLS handshake error from 100.114.141.84:53948: external certificate manager indicated that it is unable to yield certificate: Get "http://local-tailscaled.sock/localapi/v0/cert/TS-HOSTNAME.TS-NETWORK.ts.net?type=pair": dial unix /var/run/tailscale/tailscaled.sock: connect: no such file or directory
```

so its trying to contact the local tailscaled to get the cert but fails

2. Try `tailscale cert`

```bash
dev@homelab:~$ tailscale cert
Usage: tailscale cert [flags] <domain>
HTTPS cert support is not enabled/configured for your tailnet.
```

aha!

3. Go to tailscale admin panel and enable HTTPS certs

4. Then mount sock  in docker

`- /var/run/tailscale/tailscaled.sock:/var/run/tailscale/tailscaled.sock:ro`

5. Now domains work, not subdomains;
```
$ curl https://TS-HOSTNAME.TS-NETWORK.ts.net
Hello tailscale!
dev@homelab:\~$ curl https://actual.TS-HOSTNAME.TS-NETWORK.ts.net
curl: (6) Could not resolve host: actual.TS-HOSTNAME.TS-NETWORK.ts.net
```

Because tailscale MagicDNS does not support subdomains
