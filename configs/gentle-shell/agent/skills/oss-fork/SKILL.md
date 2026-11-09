---
name: oss-fork
description: "Trigger: forking or cloning an open-source repo to contribute upstream, setting up a contribution workspace, opening upstream PRs, 'cloname el fork', 'voy a aportar a'. Clone contribution forks to ~/open-source/<org>-<repo> and follow the repo's own contribution flow."
---

# OSS fork workspace convention

How to set up and work in local clones of third-party/open-source projects the
user wants to contribute to.

## Workspace layout

- All contribution clones live under `~/open-source/`.
- Directory name: `<org>-<repo>` (e.g. `noctalia-official-plugins`,
  `gentleman-programming-gentle-shell`). The org prefix disambiguates forks of
  same-named repos and keeps `ls ~/open-source` self-explanatory.
- Never use a generic `~/src` dump: one folder per upstream project, explicit
  origin.

## Setup steps

1. `gh repo fork <org>/<repo> --clone=false` (user's gh is authenticated).
2. `git clone git@github.com:<user>/<repo>.git ~/open-source/<org>-<repo>`
   (clone from the FORK, not upstream, so pushes go to the user's namespace).
3. `git remote add upstream https://github.com/<org>/<repo>.git` and
   `git fetch upstream main` (or the repo's default branch).
4. Feature branches: `feat/<short-topic>` based on `upstream/main`, never on a
   stale origin copy.

## Contribution flow (per repo, respect its own rules)

1. Read the repo's CONTRIBUTING/PR templates and issue workflow FIRST — some
   ecosystems (Gentleman-Programming) require an approved issue before a PR;
   others accept direct PRs with the template filled. The noctalia-dev org is
   STRICT about issue forms: issues must go through the yaml form templates
   (bug_report.yml / feature_request.yml), titles carry a [BUG]/[FEATURE]
   prefix, and freeform markdown issues get closed (e.g. noctalia#4812).
   When editing/creating issues there, replicate the form structure with
   `### FieldName` headers.
2. Draft user-facing issue/PR text in the repo's language (usually English),
   show the user the draft BEFORE publishing anything upstream.
3. Validate with the repo's own tooling (lint scripts, validators,
   `noctalia plugins lint <plugin>` for noctalia plugins) — match the bar the
   maintainers enforce.
4. Test locally without publishing: for noctalia plugins, copy built files
   into `~/.local/state/noctalia/plugins/materialized/` (backup first) and
   have the user test live.
5. Push the branch to the fork, open a DRAFT PR referencing the issue
   (`Closes #N`), let the user test, then mark ready.

## Gotchas

- Creating issues/PRs/pushing to upstream = publishing: always get explicit
  user approval with the exact text shown first.
- Keep follow-up ideas OUT of the feature PR: file them as separate issues so
  reviews stay focused.
- If the plugin/agent runtime breaks mid-session (MODULE_NOT_FOUND at
  subagent dispatch), fall back to inline work instead of retrying agents.
