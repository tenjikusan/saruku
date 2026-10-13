import Foundation
import SwiftData

/// Schema migration plan for Waypoints native database.
/// Prepares versioning for safe schema evolution across iOS updates.
public enum WaypointsMigrationPlan: SchemaMigrationPlan {
    public static var schemas: [VersionedSchema.Type] = [
        WaypointsVersionedSchemaV1.self
    ]
    
    public static var stages: [MigrationStage] = [
        // Future migration stages will be registered here
    ]
}

public enum WaypointsVersionedSchemaV1: VersionedSchema {
    public static var versionIdentifier = Schema.Version(1, 0, 0)
    
    public static var models: [any PersistentModel.Type] = [
        Place.self,
        Discovery.self,
        CollectionModel.self
    ]
}
