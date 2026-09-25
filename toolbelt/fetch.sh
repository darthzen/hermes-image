#!/usr/bin/env bash
# Download the static CLI binaries for the Hermes toolbelt and verify each one
# against the checksum file its project publishes. Output lands in $OUT/bin.
# Versions are pinned here; bump them deliberately and rebuild.
set -euo pipefail

OUT=${OUT:-/out}
KUBECTL_VERSION=v1.35.6    # match the cluster (k3s v1.35.6+k3s1)
HELM_VERSION=v4.3.0
GH_VERSION=2.101.0
YQ_VERSION=v4.53.6
CRANE_VERSION=v0.22.1
STERN_VERSION=1.34.0
YTDLP_VERSION=2026.08.19

mkdir -p "$OUT/bin"
work=$(mktemp -d)
cd "$work"

get() { curl -fsSL --retry 3 -o "$2" "$1"; }

# check <sha256> <file>
check() { echo "$1  $2" | sha256sum -c --quiet - || { echo "checksum mismatch: $2" >&2; exit 1; }; }

# kubectl: bare hash file
get "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl" kubectl
get "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl.sha256" kubectl.sha256
check "$(cat kubectl.sha256)" kubectl
install -m 0755 kubectl "$OUT/bin/kubectl"

# helm: "<hash>  <file>"
f=helm-${HELM_VERSION}-linux-amd64.tar.gz
get "https://get.helm.sh/$f" "$f"
get "https://get.helm.sh/$f.sha256sum" "$f.sha256sum"
check "$(awk '{print $1}' "$f.sha256sum")" "$f"
tar -xzf "$f" linux-amd64/helm
install -m 0755 linux-amd64/helm "$OUT/bin/helm"

# gh
f=gh_${GH_VERSION}_linux_amd64.tar.gz
base=https://github.com/cli/cli/releases/download/v${GH_VERSION}
get "$base/$f" "$f"
get "$base/gh_${GH_VERSION}_checksums.txt" gh.sums
check "$(awk -v f="$f" '$2==f{print $1}' gh.sums)" "$f"
tar -xzf "$f"
install -m 0755 "gh_${GH_VERSION}_linux_amd64/bin/gh" "$OUT/bin/gh"

# yq: checksums-bsd lines look like "SHA256 (yq_linux_amd64) = <hash>"
base=https://github.com/mikefarah/yq/releases/download/${YQ_VERSION}
get "$base/yq_linux_amd64" yq
get "$base/checksums-bsd" yq.sums
check "$(sed -n 's/^SHA256 (yq_linux_amd64) = //p' yq.sums)" yq
install -m 0755 yq "$OUT/bin/yq"

# crane
f=go-containerregistry_Linux_x86_64.tar.gz
base=https://github.com/google/go-containerregistry/releases/download/${CRANE_VERSION}
get "$base/$f" "$f"
get "$base/checksums.txt" crane.sums
check "$(awk -v f="$f" '$2==f{print $1}' crane.sums)" "$f"
tar -xzf "$f" crane
install -m 0755 crane "$OUT/bin/crane"

# stern
f=stern_${STERN_VERSION}_linux_amd64.tar.gz
base=https://github.com/stern/stern/releases/download/v${STERN_VERSION}
get "$base/$f" "$f"
get "$base/checksums.txt" stern.sums
check "$(awk -v f="$f" '$2==f{print $1}' stern.sums)" "$f"
tar -xzf "$f" stern
install -m 0755 stern "$OUT/bin/stern"

# yt-dlp: standalone build, no Python dependency
base=https://github.com/yt-dlp/yt-dlp/releases/download/${YTDLP_VERSION}
get "$base/yt-dlp_linux" yt-dlp
get "$base/SHA2-256SUMS" ytdlp.sums
check "$(awk '$2=="yt-dlp_linux"{print $1}' ytdlp.sums)" yt-dlp
install -m 0755 yt-dlp "$OUT/bin/yt-dlp"

cd / && rm -rf "$work"
ls -l "$OUT/bin"
