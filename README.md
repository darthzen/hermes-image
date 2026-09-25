# hermes-image

The two Hermes images on sdf1, with the ash4d toolbelt layered onto pinned
upstream digests. Deployed by `lab-fleet/10-hermes/hermes.yaml`.

| Image | Upstream | Harbor |
|---|---|---|
| `Dockerfile.agent` | `docker.io/nousresearch/hermes-agent` | `registry.ash4d.com/ash4d-lab/hermes-agent:<upstream>-ash4d.N` |
| `Dockerfile.webui` | `ghcr.io/nesquena/hermes-webui` | `registry.ash4d.com/ash4d-lab/hermes-webui:<upstream>-ash4d.N` |

Both images get the toolbelt because terminal commands from WebUI chats run
in the WebUI container, not the agent container.

## Why layered, not BCI

Upstream is Debian 13 with Playwright's Chromium, which Playwright supports
only on Debian/Ubuntu. Layering keeps upgrades to a one-line digest bump.
(Rick, 2026-09-25.)

## What is in the toolbelt

- `toolbelt/apt-packages.txt`: Debian packages (rg, fd, jq, dig, nc, procps,
  poppler, sqlite3, ffmpeg, shellcheck, and more).
- `toolbelt/fetch.sh`: pinned static binaries, each verified against its
  project's published checksum (kubectl, helm, gh, yq, crane, stern, yt-dlp).
- `toolbelt/requirements.txt`: Python libraries installed into the agent
  venv and the WebUI venv, constrained by the upstream freeze so a conflict
  fails the build rather than moving a Hermes dependency.
- `toolbelt/ssh_config`: reads the key from `/etc/hermes-ssh`, populated from
  Secret `hermes-ssh` by an init container.
- `toolcheck`: run `toolcheck` (agent) or `toolcheck /app/venv/bin/python`
  (WebUI) in a container. It exits non-zero and names anything missing.

## Upgrading

1. Put the new upstream digest in `ARG UPSTREAM` in the Dockerfile.
2. Commit and push.
3. Build with the kaniko job (tags track the upstream version):

```bash
~/.claude/skills/lab-image-build/scripts/kaniko-build.sh --repo darthzen/hermes-image \
  --image hermes-agent --tag 0.21.5-ash4d.1 --dockerfile Dockerfile.agent
~/.claude/skills/lab-image-build/scripts/kaniko-build.sh --repo darthzen/hermes-image \
  --image hermes-webui --tag 0.52.379-ash4d.1 --dockerfile Dockerfile.webui
```

4. Update both agent image references in lab-fleet together (the main
   container and `copy-agent-src`), plus the WebUI image.

The WebUI venv is pre-built at `/app/venv` owned by `10000:10000`, which must
match `WANTED_UID/GID` in lab-fleet.
