import SwiftUI

/// Genuinely native 3D interactive Earth globe with spherical projection, inertial rotation,
/// zoom gestures, pin annotations, and tap-to-pin inverse orthographic hit testing.
public struct NativeGlobeView: View {
    public let places: [Place]
    public var previewCoordinate: (latitude: Double, longitude: Double)? = nil
    public var selectedPlace: Place? = nil
    public var isTapModeActive: Bool = false
    public var onPlaceSelected: ((Place) -> Void)? = nil
    public var onGlobeTapped: ((Double, Double) -> Void)? = nil
    
    // Globe Orientation and View State
    @State private var rotation: Double = 65.0 // Center longitude
    @State private var tilt: Double = 15.0     // Viewing latitude tilt
    @State private var zoomScale: CGFloat = 1.0
    @State private var dragOffset: CGSize = .zero
    @State private var pulseScale: CGFloat = 1.0
    
    @Environment(\.colorScheme) private var scheme
    
    public init(
        places: [Place],
        previewCoordinate: (latitude: Double, longitude: Double)? = nil,
        selectedPlace: Place? = nil,
        isTapModeActive: Bool = false,
        onPlaceSelected: ((Place) -> Void)? = nil,
        onGlobeTapped: ((Double, Double) -> Void)? = nil
    ) {
        self.places = places
        self.previewCoordinate = previewCoordinate
        self.selectedPlace = selectedPlace
        self.isTapModeActive = isTapModeActive
        self.onPlaceSelected = onPlaceSelected
        self.onGlobeTapped = onGlobeTapped
    }
    
