#!/usr/bin/env bash
set -euo pipefail

protected_branches=("main" "master" "prod" "production" "dev" "develop" "test")
allowed_prefixes=("bugfix/" "feature/")

current_branch="$(git branch --show-current | tr -d '[:space:]')"

if [[ -z "$current_branch" ]]; then
    echo "Could not determine the current Git branch." >&2
    exit 1
fi

for protected in "${protected_branches[@]}"; do
    if [[ "$current_branch" == "$protected" ]]; then
        echo "Current branch '$current_branch' is protected. Create a bugfix/ or feature/ branch with a Jira key before continuing." >&2
        exit 1
    fi
done

has_allowed_prefix=false
for prefix in "${allowed_prefixes[@]}"; do
    if [[ "$current_branch" == "$prefix"* ]]; then
        has_allowed_prefix=true
        break
    fi
done

if [[ "$has_allowed_prefix" != true ]]; then
    echo "Branch '$current_branch' must start with 'bugfix/' or 'feature/'." >&2
    exit 1
fi

if ! [[ "$current_branch" =~ [A-Z]+-[0-9]+ ]]; then
    echo "Branch '$current_branch' must include an uppercase Jira key like ABC-123." >&2
    exit 1
fi

echo "Branch '$current_branch' is valid."
