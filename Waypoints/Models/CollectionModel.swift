import Foundation
import SwiftData

@Model
public final class CollectionModel {
    @Attribute(.unique) public var id: String
    public var name: String
    public var collectionDescription: String
    public var systemIcon: String
    public var colorHex: String
    public var coverImageFileName: String?
    public var isSmartCollection: Bool
    public var smartFilterType: String?
    public var sortOrder: String
    public var createdAt: Date
    public var updatedAt: Date
    
    @Relationship(deleteRule: .nullify)
    public var places: [Place] = []
    
    public init(
        id: String = UUID().uuidString,
        name: String,
        collectionDescription: String = "",
        systemIcon: String = "folder.fill",
        colorHex: String = "#244B3B",
        coverImageFileName: String? = nil,
        isSmartCollection: Bool = false,
        smartFilterType: String? = nil,
        sortOrder: String = "dateAdded",
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.collectionDescription = collectionDescription
        self.systemIcon = systemIcon
        self.colorHex = colorHex
        self.coverImageFileName = coverImageFileName
        self.isSmartCollection = isSmartCollection
        self.smartFilterType = smartFilterType
        self.sortOrder = sortOrder
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.places = []
    }
}
