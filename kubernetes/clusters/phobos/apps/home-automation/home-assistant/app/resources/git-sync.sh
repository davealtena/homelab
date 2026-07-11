#!/usr/bin/env bash
# Bidirectional git sync for /config <-> in-cluster Forgejo (dave/hass-config).
# - commits & pushes changes made via the HA UI (mirror propagates to GitHub)
# - pulls pushes from Forgejo and reloads HA (reload_all; persistent
#   notification when configuration.yaml/packages change, those need a restart)
set -uo pipefail

INTERVAL="${SYNC_INTERVAL:-60}"
BRANCH="${SYNC_BRANCH:-main}"

export GIT_CONFIG_COUNT=4
export GIT_CONFIG_KEY_0=safe.directory GIT_CONFIG_VALUE_0=/config
export GIT_CONFIG_KEY_1=user.name GIT_CONFIG_VALUE_1="HA git-sync"
export GIT_CONFIG_KEY_2=user.email GIT_CONFIG_VALUE_2="hass-git-sync@valhalla.local"
export GIT_CONFIG_KEY_3=credential.username GIT_CONFIG_VALUE_3="${FORGEJO_USER:-dave}"
export GIT_ASKPASS=/tmp/git-askpass.sh
printf '#!/bin/sh\necho "$FORGEJO_TOKEN"\n' > "$GIT_ASKPASS"
chmod 700 "$GIT_ASKPASS"

cd /config

ha_call() { # $1 = API path, $2 = JSON body
  [[ -z "${HASS_TOKEN:-}" ]] && return 0
  curl -fsS -m 10 -o /dev/null -X POST \
    -H "Authorization: Bearer $HASS_TOKEN" \
    -H "Content-Type: application/json" \
    -d "$2" "${HASS_URL:-http://localhost:8123}$1" \
    || echo "ha_call $1 failed"
}

last_conflict=""
echo "git-sync started (interval ${INTERVAL}s, branch ${BRANCH})"

while true; do
  # 1. commit local drift (UI edits)
  if [[ -n "$(git status --porcelain)" ]]; then
    git add -A
    git commit -q -m "chore(auto): sync changes made in Home Assistant" \
      && echo "committed local changes"
  fi

  # 2. integrate remote
  if git fetch -q origin "$BRANCH"; then
    local_sha=$(git rev-parse HEAD)
    remote_sha=$(git rev-parse "origin/$BRANCH")
    applied=""
    if [[ "$local_sha" != "$remote_sha" ]] \
      && ! git merge-base --is-ancestor "origin/$BRANCH" HEAD; then
      base=$(git merge-base HEAD "origin/$BRANCH")
      if git rebase -q "origin/$BRANCH" > /dev/null; then
        applied=$(git diff --name-only "$base" "$remote_sha")
        echo "applied remote changes:"; echo "$applied"
      else
        git rebase --abort
        if [[ "$last_conflict" != "$remote_sha" ]]; then
          last_conflict="$remote_sha"
          echo "rebase conflict on $remote_sha; manual fix needed"
          ha_call /api/services/persistent_notification/create \
            '{"title":"hass-config sync conflict","message":"git rebase failed in /config; resolve manually (kubectl exec)."}'
        fi
      fi
    fi

    # 3. push local commits (no-op when up to date)
    git push -q origin "$BRANCH" 2>/dev/null || echo "push failed"

    # 4. reload HA when remote changes were applied
    if [[ -n "$applied" ]]; then
      if echo "$applied" | grep -qE '^(configuration\.yaml|packages/)'; then
        ha_call /api/services/persistent_notification/create \
          '{"title":"hass-config synced","message":"configuration.yaml/packages changed via git; restart Home Assistant to apply."}'
      else
        ha_call /api/services/homeassistant/reload_all '{}'
        echo "reload_all triggered"
      fi
    fi
  else
    echo "fetch failed; retrying in ${INTERVAL}s"
  fi

  sleep "$INTERVAL"
done
