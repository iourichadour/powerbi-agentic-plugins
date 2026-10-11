---
name: fabriciq
description: Answer natural-language business questions from existing Power BI reports and semantic models through the verified FabricIQ MCP server. Use for report discovery, report metadata, semantic-model schema, entity-value resolution, and bounded DAX queries. Do not use for report CRUD, PBIR authoring, semantic-model edits, deployment, or ontology authoring.
metadata:
  version: 0.1.0
---

# FabricIQ Consumption

Use this skill for read-only, source-bound answers about existing Power BI
reports and semantic models. FabricIQ does not create, edit, deploy, refresh,
or delete report or semantic-model definitions.

## Availability gate

Use FabricIQ only when the configured `FabricIQ` MCP server exposes all six
local tools listed below. If any required tool is unavailable, state that
FabricIQ consumption is unavailable and do not fabricate an answer or route
the request to a non-existent capability.

## Local MCP tool contract

| Operation | Local tool | Required inputs and purpose |
|---|---|---|
| Discover artifacts | `FabricIQ-DiscoverArtifacts` | `searchQuery` plus optional `artifactTypes` (`Report`, `SemanticModel`) and `maxResults` (maximum 50). Finds tenant reports and semantic models. |
| Resolve artifact | `FabricIQ-ResolveFabricItem` | `fabricItemId`. Resolves a bare item GUID or supported Fabric/Power BI URL to its canonical item identity, item type, and workspace. |
| Read report context | `FabricIQ-GetReportMetadata` | `reportObjectId`, optionally up to five JMESPath `queries`. Returns workspace, semantic-model, pages, visuals, and filters. |
| Read model context | `FabricIQ-GetSemanticModelSchema` | `artifactId`, optionally up to five JMESPath `queries`. Returns schema, relationships, custom instructions, and verified answers. |
| Resolve values | `FabricIQ-ValueSearch` | `artifactId`, `searchTerms` (1–20), and optional table/column `scope`. Resolves names and filter values to exact model locations. |
| Execute DAX | `FabricIQ-ExecuteQuery` | `artifactId`, one to four `daxQueries`, each containing one `EVALUATE`, and optional `maxRows`. Executes bounded read-only queries. |

The tool schemas and response shapes above are authoritative for this local
installation. Do not substitute `powerbi-remote`, Fabric REST calls, or
invented tool names for these operations.

## Codex authentication and session bootstrap

The MCP server URL is fixed and must remain:

`https://fabriciq.svc.cloud.microsoft/v1/mcp/fabriciq`

The Codex registration must also include the `X-VARIANTS` header with value
`Fabric.Routing.FabricIQ.V1` and an `http_headers_helper` that returns a JSON
`Authorization` header. The helper should acquire a fresh token for the
`https://api.fabric.microsoft.com` resource with Azure CLI. Do not persist the
token in this skill or in repository configuration.

Do not append a tenant ID to the URL and do not store tenant IDs, access
tokens, client secrets, or other credentials in this skill.

The preferred long-term path is OAuth through `codex mcp login FabricIQ`. If
Codex reports an authorization-server issuer mismatch involving
`https://login.microsoftonline.com/{tenantid}/v2.0`, this is an OAuth
discovery compatibility issue between Codex and Microsoft Entra metadata, not
evidence that the FabricIQ URL or the user's tenant ID is wrong. Do not retry
the same login repeatedly or invent a tenant-specific endpoint. The durable
fix is a Codex version that accepts the Microsoft Entra `organizations`
metadata or a FabricIQ service metadata fix.

Until that fix is available, the supported local fallback is a bearer token
provided through an environment variable. The MCP registration must use
`--bearer-token-env-var FABRICIQ_TOKEN`, and the token must be acquired with
Azure CLI before Codex starts, for example:

```powershell
$env:FABRICIQ_TOKEN = az account get-access-token `
  --tenant <tenant-id> `
  --resource https://api.fabric.microsoft.com `
  --query accessToken -o tsv
```

Start or restart Codex from that same shell after refreshing the token. A
skill can detect missing authentication and explain this remediation, but it
cannot change the parent Codex process environment, refresh a token inside an
already-running session, or restart Codex. Never print, log, persist, or
include the token in an answer or repository file.

## Request workflow

1. **Classify the request.** Continue only for a business question about an
   existing Power BI report or semantic model.
2. **Resolve the artifact.** Use `FabricIQ-ResolveFabricItem` for a supplied
   supported Fabric or Power BI URL or bare item GUID. Otherwise use
   `FabricIQ-DiscoverArtifacts` with a non-empty search term and the
   appropriate artifact type. If no artifact is found, ask for a report or
   semantic-model name or URL. The resolver may identify a semantic model
   directly; do not assume every modeling URL is a report.
3. **Read context before querying.** For reports, call
   `FabricIQ-GetReportMetadata` and inspect applicable pages, visuals, and
   filters. Call `FabricIQ-GetSemanticModelSchema` for the report or model to
   inspect tables, relationships, custom instructions, and verified answers.
4. **Prefer governed answers.** If a verified answer matches the user's
   intent, use its bindings, granularity, and filters as the query contract.
   Follow semantic-model custom instructions before generating ad-hoc DAX.
5. **Resolve concrete values.** When the user names a customer, product,
   region, category, or other entity value, call `FabricIQ-ValueSearch` before
   generating filters. Use the highest-confidence contextual match and
   preserve the model's casing and table/column location.
6. **Preserve filters.** Retain applicable report, page, and visual filters.
   If the user explicitly requests a conflicting period or scope, apply that
   override, retain non-conflicting filters, and disclose the override.
7. **Query conservatively.** Generate bounded DAX with a single `EVALUATE`
   per query, execute no more than four queries in one call, and use the
   server's row limit. Query only fields needed to answer the question.
8. **Answer from results.** State the artifact and relevant filter context,
   summarize only returned data, and identify when the result is empty,
   ambiguous, or insufficient to support a conclusion.

## Routing boundaries

- Route report-definition CRUD to `powerbi-report-management`.
- Route PBIR pages, visuals, filters, themes, and formatting to
  `powerbi-report-authoring`.
- Route semantic-model tables, columns, measures, relationships, TMDL,
  deployment, or user-supplied DAX changes to `semantic-model-authoring`.
- Use `fabric-cli` for Fabric resource management, automation, deployment,
  and OneLake operations.
- Explain that unsupported artifact types require a Power BI report or
  semantic model instead.

## Failure handling

- **Unavailable tools or authentication:** explain that FabricIQ consumption
  is currently unavailable; do not fall back to an unverified capability.
- **No artifact match:** request a more specific name, workspace, or URL.
- **Multiple artifact matches:** present the distinguishing workspace/type
  details and ask the user to select one before querying.
- **Unsupported artifact:** explain the supported types and request a report
  or semantic model.
- **No query rows:** report that the selected filters produced no data; do
  not infer a value.
- **Conflicting governance:** follow custom instructions and verified answers,
  explain the conflict, and avoid an ad-hoc query when the request cannot be
  reconciled safely.
