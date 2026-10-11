# Fabric

Microsoft Fabric platform plugin that connects AI agents to Fabric workspaces, items, and APIs — enabling management, automation, and deployment across the entire Fabric ecosystem.

## What it does

Activated when a user needs to interact with Microsoft Fabric programmatically. Uses the `fab` CLI to perform operations across workspaces, items, lakehouses, notebooks, and REST APIs.

|  |  |
|--|--|
| Workspace management | "List all workspaces I have access to" |
| Item discovery | "What items are in my Production workspace?" |
| Export & import | "Export the Sales semantic model to a local folder" |
| Cross-workspace deployment | "Copy the ETL notebook from Dev to Prod" |
| Job execution | "Run the nightly refresh notebook and wait for it to finish" |
| OneLake file operations | "Upload this CSV to the lakehouse Files folder" |
| REST API calls | "Trigger a full refresh of the Sales dataset via the Power BI API" |

## Agents

### `fabric`

Activated for any Fabric platform task — managing workspaces, importing or exporting item definitions, running jobs, calling Fabric and Power BI REST APIs, orchestrating deployments across environments, or answering questions from existing Power BI artifacts. Use `fabric-cli` for resource operations and `fabriciq` for read-only business questions.

### `FabricDataEngineer`

Activated for cross-workload data-engineering requests spanning Spark, Warehouse,
Eventhouse, Eventstream, Dataflows, Lakehouse architecture, or semantic-model
coordination. Delegates endpoint-specific implementation to the selected
specialist skills and keeps environment, validation, and Delta Lake boundaries
explicit.

### `FabricMigrationEngineer`

Activated for Synapse Analytics, HDInsight, or Databricks migrations. Owns
assessment, phased mapping, conversion approval, validation, and cutover
readiness while delegating workload-specific work to the migration skills.

### Sample install prompt

```text
Use @setup-team-plugins.ps1 -PluginName fabric to install only the Fabric plugin.
```

## Skills

### `fabric-cli`

Activated when a user needs to run `fab` CLI commands to manage Fabric resources. Covers authentication, workspace and item listing, item import/export, job execution, OneLake file management, and direct calls to the Fabric, Power BI, and OneLake REST APIs.

### `fabriciq`

Activated for read-only natural-language questions over existing Power BI
reports and semantic models. FabricIQ discovers or resolves supported
artifacts, reads report and model context, resolves filter values, and
executes bounded DAX queries through the configured FabricIQ MCP server.
It does not create, edit, deploy, refresh, or delete artifacts.

FabricIQ is distinct from `fabric-cli`: use FabricIQ for business answers from
existing Power BI data, and `fabric-cli` for Fabric resource management,
automation, deployment, and OneLake operations. FabricIQ currently supports
Reports and Semantic Models only; Data Agents and workspace or organization
apps are outside its scope.

## Prerequisites

- **Fabric CLI (`fab`)** — [Install from the Microsoft Fabric documentation](https://learn.microsoft.com/en-us/fabric/cli/fabric-cli)
- **Microsoft Fabric account** with access to at least one workspace
- **Authentication** — Run `fab auth login` before first use to authenticate with your Microsoft account
- **FabricIQ MCP access** — The configured `FabricIQ` server must expose its
  required read-only tools and be authorized for the target Power BI artifacts.

### Data-engineering and migration skills

The Fabric plugin includes the selected specialist closure:

- `spark-cli`, `sqldw-cli`, `eventhouse-cli`, `eventstream-cli`, and `dataflows-cli`
  for endpoint-specific authoring, consumption, and operations.
- `e2e-medallion-architecture` for Bronze/Silver/Gold Lakehouse architecture.
- `synapse-migration`, `hdinsight-migration`, and `databricks-migration` for
  phased migration assessment and implementation.

These skills are loaded on demand by the two specialist agents. They do not
replace `fabric-cli`, which remains the broad Fabric resource-management owner,
or `semantic-model-authoring`, which remains the Power BI model-definition
owner.
