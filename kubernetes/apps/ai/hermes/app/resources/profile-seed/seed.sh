#!/usr/bin/env bash
set -euo pipefail
umask 077

data=/opt/data

# Keep writes to .env atomic and preserve unrelated profile settings.
update_env() (
  file=$1
  filter=$2
  temporary=$(mktemp "${file}.XXXXXX")
  trap 'rm -f "$temporary"' EXIT
  if [[ -f $file ]]; then
    sed "$filter" "$file" > "$temporary"
  fi
  cat >> "$temporary"
  chmod 600 "$temporary"
  mv "$temporary" "$file"
)

: "${LITELLM_API_KEY:?LITELLM_API_KEY is required}"
: "${SEARXNG_URL:?SEARXNG_URL is required}"
: "${API_SERVER_KEY:?API_SERVER_KEY is required}"
: "${FORGEJO_TOKEN:?FORGEJO_TOKEN is required}"

cp /seed/config.yaml "$data/config.yaml"
cp /seed/SOUL.md "$data/SOUL.md"
mkdir -p "$data/workspace"

# The image only autostarts the gateway at boot when the last recorded state was
# `running` (hermes_cli/container_boot.py); a fresh volume has no state and the
# heartbeat probe would never pass. Named profiles fold into this root gateway.
if [[ ! -f $data/gateway_state.json ]]; then
  printf '{"gateway_state": "running", "desired_state": "running"}\n' > "$data/gateway_state.json"
fi

cat > "$data/.hermes-terminal-env.sh" <<'EOT'
# Bash sources this file through BASH_ENV for every Hermes terminal command.
for directory in /opt/data/.local/bin /opt/hermes/.venv/bin /opt/hermes/bin; do
  case ":$PATH:" in
    *":$directory:"*) ;;
    *) PATH="$directory:$PATH" ;;
  esac
done
export PATH
if [[ ${_HERMES_MISE_ACTIVATED:-} != 1 ]]; then
  _HERMES_MISE_ACTIVATED=1
  eval "$(mise activate bash)"
fi
EOT
chmod 644 "$data/.hermes-terminal-env.sh"

# git identity + Forgejo credentials for the agent's terminal
cat > "$data/.gitconfig" <<'EOT'
[user]
	name = AI Agent
	email = agent@altena.io
[credential]
	helper = store
[init]
	defaultBranch = main
EOT
printf 'http://agent:%s@forgejo-http.selfhosted.svc.cluster.local:3000\nhttps://agent:%s@git.altena.io\n' "$FORGEJO_TOKEN" "$FORGEJO_TOKEN" > "$data/.git-credentials"
chmod 600 "$data/.git-credentials"

update_env "$data/.env" '/^LITELLM_/d; /^SEARXNG_URL=/d; /^FORGEJO_TOKEN=/d' <<EOT
LITELLM_API_KEY=$LITELLM_API_KEY
SEARXNG_URL=$SEARXNG_URL
FORGEJO_TOKEN=$FORGEJO_TOKEN
EOT

# Role profiles are Hermes profile distributions kept in the repo; reinstall them
# from main on every boot (config/SOUL/skills from Git, memories and sessions kept).
repo=/tmp/homelab
rm -rf "$repo"
git clone --quiet --depth 1 http://forgejo-http.selfhosted.svc.cluster.local:3000/dave/homelab.git "$repo"
dists=$repo/kubernetes/apps/ai/hermes/app/resources/profiles
export HOME=$data PATH=/opt/hermes/.venv/bin:/opt/hermes/bin:$PATH
for dist in "$dists"/*/; do
  name=$(basename "$dist")
  if [[ $name == gitops-engineer ]]; then
    # the repo's own agent skills (add-app, ...) travel with the GitOps profile
    cp -r "$repo"/.agents/skills/. "$dist/skills/"
  fi
  hermes profile install "$dist" --name "$name" --force --yes >/dev/null
  echo "profile $name installed from git"
done
rm -rf "$repo"

for profile in "$data"/profiles/*; do
  [[ -d $profile ]] || continue
  update_env "$profile/.env" '/^LITELLM_API_KEY=/d; /^API_SERVER_KEY=/d; /^SEARXNG_URL=/d; /^HERMES_WEBUI_GATEWAY_BASE_URL=/d' <<EOT
LITELLM_API_KEY=$LITELLM_API_KEY
API_SERVER_KEY=$API_SERVER_KEY
SEARXNG_URL=$SEARXNG_URL
HERMES_WEBUI_GATEWAY_BASE_URL=http://127.0.0.1:8642/p/${profile##*/}
EOT
done

mkdir -p "$data/.local/bin"
ln -sfn /opt/mise/mise "$data/.local/bin/mise"
