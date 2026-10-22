import SwiftUI

public extension Color {
    /// Waypoints Signature Brand Palette
    static let waypointsGreen = Color(red: 0.141, green: 0.294, blue: 0.231) // #244B3B
    static let waypointsGreenLight = Color(red: 0.820, green: 0.880, blue: 0.840) // #D1E0D6
    static let waypointsTerracotta = Color(red: 0.851, green: 0.455, blue: 0.278) // #D97447
    static let waypointsSand = Color(red: 0.918, green: 0.835, blue: 0.729) // #EAD5BA
    static let waypointsSage = Color(red: 0.494, green: 0.608, blue: 0.533) // #7E9B88
    
    /// Adaptive Semantic Colors for Light and Dark Modes
    static let appBackground = Color("AppBackground", bundle: nil)
    static let appSurface = Color("AppSurface", bundle: nil)
    static let appBorder = Color("AppBorder", bundle: nil)
}

public struct WaypointsTheme {
    public static let primary = Color.waypointsGreen
    public static let accent = Color.waypointsTerracotta
    
    // Fallback adaptive colors
    public static func background(for scheme: ColorScheme) -> Color {
        scheme == .dark ? Color(red: 0.08, green: 0.10, blue: 0.09) : Color(red: 0.97, green: 0.98, blue: 0.96)
    }
    
    public static func surface(for scheme: ColorScheme) -> Color {
        scheme == .dark ? Color(red: 0.13, green: 0.16, blue: 0.14) : Color.white
    }
    
    public static func cardBorder(for scheme: ColorScheme) -> Color {
        scheme == .dark ? Color(white: 0.22) : Color(red: 0.89, green: 0.91, blue: 0.88)
    }
    
    public static func textPrimary(for scheme: ColorScheme) -> Color {
        scheme == .dark ? Color(red: 0.94, green: 0.95, blue: 0.93) : Color(red: 0.12, green: 0.18, blue: 0.14)
    }
    
    public static func textSecondary(for scheme: ColorScheme) -> Color {
        scheme == .dark ? Color(red: 0.65, green: 0.70, blue: 0.66) : Color(red: 0.42, green: 0.48, blue: 0.44)
    }
}

public enum WaypointsColors {
    public static let deepForest = Color(hex: "#244B3B")
    public static let terracotta = Color(hex: "#D97447")
    public static let sandLight = Color(hex: "#FAF9F5")
    public static let sandMedium = Color(hex: "#EAD5BA")
    public static let sageGreen = Color(hex: "#7E9B88")
    public static let sunsetAmber = Color(hex: "#D48B46")
    public static let cardBackground = Color.white
    public static let textPrimary = Color(hex: "#244B3B")
    public static let textSecondary = Color(hex: "#73816C")
    public static let borderLight = Color(hex: "#E6E9DF")
    public static let mintMist = Color(hex: "#E8F0EC")
}