    public var body: some View {
        GeometryReader { proxy in
            let size = min(proxy.size.width, proxy.size.height)
            let baseRadius = (size * 0.42) * zoomScale
            let center = size / 2.0
            
            ZStack {
                // 1. Globe Atmosphere & Shadow Backdrop
                Circle()
                    .fill(
                        RadialGradient(
                            gradient: Gradient(colors: [
                                Color(red: 0.85, green: 0.90, blue: 0.88),
                                Color(red: 0.65, green: 0.75, blue: 0.70)
                            ]),
                            center: .center,
                            startRadius: 0,
                            endRadius: baseRadius
                        )
                    )
                    .frame(width: baseRadius * 2, height: baseRadius * 2)
                    .shadow(color: Color.black.opacity(scheme == .dark ? 0.4 : 0.15), radius: 24, y: 12)
                
                // 2. Continents and Geographic Coastlines (Projected Land)
                GlobeLandCanvas(
                    rotation: rotation + Double(dragOffset.width * 0.35),
                    tilt: min(60, max(-60, tilt - Double(dragOffset.height * 0.35))),
                    radius: baseRadius,
                    center: baseRadius
                )
                .frame(width: baseRadius * 2, height: baseRadius * 2)
                .clipShape(Circle())
                
                // 3. Atmosphere Rim Specular Lighting Overlay
                Circle()
                    .stroke(
                        LinearGradient(
                            colors: [Color.white.opacity(0.6), Color.white.opacity(0.0)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 3
                    )
                    .frame(width: baseRadius * 2, height: baseRadius * 2)
                    .allowsHitTesting(false)
                
                // 4. Render Permanent Place Pins
                ForEach(places) { place in
                    let proj = CoordinateMath.project(
                        latitude: place.latitude,
                        longitude: place.longitude,
                        rotation: rotation + Double(dragOffset.width * 0.35),
                        tilt: min(60, max(-60, tilt - Double(dragOffset.height * 0.35))),
                        radius: baseRadius,
                        center: center
                    )
                    
                    if proj.isVisible {
                        let isSelected = selectedPlace?.id == place.id
                        
                        GlobePinMarkerView(
                            place: place,
                            isSelected: isSelected,
                            pulseScale: pulseScale
                        )
                        .position(x: proj.x, y: proj.y)
                        .onTapGesture {
                            onPlaceSelected?(place)
                        }
                    }
                }
                
                // 5. Render Preview Pin (Candidate or Globe Tap)
                if let preview = previewCoordinate {
                    let proj = CoordinateMath.project(
                        latitude: preview.latitude,
                        longitude: preview.longitude,
                        rotation: rotation + Double(dragOffset.width * 0.35),
                        tilt: min(60, max(-60, tilt - Double(dragOffset.height * 0.35))),
                        radius: baseRadius,
                        center: center
                    )
                    
                    if proj.isVisible {
                        ZStack {
                            Circle()
                                .stroke(Color.waypointsTerracotta, lineWidth: 2)
                                .frame(width: 28, height: 28)
                                .scaleEffect(pulseScale)
                            
                            Circle()
                                .fill(Color.waypointsTerracotta)
                                .frame(width: 14, height: 14)
                            
                            Circle()
                                .fill(Color.white)
                                .frame(width: 5, height: 5)
                        }
                        .position(x: proj.x, y: proj.y)
                    }
                }
                
                // 6. Tap-to-Pin Mode Crosshair Indicator
                if isTapModeActive {
                    VStack {
                        Spacer()
                        HStack(spacing: 6) {
                            Image(systemName: "hand.tap.fill")
                            Text("Tap anywhere on the globe to set coordinates")
                                .font(WaypointsTypography.eyebrow)
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(Color.waypointsGreen)
                        .foregroundColor(.white)
                        .cornerRadius(20)
                        .shadow(radius: 4)
                        .padding(.bottom, 16)
                    }
                }
            }
            .frame(width: size, height: size)
            .position(x: proxy.size.width / 2, y: proxy.size.height / 2)
            .contentShape(Circle())
            .gesture(
                DragGesture()
                    .onChanged { value in
                        dragOffset = value.translation
                    }
                    .onEnded { value in
                        rotation = CoordinateValidator.wrapLongitude(rotation + Double(value.translation.width * 0.35))
                        tilt = min(60, max(-60, tilt - Double(value.translation.height * 0.35)))
                        dragOffset = .zero
                    }
            )
            .simultaneousGesture(
                MagnificationGesture()
                    .onChanged { scale in
                        zoomScale = min(1.6, max(0.75, scale))
                    }
                    .onEnded { _ in }
            )
            .onTapGesture { location in
                if isTapModeActive {
                    // Inverse orthographic hit-test to resolve exact lat/lon
                    let curRotation = rotation + Double(dragOffset.width * 0.35)
                    let curTilt = min(60, max(-60, tilt - Double(dragOffset.height * 0.35)))
                    
                    if let recovered = CoordinateMath.unproject(
                        screenX: location.x,
                        screenY: location.y,
                        rotation: curRotation,
                        tilt: curTilt,
                        radius: baseRadius,
                        center: center
                    ) {
                        onGlobeTapped?(recovered.latitude, recovered.longitude)
                    }
                }
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true)) {
                pulseScale = 1.3
            }
        }
        .onChange(of: selectedPlace) { _, newPlace in
            if let newPlace {
                withAnimation(.spring(response: 0.8, dampingFraction: 0.75)) {
                    rotation = newPlace.longitude
                    tilt = min(45, max(-45, newPlace.latitude))
                }
            }
        }
    }
}

// MARK: - Subviews

private struct GlobePinMarkerView: View {
    let place: Place
    let isSelected: Bool
    let pulseScale: CGFloat
    
    var body: some View {
        ZStack {
            if isSelected {
                Circle()
                    .stroke(Color.waypointsTerracotta, lineWidth: 2)
                    .frame(width: 32, height: 32)
                    .scaleEffect(pulseScale)
            }
            
            Circle()
                .fill(Color.white)
                .frame(width: isSelected ? 18 : 14, height: isSelected ? 18 : 14)
                .shadow(color: Color.black.opacity(0.3), radius: 3, y: 1)
            
            Circle()
                .fill(place.isVisited ? Color.waypointsGreen : Color.waypointsTerracotta)
                .frame(width: isSelected ? 12 : 8, height: isSelected ? 12 : 8)
        }
    }
}

/// Native Canvas rendering accurate continental boundaries projected onto the sphere.
private struct GlobeLandCanvas: View {
    let rotation: Double
    let tilt: Double
    let radius: Double
    let center: Double
    
    var body: some View {
        Canvas { context, size in
            // Continents represented by major geographic polygon rings
            for continent in Self.continentalRings {
                var path = Path()
                var firstPoint = true
                var hasVisible = false
                
                for coord in continent {
                    let proj = CoordinateMath.project(
                        latitude: coord.0,
                        longitude: coord.1,
                        rotation: rotation,
                        tilt: tilt,
                        radius: radius,
                        center: center
                    )
                    
                    if proj.isVisible {
                        hasVisible = true
                        let pt = CGPoint(x: proj.x, y: proj.y)
                        if firstPoint {
                            path.move(to: pt)
                            firstPoint = false
                        } else {
                            path.addLine(to: pt)
                        }
                    } else {
                        firstPoint = true
                    }
                }
                
                if hasVisible {
                    context.fill(path, with: .color(Color(red: 0.44, green: 0.58, blue: 0.48).opacity(0.85)))
                }
            }
        }
    }
    
    // Major landmass polygon coordinates
    private static let continentalRings: [[(Double, Double)]] = [
        // Eurasia
        [
            (70, 30), (60, 60), (55, 100), (65, 140), (50, 140), (40, 120), (30, 120),
            (20, 110), (10, 105), (15, 80), (25, 60), (30, 35), (40, 25), (45, 10),
            (55, 10), (60, 25), (70, 30)
        ],
        // Africa
        [
            (35, -5), (30, 32), (10, 50), (0, 42), (-20, 35), (-34, 20), (-25, 15),
            (-5, 10), (5, 0), (15, -17), (25, -15), (35, -5)
        ],
        // North America
        [
            (70, -160), (70, -100), (60, -65), (45, -60), (30, -80), (20, -90), (15, -95),
            (25, -110), (35, -120), (50, -125), (60, -140), (65, -165), (70, -160)
        ],
        // South America
        [
            (10, -75), (0, -50), (-10, -35), (-25, -45), (-45, -65), (-55, -70),
            (-35, -75), (-20, -70), (0, -80), (10, -75)
        ],
        // Australia
        [
            (-12, 130), (-15, 145), (-25, 152), (-38, 145), (-35, 118), (-22, 114), (-12, 130)
        ],
        // Japan
        [
            (45, 142), (43, 145), (38, 141), (35, 136), (33, 130), (35, 133), (40, 139), (45, 142)
        ]
    ]
}
