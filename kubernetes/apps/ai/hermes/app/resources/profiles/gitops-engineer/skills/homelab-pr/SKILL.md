---
name: homelab-pr
description: "Make a change to Dave's homelab repo the right way: clone, branch, conventional signed-off commit, push, open a Forgejo PR with forgejo-mcp. Use for any manifest, workflow or docs change."
version: 1.0.0
author: dave
license: MIT
metadata:
  hermes:
    tags: [git, forgejo, gitops, pull-request, flux]
    related_skills: [add-app, flux-gitops]
---

# Homelab pull request workflow

The repo is `dave/homelab` on the in-cluster Forgejo. Your git credentials and identity are already configured (`~/.gitconfig`, `~/.git-credentials`, user `agent`). You can push branches and open PRs; you cannot merge.

## 1. Clone or refresh

```bash
cd "$HERMES_HOME/workspace"
[ -d homelab ] || git clone --depth 50 http://forgejo-http.selfhosted.svc.cluster.local:3000/dave/homelab.git
cd homelab && git fetch origin && git checkout main && git reset --hard origin/main
```

## 2. Read the conventions

`AGENTS.md` is the contract: layout (`kubernetes/apps/<ns>/<app>/ks.yaml` + `app/`), schema header under every `---`, pinned chart/image tags, `ks.yaml` fields (`targetNamespace`, `sourceRef.namespace: flux-system`, `healthChecks`, `wait: true`, `dependsOn` with `namespace:`), new apps also added to the namespace `kustomization.yaml`. Copy a neighbouring app rather than inventing fields. Secrets only via `ExternalSecret` from 1Password; never a plaintext token.

Flux runs envsubst over manifests: a literal `${VAR}` that must survive is written `$${VAR}`.

## 3. Branch, change, validate

```bash
git checkout -b fix/<short-topic>      # or feat/, chore/, docs/
# edit files
kubectl kustomize kubernetes/apps/<ns>/<app>/app >/dev/null   # when kubectl is available via mise
```

If `flate` is installed (`mise use ubi:home-operations/flate`), `flate diff all --path ./kubernetes --base origin/main` shows the rendered diff the CI check will post.

## 4. Commit and push

```bash
git add -A
git commit -s -m "fix(<app>): <what and why in one line>"
git push -u origin HEAD
```

Conventional commits: `feat|fix|chore|docs(<scope>): message`; `-s` (signoff) is mandatory.

## 5. Open the PR

Use `forgejo-mcp_pull_request_write` with `owner: dave`, `repo: homelab`, `head: <branch>`, `base: main`, a title equal to the commit subject and a body with: observed problem (with the evidence you gathered from the cluster), the change, and how to verify. Report the PR URL. Required checks `Flux Diff` and `Labeler` run automatically; the AI reviewer may comment. Dave merges.

## Don'ts

- Never commit to `main`, never force-push, never rewrite someone else's branch.
- Never put credentials, tokens or cluster secrets in Git or in the PR body.
- One concern per PR.
