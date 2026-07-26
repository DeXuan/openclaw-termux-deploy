# Security Policy

## Supported Versions

| Version | Supported |
|---------|-----------|
| Latest release | ✅ |
| Older releases | ❌ |

## Reporting a Vulnerability

**Do not open a public issue.** Instead, please report security vulnerabilities privately via:

- GitHub Security Advisories: https://github.com/DeXuan/openclaw-termux-deploy/security/advisories/new
- Or email the project maintainer

You should receive a response within 48 hours. Please allow time for the fix to be developed and released before disclosing publicly.

## Scope

Concerns we take seriously:
- Remote code execution via the installer or scripts
- Credential exposure in logs or config files
- Authentication bypass in gateway or channel setup
- Supply chain attacks via npm dependencies

## Best Practices for Users

1. **Change default passwords.** Termux `passwd` should be set before exposing SSH.
2. **Use Tailscale or VPN.** Never expose port 8022 directly to the internet.
3. **Review scripts before piping.** All install scripts are open source — read them before running `curl | bash`.
4. **Keep OpenClaw updated.** Security patches come via `npm update -g openclaw`.
5. **Restrict gateway bind.** Set gateway to `loopback` mode unless you understand the risks.
