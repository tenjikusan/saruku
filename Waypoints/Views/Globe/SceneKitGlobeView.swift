import SwiftUI
import SceneKit

/// True hardware-accelerated 3D Earth Globe built with SceneKit & Metal shaders.
/// Renders an accurate spherical 3D geometry with realistic ambient lighting, specular highlights,
/// dynamic 3D pin nodes positioned via spherical coordinates, and raycast hit-testing.
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
        
        // 1. Setup Camera
        let cameraNode = SCNNode()
        cameraNode.name = "cameraNode"
        let camera = SCNCamera()
        camera.zNear = 0.1
        camera.zFar = 100
        cameraNode.camera = camera
        cameraNode.position = SCNVector3(0, 0, 3.2)
        scene.rootNode.addChildNode(cameraNode)
        
        // 2. Setup Lighting (Atmospheric Sunlight + Ambient Glow)
        let sunLight = SCNLight()
        sunLight.type = .directional
        sunLight.color = UIColor(white: 1.0, alpha: 1.0)
        sunLight.intensity = 1100
        let sunNode = SCNNode()
        sunNode.light = sunLight
        sunNode.position = SCNVector3(3, 3, 5)
        sunNode.look(at: SCNVector3(0, 0, 0))
        scene.rootNode.addChildNode(sunNode)
        
        let ambientLight = SCNLight()
        ambientLight.type = .ambient
        ambientLight.color = UIColor(red: 0.15, green: 0.22, blue: 0.28, alpha: 1.0)
        ambientLight.intensity = 450
        let ambientNode = SCNNode()
        ambientNode.light = ambientLight
        scene.rootNode.addChildNode(ambientNode)
        
        // 3. Create 3D Earth Sphere Geometry
        let globeRadius: CGFloat = 1.0
        let sphere = SCNSphere(radius: globeRadius)
        sphere.segmentCount = 96
        
        let material = SCNMaterial()
        material.diffuse.contents = UIColor(red: 0.18, green: 0.35, blue: 0.38, alpha: 1.0) // Deep ocean
        material.specular.contents = UIColor(white: 0.3, alpha: 1.0)
        material.shininess = 30.0
        material.roughness.contents = 0.4
        sphere.materials = [material]
        
        let globeNode = SCNNode(geometry: sphere)
        globeNode.name = "globeNode"
        scene.rootNode.addChildNode(globeNode)
        
        // 4. Attach Tap Gesture Recognizer for raycast selection & tap-to-pin
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
        
        // Animate camera rotation to focus selected place
        if let place = selectedPlace, context.coordinator.lastSelectedPlaceId != place.id {
            context.coordinator.lastSelectedPlaceId = place.id
            SCNTransaction.begin()
            SCNTransaction.animationDuration = 0.8
            let latRad = Float(place.latitude * .pi / 180.0)
            let lonRad = Float(-place.longitude * .pi / 180.0)
            globeNode.eulerAngles = SCNVector3(latRad, lonRad, 0)
            SCNTransaction.commit()
        }
    }
    
    public func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    public final class Coordinator: NSObject {
        var parent: SceneKitGlobeView
        weak var scnView: SCNView?
        var onPlaceSelected: ((Place) -> Void)?
        var onGlobeTapped: ((Double, Double) -> Void)?
        var isTapModeActive: Bool = false
        var lastSelectedPlaceId: String? = nil
        
        init(_ parent: SceneKitGlobeView) {
            self.parent = parent
            self.onPlaceSelected = parent.onPlaceSelected
            self.onGlobeTapped = parent.onGlobeTapped
            self.isTapModeActive = parent.isTapModeActive
        }
        
        func updatePins(places: [Place], previewCoordinate: (latitude: Double, longitude: Double)?, in globeNode: SCNNode) {
            // Remove previous pin nodes
            globeNode.enumerateChildNodes { (node, _) in
                if node.name?.hasPrefix("pin_") == true || node.name == "preview_pin" {
                    node.removeFromParentNode()
                }
            }
            
            // Add Place Pins
            for place in places {
                let vec = CoordinateMath.toSphereVector(latitude: place.latitude, longitude: place.longitude, radius: 1.025)
                let pinGeom = SCNSphere(radius: 0.024)
                let pinMat = SCNMaterial()
                if place.isFavorite {
                    pinMat.diffuse.contents = UIColor.systemYellow
                } else if place.isVisited {
                    pinMat.diffuse.contents = UIColor(red: 0.35, green: 0.65, blue: 0.45, alpha: 1.0)
                } else {
                    pinMat.diffuse.contents = UIColor(red: 0.85, green: 0.45, blue: 0.28, alpha: 1.0) // Terracotta
                }
                pinGeom.materials = [pinMat]
                
                let pinNode = SCNNode(geometry: pinGeom)
                pinNode.name = "pin_\(place.id)"
                pinNode.position = SCNVector3(vec.x, vec.y, vec.z)
                globeNode.addChildNode(pinNode)
            }
            
            // Add Preview Pin
            if let preview = previewCoordinate {
                let vec = CoordinateMath.toSphereVector(latitude: preview.latitude, longitude: preview.longitude, radius: 1.03)
                let prevGeom = SCNSphere(radius: 0.035)
                let prevMat = SCNMaterial()
                prevMat.diffuse.contents = UIColor.systemRed
                prevGeom.materials = [prevMat]
                
                let prevNode = SCNNode(geometry: prevGeom)
                prevNode.name = "preview_pin"
                prevNode.position = SCNVector3(vec.x, vec.y, vec.z)
                globeNode.addChildNode(prevNode)
            }
        }
        
        @objc func handleTap(_ gesture: UITapGestureRecognizer) {
            guard let scnView = scnView else { return }
            let point = gesture.location(in: scnView)
            let hits = scnView.hitTest(point, options: [SCNHitTestOption.searchMode: SCNHitTestSearchMode.all.rawValue])
            
            // 1. Check if tapped on an existing pin
            for hit in hits {
                if let nodeName = hit.node.name, nodeName.hasPrefix("pin_") {
                    let placeId = String(nodeName.dropFirst(4))
                    if let tappedPlace = parent.places.first(where: { $0.id == placeId }) {
                        onPlaceSelected?(tappedPlace)
                        return
                    }
                }
            }
            
            // 2. Check if tapped on the globe sphere surface (Raycast 3D Hit Test)
            for hit in hits {
                if hit.node.name == "globeNode" {
                    let localPoint = hit.localCoordinates
                    let r = sqrt(localPoint.x * localPoint.x + localPoint.y * localPoint.y + localPoint.z * localPoint.z)
                    guard r > 0.1 else { return }
                    
                    let latRad = asin(Double(localPoint.y / r))
                    let lonRad = atan2(Double(localPoint.x), Double(localPoint.z))
                    
                    let lat = latRad * 180.0 / .pi
                    let lon = lonRad * 180.0 / .pi
                    
                    if isTapModeActive {
                        onGlobeTapped?(lat, lon)
                    }
                    return
                }
            }
        }
    }
}
