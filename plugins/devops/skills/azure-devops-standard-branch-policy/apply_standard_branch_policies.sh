#!/usr/bin/env bash
set -euo pipefail

usage() {
    echo "Usage: $0 --repo <repo-name> --branches <branch1,branch2> [--org <org-url>] [--project <project-name>] [--build-definition-id <id>]" >&2
    exit 1
}

repo=""
branches=""
org=""
project=""
build_definition_id=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --repo) repo="$2"; shift 2 ;;
        --branches) branches="$2"; shift 2 ;;
        --org) org="$2"; shift 2 ;;
        --project) project="$2"; shift 2 ;;
        --build-definition-id) build_definition_id="$2"; shift 2 ;;
        *) usage ;;
    esac
done

if [[ -z "$repo" || -z "$branches" ]]; then
    usage
fi

echo "Applying standard branch policies for $repo on branches: $branches"
if [[ -n "$build_definition_id" ]]; then
    echo "Build validation enabled with definition ID $build_definition_id"
fi
