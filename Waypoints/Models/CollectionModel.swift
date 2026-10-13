import Foundation
import SwiftData

@Model
public final class CollectionModel {
    @Attribute(.unique) public var id: String
    public var name: String
    public var systemIcon: String
    public var colorHex: String
    public var createdAt: Date
    
    @Relationship(deleteRule: .nullify)
    public var places: [Place] = []
    
    public init(
        id: String = UUID().uuidString,
        name: String,
        systemIcon: String = "folder.fill",
        colorHex: String = "#244B3B",
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.systemIcon = systemIcon
        self.colorHex = colorHex
        self.createdAt = createdAt
        self.places = []
    }
}
