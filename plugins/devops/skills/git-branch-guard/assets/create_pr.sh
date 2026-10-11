#!/usr/bin/env bash
#
# Creates a pull request for the current repository. The host is detected from
# `git remote get-url origin`:
#   github.com            -> `gh pr create`
#   dev.azure.com         -> `az repos pr create`
#   anything else         -> reported as unsupported, nothing is created
#
# This script does NOT prompt for confirmation itself — the calling agent
# is responsible for showing the resolved plan (repo, source, target,
# title) to the user and getting an explicit "yes" before invoking this
# script. This mirrors apply_standard_branch_policies.sh's reliance on the
# agent for the confirmation gate.
#
set -euo pipefail

usage() {
    echo "Usage: $0 [--repo <repo-name>] [--source-branch <branch>] [--target-branch <branch>] [--title <title>] [--body <text>] [--org <org-url>] [--project <project-name>]" >&2
    echo "  --repo is required for Azure DevOps remotes and optional for GitHub (defaults to the origin remote)." >&2
    echo "  --org and --project apply to Azure DevOps remotes only." >&2
    exit 1
}

repo=""
source_branch=""
target_branch="DEV"
title=""
body=""
org=""
project=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --repo) repo="$2"; shift 2 ;;
        --source-branch) source_branch="$2"; shift 2 ;;
        --target-branch) target_branch="$2"; shift 2 ;;
        --title) title="$2"; shift 2 ;;
        --body) body="$2"; shift 2 ;;
        --org) org="$2"; shift 2 ;;
        --project) project="$2"; shift 2 ;;
        *) usage ;;
    esac
done

# --- Detect the host from the origin remote ---
remote_url="$(git remote get-url origin 2>/dev/null || true)"
if [[ -z "$remote_url" ]]; then
    echo "Could not read the 'origin' remote URL (git remote get-url origin). Add an origin remote first." >&2
    exit 1
fi

# Reduce the URL to its host: strip scheme, user@, then everything after the host.
remote_host="${remote_url#*://}"
remote_host="${remote_host#*@}"
remote_host="${remote_host%%[/:]*}"
remote_host="$(printf '%s' "$remote_host" | tr '[:upper:]' '[:lower:]')"

case "$remote_host" in
    github.com) host_kind="github" ;;
    dev.azure.com|ssh.dev.azure.com) host_kind="azure" ;;
    *)
        echo "Unsupported remote host '$remote_host' (origin: $remote_url). Only github.com and dev.azure.com are supported. No pull request was created." >&2
        exit 1
        ;;
esac
echo "Detected host: $remote_host ($host_kind)"

# --- Prerequisite check for the detected host ---
if [[ "$host_kind" == "github" ]]; then
    if ! command -v gh >/dev/null 2>&1; then
        echo "Prerequisite missing: the GitHub CLI ('gh') is not installed. Install it from https://cli.github.com and run 'gh auth login'." >&2
        exit 1
    fi
    if ! gh auth status >/dev/null 2>&1; then
        echo "Prerequisite missing: 'gh' is not authenticated. Run 'gh auth login' first." >&2
        exit 1
    fi
else
    has_extension="$(az extension list -o tsv --query "[?name=='azure-devops'].name" 2>/dev/null || true)"
    if [[ -z "$has_extension" ]]; then
        echo "Prerequisite missing: the 'azure-devops' CLI extension is not installed. Run 'az extension add --name azure-devops' (or plugins/devops/skills/git-branch-guard/assets/setup_azure_cli.sh) first." >&2
        exit 1
    fi

    account="$(az account show -o json 2>/dev/null || true)"
    if [[ -z "$account" ]]; then
        echo "Prerequisite missing: no authenticated Azure CLI session. Run 'az login' first." >&2
        exit 1
    fi

    if [[ -z "$org" && -z "$project" ]]; then
        defaults="$(az devops configure --list -o tsv 2>/dev/null || true)"
        if [[ "$defaults" != *organization* ]]; then
            echo "Prerequisite missing: no default organization is configured and --org was not provided. Run 'az devops configure --defaults organization=<url>' or pass --org explicitly." >&2
            exit 1
        fi
    fi
fi

# --- Resolve source branch / title from the current branch if not passed ---
if [[ -z "$source_branch" ]]; then
    source_branch="$(git branch --show-current | tr -d '[:space:]')"
    if [[ -z "$source_branch" ]]; then
        echo "Could not determine the current Git branch to use as --source-branch. Pass --source-branch explicitly." >&2
        exit 1
    fi
    echo "Resolved --source-branch from the current branch: '$source_branch'"
fi

if [[ -z "$title" ]]; then
    if [[ "$source_branch" =~ ([A-Z]+-[0-9]+) ]]; then
        title="${BASH_REMATCH[1]}: $source_branch"
    else
        title="$source_branch"
    fi
    echo "Resolved --title from the source branch: '$title'"
fi

if [[ "$host_kind" == "azure" && -z "$repo" ]]; then
    echo "Prerequisite missing: --repo is required for Azure DevOps remotes (no repository was passed)." >&2
    exit 1
fi

# --- Always print the exact plan before creating anything ---
echo "PR plan:"
echo "  Host:            $remote_host"
echo "  Repository:      ${repo:-(from origin: $remote_url)}"
echo "  Source branch:   $source_branch"
echo "  Target branch:   $target_branch"
echo "  Title:           $title"
[[ -n "$body" ]] && echo "  Body:            $body"
[[ -n "$org" ]] && echo "  Organization:    $org"
[[ -n "$project" ]] && echo "  Project:         $project"

if [[ "$host_kind" == "github" ]]; then
    args=(pr create --base "$target_branch" --head "$source_branch" --title "$title" --body "$body")
    [[ -n "$repo" ]] && args+=(--repo "$repo")
    tool=gh
else
    args=(repos pr create --repository "$repo" --source-branch "$source_branch" --target-branch "$target_branch" --title "$title")
    [[ -n "$body" ]] && args+=(--description "$body")
    [[ -n "$org" ]] && args+=(--org "$org")
    [[ -n "$project" ]] && args+=(--project "$project")
    tool=az
fi

if "$tool" "${args[@]}"; then
    echo "Pull request created."
else
    exit_code=$?
    echo "PR creation failed ($tool exit code $exit_code). See the CLI output above for details." >&2
    exit "$exit_code"
fi
