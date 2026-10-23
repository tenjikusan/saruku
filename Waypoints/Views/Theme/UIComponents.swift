import SwiftUI

public struct PrimaryButton: View {
    public let title: String
    public var icon: String? = nil
    public var isLoading: Bool = false
    public var isDisabled: Bool = false
    public let action: () -> Void
    
    public init(_ title: String, icon: String? = nil, isLoading: Bool = false, isDisabled: Bool = false, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.isLoading = isLoading
        self.isDisabled = isDisabled
        self.action = action
    }
    
    public var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if isLoading {
                    ProgressView()
                        .tint(.white)
                } else if let icon {
                    Image(systemName: icon)
                }
                Text(title)
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(isDisabled ? Color.gray.opacity(0.4) : Color.waypointsGreen)
            .foregroundColor(.white)
            .cornerRadius(14)
            .shadow(color: Color.waypointsGreen.opacity(isDisabled ? 0 : 0.25), radius: 6, y: 3)
        }
        .disabled(isDisabled || isLoading)
    }
}

public struct SubtleButton: View {
    public let title: String
    public var icon: String? = nil
    public let action: () -> Void
    @Environment(\.colorScheme) private var scheme
    
    public init(_ title: String, icon: String? = nil, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.action = action
    }
    
    public var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if let icon {
                    Image(systemName: icon)
                }
                Text(title)
                    .fontWeight(.medium)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(scheme == .dark ? Color.white.opacity(0.08) : Color.waypointsGreen.opacity(0.08))
            .foregroundColor(Color.waypointsGreen)
            .cornerRadius(12)
        }
    }
}

public struct StatusBadge: View {
    public let status: DiscoveryStatus
    
    public var body: some View {
        HStack(spacing: 4) {
            Image(systemName: status.systemIcon)
                .font(.caption2)
            Text(status.displayLabel)
                .font(WaypointsTypography.eyebrow)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color(hex: status.badgeColorHex).opacity(0.15))
        .foregroundColor(Color(hex: status.badgeColorHex))
        .cornerRadius(8)
    }
}

public struct ProvenanceBadge: View {
    public let provenance: CoordinateProvenance
    
    public var body: some View {
        HStack(spacing: 4) {
            Image(systemName: provenance.badgeIcon)
                .font(.caption2)
            Text(provenance.displayName)
                .font(WaypointsTypography.eyebrow)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.waypointsSage.opacity(0.18))
        .foregroundColor(Color.waypointsGreen)
        .cornerRadius(8)
    }
}

public struct CardContainer<Content: View>: View {
    @Environment(\.colorScheme) private var scheme
    public let content: () -> Content
    
    public init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
    }
    
    public var body: some View {
        content()
            .padding(16)
            .background(WaypointsTheme.surface(for: scheme))
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(WaypointsTheme.cardBorder(for: scheme), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(scheme == .dark ? 0.2 : 0.04), radius: 8, y: 3)
    }
}
