#!/usr/bin/env bash
#
# Creates an Azure DevOps pull request via `az repos pr create`.
#
# This script does NOT prompt for confirmation itself — the calling agent
# is responsible for showing the resolved plan (repo, source, target,
# title) to the user and getting an explicit "yes" before invoking this
# script. This mirrors apply_standard_branch_policies.sh's reliance on the
# agent for the confirmation gate.
#
set -euo pipefail

usage() {
    echo "Usage: $0 --repo <repo-name> [--source-branch <branch>] [--target-branch <branch>] [--title <title>] [--org <org-url>] [--project <project-name>]" >&2
    exit 1
}

repo=""
source_branch=""
target_branch="DEV"
title=""
org=""
project=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --repo) repo="$2"; shift 2 ;;
        --source-branch) source_branch="$2"; shift 2 ;;
        --target-branch) target_branch="$2"; shift 2 ;;
        --title) title="$2"; shift 2 ;;
        --org) org="$2"; shift 2 ;;
        --project) project="$2"; shift 2 ;;
        *) usage ;;
    esac
done

# --- Prerequisite check: azure-devops extension + authenticated session ---
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

if [[ -z "$repo" ]]; then
    echo "Prerequisite missing: --repo is required (no repository was passed)." >&2
    exit 1
fi

# --- Always print the exact plan before creating anything ---
echo "PR plan:"
echo "  Repository:      $repo"
echo "  Source branch:   $source_branch"
echo "  Target branch:   $target_branch"
echo "  Title:           $title"
[[ -n "$org" ]] && echo "  Organization:    $org"
[[ -n "$project" ]] && echo "  Project:         $project"

args=(repos pr create --repository "$repo" --source-branch "$source_branch" --target-branch "$target_branch" --title "$title")
[[ -n "$org" ]] && args+=(--org "$org")
[[ -n "$project" ]] && args+=(--project "$project")

if az "${args[@]}"; then
    echo "Pull request created."
else
    exit_code=$?
    echo "PR creation failed (az exit code $exit_code). See the CLI output above for details." >&2
    exit "$exit_code"
fi
