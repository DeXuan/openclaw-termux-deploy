# Contributing to OpenClaw Termux Deploy

Thanks for your interest! This project helps people turn old Android phones into AI servers. Here's how to contribute.

## Quick Ways to Help

| What | Time | Impact |
|------|------|--------|
| Test on your phone model | 30 min | ⭐⭐⭐ |
| Report a bug with logs | 10 min | ⭐⭐⭐ |
| Translate docs | 1-2 hours | ⭐⭐ |
| Add a new pitfall | 20 min | ⭐⭐ |
| Improve a script | Varies | ⭐⭐ |

## Testing on Your Phone

The most valuable contribution: run the installer on your Android device and report results.

```bash
curl -fsSL https://raw.githubusercontent.com/DeXuan/openclaw-termux-deploy/main/install.sh | bash
```

Then run the diagnostic:
```bash
cat scripts/phone_check_env.sh | sh -
```

**Report your results** by opening an issue with:
```
Device: [model name]
Android: [version]
RAM: [amount]
Result: [success / partial / failed]
Details: [what happened]
```

We'll add your device to the [device matrix](skill/references/device-matrix.md).

## Reporting Bugs

Include these in your bug report:
1. Device model + Android version
2. OpenClaw version (`openclaw --version`)
3. Node version (`node --version`)
4. Service status (`sv status openclaw`)
5. Recent logs (`tail -50 $PREFIX/var/log/sv/openclaw/current`)
6. Diagnostic output (`cat scripts/phone_check_env.sh | sh -`)

## Adding a New Pitfall

Found a real problem on a real phone? Add it to [pitfalls.md](skill/references/pitfalls.md):

```markdown
| # | 现象 | 原因 | 解法 |
|---|------|------|------|
| N | [Symptom - what you see] | [Root cause] | [Fix command] |
```

Include a detailed section below the table if the fix needs explanation.

## Adding Device Support

For a new phone model or Android version:
1. Run `phone_check_env.sh` → note the output
2. Check [device-matrix.md](skill/references/device-matrix.md) for similar devices
3. Document any special steps (e.g., phantom killer, Doze, Tailscale compatibility)
4. Add to the device table

## Pull Request Process

1. **Fork** the repo
2. **Create a branch** (`fix/shebang-arm64` or `feat/new-channel`)
3. **Test** on at least one real Android device
4. **Run ShellCheck** on bash scripts: `shellcheck scripts/*.sh`
5. **Commit** with [Conventional Commits](https://www.conventionalcommits.org/):
   - `fix:` for bug fixes
   - `feat:` for new features
   - `docs:` for documentation
   - `refactor:` for code improvements
6. **Open a PR** with a clear description

## Code Style

### Shell Scripts
- Shebang: `#!/data/data/com.termux/files/usr/bin/sh`
- Use `$PREFIX` not hardcoded paths
- No `/tmp` (Termux doesn't have it — use `$HOME` or `$PREFIX/tmp`)
- Comment pitfall numbers (`# 坑17`)
- Test with `shellcheck`

### Python Scripts
- Shebang: `#!/data/data/com.termux/files/usr/bin/python3`
- Use `urllib.request` (stdlib, no deps)
- No emoji in code strings on Windows (GBK encoding issues)
- Handle QDII fund data delay gracefully

### Documentation
- Bilingual preferred (Chinese + English)
- Keep [pitfalls.md](skill/references/pitfalls.md) up to date — it's our moat
- Add new scripts to the project structure in README

## Project Values

- **Real phones, real problems.** No simulated environments.
- **Native Termux only.** No Proot, no containers, no root.
- **Battle-tested.** Every pitfall entry comes from actual debugging sessions.
- **Fleet-first.** Tools work across multiple devices, not just one-off setups.

## Recognition

All contributors are listed in the README and commit history. Significant contributions (new device support, major features) get a shoutout in release notes.

## Questions?

Open a [Discussion](https://github.com/DeXuan/openclaw-termux-deploy/discussions) or issue. We respond within 24 hours.
