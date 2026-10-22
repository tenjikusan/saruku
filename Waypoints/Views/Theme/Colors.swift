import SwiftUI
import UIKit

// MARK: - Color Hex Initializers

public extension Color {
    init(hex: String) {
        let cleanHex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: cleanHex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch cleanHex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255.0,
            green: Double(g) / 255.0,
            blue: Double(b) / 255.0,
            opacity: Double(a) / 255.0
        )
    }
}

public extension UIColor {
    convenience init(hex: String) {
        let cleanHex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: cleanHex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch cleanHex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            red: CGFloat(r) / 255.0,
            green: CGFloat(g) / 255.0,
            blue: CGFloat(b) / 255.0,
            alpha: CGFloat(a) / 255.0
        )
    }
}

// MARK: - Premium Waypoints Semantic Theme System

public enum WaypointsColors {
    
    // Core Brand Palette Tokens (Light)
    public static let primaryEvergreen = Color(hex: "#164B43")
    public static let deepOcean = Color(hex: "#101F33")
    public static let backgroundPorcelain = Color(hex: "#F7F8F5")
    public static let textGraphite = Color(hex: "#202B30")
    public static let sunsetCoral = Color(hex: "#FF785A")
    public static let secondaryMuted = Color(hex: "#68777B")
    public static let borderSlate = Color(hex: "#E4E9E6")
    public static let cardSurface = Color(hex: "#FFFFFF")
    
    // Dark Mode Specific Tokens
    public static let darkBackground = Color(hex: "#0B131E")
    public static let darkCardSurface = Color(hex: "#121E2C")
    public static let darkBorder = Color(hex: "#1E3144")
    public static let darkTextPrimary = Color(hex: "#F0F4F5")
    public static let darkTextSecondary = Color(hex: "#8DA1A8")
    public static let darkEvergreen = Color(hex: "#267A6E")
    public static let darkSunsetCoral = Color(hex: "#FF8E75")

    // Adaptive Semantic Tokens (Dynamically adapts based on iOS system light/dark mode)
    public static var background: Color {
        Color(UIColor { trait in
            trait.userInterfaceStyle == .dark ? UIColor(hex: "#0B131E") : UIColor(hex: "#F7F8F5")
        })
    }
    
    public static var surface: Color {
        Color(UIColor { trait in
            trait.userInterfaceStyle == .dark ? UIColor(hex: "#121E2C") : UIColor(hex: "#FFFFFF")
        })
    }
    
    public static var border: Color {
        Color(UIColor { trait in
            trait.userInterfaceStyle == .dark ? UIColor(hex: "#1E3144") : UIColor(hex: "#E4E9E6")
        })
    }
    
    public static var textPrimary: Color {
        Color(UIColor { trait in
            trait.userInterfaceStyle == .dark ? UIColor(hex: "#F0F4F5") : UIColor(hex: "#202B30")
        })
    }
    
    public static var textSecondary: Color {
        Color(UIColor { trait in
            trait.userInterfaceStyle == .dark ? UIColor(hex: "#8DA1A8") : UIColor(hex: "#68777B")
        })
    }
    
    public static var brandPrimary: Color {
        Color(UIColor { trait in
            trait.userInterfaceStyle == .dark ? UIColor(hex: "#267A6E") : UIColor(hex: "#164B43")
        })
    }
    
    public static var accentCoral: Color {
        Color(UIColor { trait in
            trait.userInterfaceStyle == .dark ? UIColor(hex: "#FF8E75") : UIColor(hex: "#FF785A")
        })
    }
    
    // Legacy / Backwards Compatibility Aliases
    public static let deepForest = primaryEvergreen
    public static let terracotta = sunsetCoral
    public static let sandLight = background
    public static let cardBackground = surface
    public static let borderLight = border
}

// MARK: - Swift Extension for Color convenience

public extension Color {
    static let waypointsGreen = WaypointsColors.brandPrimary
    static let waypointsTerracotta = WaypointsColors.accentCoral
    static let waypointsEvergreen = WaypointsColors.primaryEvergreen
    static let waypointsOcean = WaypointsColors.deepOcean
    static let waypointsPorcelain = WaypointsColors.backgroundPorcelain
    static let waypointsGraphite = WaypointsColors.textGraphite
}
