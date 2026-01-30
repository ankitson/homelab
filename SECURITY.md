# Security Audit

Audit date: 2026-01-28
Scope: all 25 commits in git history + working directory

## Git History

**Result: CLEAN** - no secrets found in any commit.

The repo was properly managed from the initial commit:

- `secrets.auto.tfvars` was in `.gitignore` from commit `af4cc09` (first commit)
- `*.pem` was in `.gitignore` from the first commit
- `terraform.tfvars` uses placeholder text `"overridden in secrets.auto.tfvars"` rather than actual values
- Template files (`docker.env.tpl`, `user_data.yaml.tpl`, `cleanup-tailscale.sh.tpl`) use Terraform/shell variable substitution, not hardcoded values
- `notes.md` uses redacted placeholders like `DOMAIN.com`, `CLOUDFLARE-TOKEN`, `TS-HOSTNAME.TS-NETWORK.ts.net`

**Minor informational items** (not secrets, but noted for completeness):

- SSH public keys appear in `terraform.tfvars` (public keys are not secrets)
- Domain name "nopeslide" appeared in `Caddyfile` (commit `883db58`, changed in `776d2f7`)
- Tailscale internal IP `100.114.141.84` in `notes.md` debug logs

## Working Directory

**WARNING: `docker.env.tpl` has an unstaged change adding a hardcoded password:**

```
PIHOLE_PASSWORD=sup3r12,s9@4k1 #TODO use tf var
```

This **must not be committed**. Instead, add a Terraform variable and use substitution:

```
PIHOLE_PASSWORD=${pihole_password}
```

## .gitignore Gaps

The following untracked files should be added to `.gitignore` to prevent accidental commits:

| File | Risk |
|------|------|
| `Caddystore.bc` | Backup of Caddy certificate storage — may contain private keys |
| `ts-homelab.db` | Tailscale state database — contains node identity |
| `repo.txt` | File listing dump — low risk but unnecessary to track |

## Recommendations

1. **Fix the pihole password** — replace the hardcoded value in the unstaged `docker.env.tpl` diff with a Terraform variable reference (`${pihole_password}`) and put the actual password in `secrets.auto.tfvars`.
2. **Update `.gitignore`** — add `Caddystore.bc`, `ts-homelab.db`, and `repo.txt`.
3. **Consider pre-commit secret scanning** — tools like `gitleaks` or `detect-secrets` can catch hardcoded credentials before they reach history. A pre-commit hook config already exists (`507f99c`) and could be extended.

## Verdict

The git history is clean and safe to make public. Address the unstaged hardcoded password and `.gitignore` gaps before any further commits.
