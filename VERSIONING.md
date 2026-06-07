# Versioning Guide

This repo uses one main project structure (no versioned folders), works directly on `main`, and uses Git tags for releases.

## Recommended Flow

1. Make sure you are on `main` and up to date:
```bash
git switch main
git pull origin main
```

2. Commit your work:
```bash
git add .
git commit -m "Your message"
```

3. Push `main`:
```bash
git push origin main
```

4. Create and push an annotated release tag:
```bash
git tag -a <tag-name> -m "<tag-name>"
git push origin <tag-name>
```

Examples:
- `v0.1.0`
- `analysis-v0.3.0`
- `report-v1.0.0`

## SemVer Note

Use `MAJOR.MINOR.PATCH` for tags:
- Patch (`0.1.1`): small fix, no workflow change.
- Minor (`0.2.0`): new analysis feature, backward-compatible.
- Major (`1.0.0`): breaking structure/process change.

## Main-Branch Example

```bash
git branch --show-current
git switch main
git pull origin main
git status --short
git add .
git commit -m "Files Setup"
git push origin main
git tag -a v0.1.0 -m "v0.1.0"
git push origin v0.1.0
git --no-pager log -1 --stat

```

## Useful Commands

Current version string:
```bash
git describe --tags --always --dirty
```

List tags:
```bash
git tag --list
```

Checkout old tag:
```bash
git checkout <tag>
```

Return to branch:
```bash
git checkout main
```

## Tag Notes

- Commit first, then tag.
- Prefer annotated tags (`git tag -a`) over lightweight tags.
- Do not reuse tag names unless you intentionally delete/recreate them.
- Keep large generated outputs and local artifacts out of Git (as defined in `.gitignore`).