## Purpose

Provide focused, cross-workload Fabric data-engineering and migration orchestration without importing unrelated Fabric personas or loading irrelevant workload guidance.

## ADDED Requirements

### Requirement: Data-engineering requests route to focused personas

The system SHALL provide `FabricDataEngineer` for cross-workload Fabric data-engineering requests and `FabricMigrationEngineer` for migrations from Azure Synapse Analytics, Azure HDInsight, or Databricks. Each persona SHALL delegate endpoint-specific work to the approved specialist skills rather than attempting to preload or own every workload implementation.

#### Scenario: Cross-workload data-engineering request

- **WHEN** a user requests a data-engineering workflow spanning Spark, Warehouse, pipelines, Lakehouse, real-time analytics, or data quality
- **THEN** the system uses `FabricDataEngineer` and routes endpoint-specific work to the relevant specialist skill

#### Scenario: Cross-platform migration request

- **WHEN** a user requests migration from Synapse, HDInsight, or Databricks to Fabric
- **THEN** the system uses `FabricMigrationEngineer` and follows assessment, phased planning, validation, and cutover orchestration

### Requirement: Approved dependency closure is available

The system SHALL make available the specialist capabilities required by the two personas: Spark/Lakehouse, Warehouse SQL, Eventhouse, Eventstream, Dataflows, Medallion architecture, and Synapse, HDInsight, and Databricks migration. FabricIQ consumption SHALL be available through the separately planned FabricIQ capability before any persona routes read-only report or semantic-model questions to it.

#### Scenario: Endpoint-specific work is delegated

- **WHEN** a data-engineering request requires Spark notebook work, Warehouse SQL, KQL/Eventhouse, Eventstream, Dataflow, or source-platform migration changes
- **THEN** the system routes the implementation to the corresponding approved specialist capability

#### Scenario: FabricIQ companion capability is unavailable

- **WHEN** a persona receives a read-only Power BI data question before the FabricIQ consumption capability is installed and verified
- **THEN** the system reports that the FabricIQ capability is unavailable and does not route to a missing skill

### Requirement: Shared guidance is progressively disclosed

The system SHALL retain only the shared reference materials required by the approved dependency closure. Agents and skills SHALL load shared guidance only when the active workflow requires it and SHALL not preload unrelated Fabric workload documentation.

#### Scenario: Single-endpoint task

- **WHEN** a request concerns one endpoint such as a Warehouse SQL change
- **THEN** the system loads the Warehouse-specific skill and only its relevant references without loading unrelated Spark, Eventstream, or migration materials

### Requirement: Unapproved reference capabilities remain excluded

The system SHALL not expose `FabricAdmin`, `FabricAppDev`, the `FabricIQ` persona, ontology authoring, governance, or unrelated upstream Fabric skills as part of this change.

#### Scenario: Request targets an excluded persona

- **WHEN** a user requests work that requires an excluded persona or capability
- **THEN** the system does not claim that the excluded upstream capability was installed by this change
