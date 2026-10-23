import SwiftUI
import SceneKit

/// True hardware-accelerated 3D Earth Globe built with SceneKit & Metal shaders.
/// Renders an accurate, photorealistic Earth geometry using NASA Visible Earth satellite topography,
/// physically based ambient & directional sunlight, geographic orientation, and sensible pin clustering.
public struct SceneKitGlobeView: UIViewRepresentable {
    public let places: [Place]
    public var previewCoordinate: (latitude: Double, longitude: Double)? = nil
    public var selectedPlace: Place? = nil
    public var isTapModeActive: Bool = false
    public var onPlaceSelected: ((Place) -> Void)? = nil
    public var onGlobeTapped: ((Double, Double) -> Void)? = nil
    
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
    
    public func makeUIView(context: Context) -> SCNView {
        let scnView = SCNView()
        let scene = SCNScene()
        scnView.scene = scene
        scnView.backgroundColor = UIColor.clear
        scnView.antialiasingMode = .multisampling4X
        scnView.allowsCameraControl = true
        scnView.autoenablesDefaultLighting = false
        
        // 1. Camera Node with Natural Perspective & Depth Bounds
        let cameraNode = SCNNode()
        cameraNode.name = "cameraNode"
        let camera = SCNCamera()
        camera.zNear = 0.1
        camera.zFar = 100
        camera.fieldOfView = 45
        cameraNode.camera = camera
        cameraNode.position = SCNVector3(0, 0, 2.8)
        scene.rootNode.addChildNode(cameraNode)
        
        // 2. Realistic Spherical Illumination (Sunlight + Deep Ocean Ambient Fill)
        let sunLight = SCNLight()
        sunLight.type = .directional
        sunLight.color = UIColor(red: 1.0, green: 0.98, blue: 0.95, alpha: 1.0)
        sunLight.intensity = 1250
        let sunNode = SCNNode()
        sunNode.light = sunLight
        sunNode.position = SCNVector3(3.5, 2.5, 4.0)
        sunNode.look(at: SCNVector3(0, 0, 0))
        scene.rootNode.addChildNode(sunNode)
        
        // Fill light to gracefully illuminate the night side with deep ocean navy
        let fillLight = SCNLight()
        fillLight.type = .directional
        fillLight.color = UIColor(red: 0.08, green: 0.14, blue: 0.22, alpha: 1.0)
        fillLight.intensity = 450
        let fillNode = SCNNode()
        fillNode.light = fillLight
        fillNode.position = SCNVector3(-3.0, -1.5, -2.0)
        fillNode.look(at: SCNVector3(0, 0, 0))
        scene.rootNode.addChildNode(fillNode)
        
        let ambientLight = SCNLight()
        ambientLight.type = .ambient
        ambientLight.color = UIColor(red: 0.12, green: 0.18, blue: 0.24, alpha: 1.0)
        ambientLight.intensity = 350
        let ambientNode = SCNNode()
        ambientNode.light = ambientLight
        scene.rootNode.addChildNode(ambientNode)
        
        // 3. Globe Node with High-Resolution NASA Visible Earth Texture
        let globeRadius: CGFloat = 1.0
        let sphere = SCNSphere(radius: globeRadius)
        sphere.segmentCount = 128
        
        let earthMaterial = SCNMaterial()
        earthMaterial.lightingModel = .lambert
        
        // Load bundled NASA Visible Earth texture
        if let textureImage = UIImage(named: "earth_diffuse.jpg") ?? loadBundledEarthTexture() {
            earthMaterial.diffuse.contents = textureImage
            earthMaterial.diffuse.wrapS = .repeat
            earthMaterial.diffuse.wrapT = .clamp
            earthMaterial.diffuse.mipFilter = .linear
        } else {
            // Elegant cartographic fallback if texture load fails
            earthMaterial.diffuse.contents = UIColor(red: 0.06, green: 0.12, blue: 0.20, alpha: 1.0)
        }
        
        earthMaterial.specular.contents = UIColor(white: 0.25, alpha: 1.0)
        earthMaterial.shininess = 25.0
        earthMaterial.roughness.contents = 0.5
        sphere.materials = [earthMaterial]
        
        let globeNode = SCNNode(geometry: sphere)
        globeNode.name = "globeNode"
        scene.rootNode.addChildNode(globeNode)
        
        // 4. Subtle Atmospheric Glow Ring (Concentric, no giant white halo)
        let atmosphereSphere = SCNSphere(radius: globeRadius * 1.008)
        atmosphereSphere.segmentCount = 64
        let atmoMat = SCNMaterial()
        atmoMat.lightingModel = .constant
        atmoMat.diffuse.contents = UIColor(red: 0.45, green: 0.72, blue: 0.95, alpha: 0.06)
        atmoMat.isDoubleSided = false
        atmoMat.blendMode = .add
        atmosphereSphere.materials = [atmoMat]
        let atmoNode = SCNNode(geometry: atmosphereSphere)
        atmoNode.name = "atmoNode"
        globeNode.addChildNode(atmoNode)
        
        // 5. Tap Gesture Recognizer for raycast selection & tap-to-pin
        let tapGesture = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap(_:)))
        scnView.addGestureRecognizer(tapGesture)
        context.coordinator.scnView = scnView
        
        context.coordinator.updatePins(places: places, previewCoordinate: previewCoordinate, in: globeNode)
        
        return scnView
    }
    
    public func updateUIView(_ scnView: SCNView, context: Context) {
        guard let globeNode = scnView.scene?.rootNode.childNode(withName: "globeNode", recursively: false) else { return }
        
        context.coordinator.onPlaceSelected = onPlaceSelected
        context.coordinator.onGlobeTapped = onGlobeTapped
        context.coordinator.isTapModeActive = isTapModeActive
        
        context.coordinator.updatePins(places: places, previewCoordinate: previewCoordinate, in: globeNode)
        
        // Animate camera rotation to smoothly center on newly selected destination
        if let place = selectedPlace, context.coordinator.lastSelectedPlaceId != place.id {
            context.coordinator.lastSelectedPlaceId = place.id
            SCNTransaction.begin()
            SCNTransaction.animationDuration = 0.9
            SCNTransaction.animationTimingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            let latRad = Float(place.latitude * .pi / 180.0)
            let lonRad = Float(-place.longitude * .pi / 180.0)
            globeNode.eulerAngles = SCNVector3(latRad, lonRad, 0)
            SCNTransaction.commit()
        }
    }
    
    public func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    // MARK: - Texture Resource Loader
    
    private func loadBundledEarthTexture() -> UIImage? {
        let possiblePaths: [String?] = [
            Bundle.main.path(forResource: "earth_diffuse", ofType: "jpg"),
            Bundle.main.path(forResource: "earth_diffuse", ofType: "jpg", inDirectory: "Resources"),
            Bundle.main.bundleURL.appendingPathComponent("Resources/earth_diffuse.jpg").path,
            Bundle.main.bundleURL.appendingPathComponent("earth_diffuse.jpg").path
        ]
        for case let p? in possiblePaths {
            if FileManager.default.fileExists(atPath: p), let img = UIImage(contentsOfFile: p) {
                return img
            }
        }
        return nil
    }
    
    // MARK: - Coordinator & Cluster Node Manager
    
    public final class Coordinator: NSObject {
        var parent: SceneKitGlobeView
        weak var scnView: SCNView?
        var onPlaceSelected: ((Place) -> Void)?
        var onGlobeTapped: ((Double, Double) -> Void)?
        var isTapModeActive: Bool = false
        var lastSelectedPlaceId: String? = nil
        
        private var clusterMap: [String: [Place]] = [:]
        
        init(_ parent: SceneKitGlobeView) {
            self.parent = parent
            self.onPlaceSelected = parent.onPlaceSelected
            self.onGlobeTapped = parent.onGlobeTapped
            self.isTapModeActive = parent.isTapModeActive
        }
        
        /// Rebuilds place pin markers with clustering to prevent overlapping clutter.
        func updatePins(places: [Place], previewCoordinate: (latitude: Double, longitude: Double)?, in globeNode: SCNNode) {
            clusterMap.removeAll()
            
            // 1. Remove existing pin/cluster nodes
            globeNode.enumerateChildNodes { (node, _) in
                if node.name?.hasPrefix("pin_") == true ||
                   node.name?.hasPrefix("cluster_") == true ||
                   node.name == "preview_pin" {
                    node.removeFromParentNode()
                }
            }
            
            // 2. Cluster close places (angular distance < 3.5 degrees)
            var visitedPlaces = Set<String>()
            var clusters: [[Place]] = []
            
            for place in places {
                if visitedPlaces.contains(place.id) { continue }
                visitedPlaces.insert(place.id)
                
                var group = [place]
                for other in places {
                    if visitedPlaces.contains(other.id) { continue }
                    let distKm = CoordinateMath.haversineDistanceKm(
                        lat1: place.latitude, lon1: place.longitude,
                        lat2: other.latitude, lon2: other.longitude
                    )
                    // Approximately < 300 km threshold for globe scale clustering
                    if distKm < 300.0 {
                        visitedPlaces.insert(other.id)
                        group.append(other)
                    }
                }
                clusters.append(group)
            }
            
            // 3. Render Clusters or Individual Refined Pins
            for group in clusters {
                if group.count > 1 {
                    renderClusterNode(group: group, in: globeNode)
                } else if let single = group.first {
                    renderSinglePinNode(place: single, in: globeNode)
                }
            }
            
            // 4. Render Preview Pin (if setting a point via tap or geocoder preview)
            if let preview = previewCoordinate {
                let vec = CoordinateMath.toSphereVector(latitude: preview.latitude, longitude: preview.longitude, radius: 1.025)
                
                let prevGeom = SCNSphere(radius: 0.028)
                let prevMat = SCNMaterial()
                prevMat.diffuse.contents = UIColor(red: 1.0, green: 0.47, blue: 0.35, alpha: 1.0) // Sunset coral
                prevGeom.materials = [prevMat]
                
                let prevNode = SCNNode(geometry: prevGeom)
                prevNode.name = "preview_pin"
                prevNode.position = SCNVector3(vec.x, vec.y, vec.z)
                globeNode.addChildNode(prevNode)
            }
        }
        
        private func renderSinglePinNode(place: Place, in globeNode: SCNNode) {
            let vec = CoordinateMath.toSphereVector(latitude: place.latitude, longitude: place.longitude, radius: 1.018)
            
            // Spherical marker bead
            let isSelected = parent.selectedPlace?.id == place.id
            let beadRadius: CGFloat = isSelected ? 0.026 : 0.018
            let pinGeom = SCNSphere(radius: beadRadius)
            let pinMat = SCNMaterial()
            
            if place.isFavorite {
                pinMat.diffuse.contents = UIColor(red: 1.0, green: 0.72, blue: 0.01, alpha: 1.0) // Golden Amber
            } else if place.isVisited {
                pinMat.diffuse.contents = UIColor(red: 0.09, green: 0.29, blue: 0.26, alpha: 1.0) // Evergreen
            } else {
                pinMat.diffuse.contents = UIColor(red: 1.0, green: 0.47, blue: 0.35, alpha: 1.0) // Sunset Coral
            }
            pinMat.specular.contents = UIColor.white
            pinMat.shininess = 50.0
            pinGeom.materials = [pinMat]
            
            let pinNode = SCNNode(geometry: pinGeom)
            pinNode.name = "pin_\(place.id)"
            pinNode.position = SCNVector3(vec.x, vec.y, vec.z)
            
            // Selected Halo Ring
            if isSelected {
                let ringGeom = SCNTorus(ringRadius: 0.038, pipeRadius: 0.003)
                let ringMat = SCNMaterial()
                ringMat.diffuse.contents = UIColor(red: 1.0, green: 0.47, blue: 0.35, alpha: 0.9)
                ringGeom.materials = [ringMat]
                let ringNode = SCNNode(geometry: ringGeom)
                
                // Align ring with normal vector of the sphere surface
                ringNode.look(at: SCNVector3(vec.x * 2, vec.y * 2, vec.z * 2))
                pinNode.addChildNode(ringNode)
            }
            
            globeNode.addChildNode(pinNode)
        }
        
        private func renderClusterNode(group: [Place], in globeNode: SCNNode) {
            guard let representative = group.first else { return }
            let clusterId = "cluster_\(representative.id)"
            clusterMap[clusterId] = group
            
            // Mean coordinates of the cluster
            let meanLat = group.reduce(0.0) { $0 + $1.latitude } / Double(group.count)
            let meanLon = group.reduce(0.0) { $0 + $1.longitude } / Double(group.count)
            
            let vec = CoordinateMath.toSphereVector(latitude: meanLat, longitude: meanLon, radius: 1.022)
            
            // Cluster sphere geometry
            let clusterGeom = SCNSphere(radius: 0.032)
            let clusterMat = SCNMaterial()
            clusterMat.diffuse.contents = UIColor(red: 0.09, green: 0.29, blue: 0.26, alpha: 0.95) // Deep Evergreen
            clusterMat.specular.contents = UIColor.white
            clusterGeom.materials = [clusterMat]
            
            let clusterNode = SCNNode(geometry: clusterGeom)
            clusterNode.name = clusterId
            clusterNode.position = SCNVector3(vec.x, vec.y, vec.z)
            
            // Text badge indicator for cluster count
            let textGeom = SCNText(string: "\(group.count)", extrusionDepth: 0.005)
            textGeom.font = UIFont.systemFont(ofSize: 0.04, weight: .bold)
            let textMat = SCNMaterial()
            textMat.diffuse.contents = UIColor.white
            textGeom.materials = [textMat]
            
            let textNode = SCNNode(geometry: textGeom)
            textNode.scale = SCNVector3(0.3, 0.3, 0.3)
            textNode.position = SCNVector3(-0.015, -0.015, 0.02)
            clusterNode.addChildNode(textNode)
            
            globeNode.addChildNode(clusterNode)
        }
        
        @objc func handleTap(_ gesture: UITapGestureRecognizer) {
            guard let scnView = scnView else { return }
            let point = gesture.location(in: scnView)
            let hits = scnView.hitTest(point, options: [
                SCNHitTestOption.searchMode: SCNHitTestSearchMode.all.rawValue,
                SCNHitTestOption.ignoreHiddenNodes: true
            ])
            
            // 1. Check if tapped on an individual pin
            for hit in hits {
                if let nodeName = hit.node.name, nodeName.hasPrefix("pin_") {
                    let placeId = String(nodeName.dropFirst(4))
                    if let tappedPlace = parent.places.first(where: { $0.id == placeId }) {
                        onPlaceSelected?(tappedPlace)
                        return
                    }
                }
            }
            
            // 2. Check if tapped on a cluster badge
            for hit in hits {
                if let nodeName = hit.node.name, nodeName.hasPrefix("cluster_") {
                    if let clusterPlaces = clusterMap[nodeName], let first = clusterPlaces.first {
                        onPlaceSelected?(first)
                        return
                    }
                }
            }
            
            // 3. Check if tapped on the globe sphere surface (Raycast 3D Hit Test)
            for hit in hits {
                if hit.node.name == "globeNode" {
                    let localPoint = hit.localCoordinates
                    let r = sqrt(localPoint.x * localPoint.x + localPoint.y * localPoint.y + localPoint.z * localPoint.z)
                    guard r > 0.1 else { return }
                    
                    let latRad = asin(Double(localPoint.y / r))
                    let lonRad = atan2(Double(localPoint.x), Double(localPoint.z))
                    
                    let lat = CoordinateMath.rad2deg(latRad)
                    let lon = CoordinateMath.rad2deg(lonRad)
                    
                    if isTapModeActive {
                        onGlobeTapped?(lat, lon)
                    }
                    return
                }
            }
        }
    }
}
