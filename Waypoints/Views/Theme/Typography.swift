import SwiftUI

public struct WaypointsTypography {
    public static let appTitle = Font.system(.title, design: .serif).weight(.bold)
    public static let headline = Font.system(.title2, design: .serif).weight(.semibold)
    public static let sectionHeader = Font.system(.title3, design: .serif).weight(.semibold)
    public static let subheadline = Font.system(.headline, design: .default).weight(.medium)
    public static let body = Font.system(.body, design: .default)
    public static let callout = Font.system(.callout, design: .default)
    public static let caption = Font.system(.caption, design: .default)
    public static let monoCaption = Font.system(.caption, design: .monospaced)
    public static let eyebrow = Font.system(size: 11, weight: .bold, design: .default)
    
    public static func display(_ size: CGFloat) -> Font {
        Font.system(size: size, weight: .bold, design: .serif)
    }
    
    public static func title(_ size: CGFloat) -> Font {
        Font.system(size: size, weight: .bold, design: .serif)
    }
}
