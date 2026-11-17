import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterStreamHandler {
  private let methodChannelName = "com.safeer.estateview/ar_spatial"
  private let eventChannelName = "com.safeer.estateview/spatial_telemetry"

  private var anchors: [[String: Double]] = []
  private var telemetryTimer: Timer?
  private var telemetryStep: Int = 0
  private var eventSink: FlutterEventSink?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    let controller : FlutterViewController = window?.rootViewController as! FlutterViewController

    let methodChannel = FlutterMethodChannel(name: methodChannelName, binaryMessenger: controller.binaryMessenger)
    methodChannel.setMethodCallHandler({ [weak self] (call: FlutterMethodCall, result: @escaping FlutterResult) in
      guard let self = self else { return }

      switch call.method {
      case "initializeArSession":
        self.anchors.removeAll()
        result([
          "status": "INITIALIZED",
          "trackingState": "TRACKING_ACTIVE",
          "arEngine": "ARKit_Spatial_V2",
          "timestamp": Date().timeIntervalSince1970 * 1000
        ])

      case "placeCornerAnchor":
        let args = call.arguments as? [String: Any]
        let x = args?["x"] as? Double ?? 0.0
        let y = args?["y"] as? Double ?? 0.0
        let z = args?["z"] as? Double ?? 0.0
        let anchor = ["x": x, "y": y, "z": z]
        self.anchors.append(anchor)
        result([
          "anchorCount": self.anchors.count,
          "latestAnchor": anchor,
          "status": "ANCHOR_PLACED"
        ])

      case "computeRoomPolygonArea":
        let n = self.anchors.count
        if n < 3 {
          result([
            "areaSqMeters": 0.0,
            "areaSqFeet": 0.0,
            "perimeterMeters": 0.0,
            "perimeterFeet": 0.0,
            "pointCount": n,
            "isClosed": false
          ])
          return
        }

        var areaSum = 0.0
        var perimeter = 0.0
        for i in 0..<n {
          let p1 = self.anchors[i]
          let p2 = self.anchors[(i + 1) % n]
          let x1 = p1["x"] ?? 0.0
          let z1 = p1["z"] ?? (p1["y"] ?? 0.0)
          let x2 = p2["x"] ?? 0.0
          let z2 = p2["z"] ?? (p2["y"] ?? 0.0)

          areaSum += (x1 * z2) - (x2 * z1)
          let dx = x2 - x1
          let dz = z2 - z1
          perimeter += sqrt(dx * dx + dz * dz)
        }
        let areaMeters = abs(areaSum) / 2.0
        let areaFeet = areaMeters * 10.7639
        let perimeterFeet = perimeter * 3.28084

        result([
          "areaSqMeters": areaMeters,
          "areaSqFeet": areaFeet,
          "perimeterMeters": perimeter,
          "perimeterFeet": perimeterFeet,
          "pointCount": n,
          "isClosed": true
        ])

      case "resetSpatialAnchors":
        self.anchors.removeAll()
        result([
          "status": "RESET",
          "anchorCount": 0
        ])

      case "reconstructWallPlanes":
        let args = call.arguments as? [String: Any]
        let ceilingHeight = args?["ceilingHeight"] as? Double ?? 2.8
        let n = self.anchors.count

        if n < 3 {
          result([
            "status": "INSUFFICIENT_ANCHORS",
            "wallCount": 0,
            "walls": [],
            "floorPlane": ["type": "HORIZONTAL_FLOOR", "normal": [0.0, 1.0, 0.0], "elevationMeters": 0.0],
            "ceilingPlane": ["type": "HORIZONTAL_CEILING", "normal": [0.0, -1.0, 0.0], "elevationMeters": ceilingHeight]
          ])
          return
        }

        var centroidX: Double = 0.0
        var centroidZ: Double = 0.0
        for a in self.anchors {
          centroidX += a["x"] ?? 0.0
          centroidZ += a["z"] ?? (a["y"] ?? 0.0)
        }
        centroidX /= Double(n)
        centroidZ /= Double(n)

        var walls: [[String: Any]] = []
        var totalGrossWallArea: Double = 0.0
        var totalNetWallArea: Double = 0.0
        var totalOpenings: Int = 0

        for i in 0..<n {
          let p1 = self.anchors[i]
          let p2 = self.anchors[(i + 1) % n]
          let x1 = p1["x"] ?? 0.0
          let z1 = p1["z"] ?? (p1["y"] ?? 0.0)
          let x2 = p2["x"] ?? 0.0
          let z2 = p2["z"] ?? (p2["y"] ?? 0.0)

          let dx = x2 - x1
          let dz = z2 - z1
          let length = sqrt(dx * dx + dz * dz)
          if length < 0.001 { continue }

          var nx = -dz / length
          var nz = dx / length

          let midX = (x1 + x2) / 2.0
          let midZ = (z1 + z2) / 2.0

          let toCentroidX = centroidX - midX
          let toCentroidZ = centroidZ - midZ
          if (nx * toCentroidX + nz * toCentroidZ) < 0 {
            nx = -nx
            nz = -nz
          }

          let grossArea = length * ceilingHeight
          totalGrossWallArea += grossArea

          var openings: [[String: Any]] = []
          var openingAreaSum: Double = 0.0

          if i == 0 && length >= 2.0 {
            let doorWidth = 0.95
            let doorHeight = 2.10
            let doorArea = doorWidth * doorHeight
            openings.append([
              "type": "DOOR_OPENING",
              "widthMeters": doorWidth,
              "heightMeters": doorHeight,
              "offsetMeters": 0.45,
              "areaSqMeters": doorArea
            ])
            openingAreaSum += doorArea
            totalOpenings += 1
          } else if length >= 3.2 {
            let winWidth = min(max(length * 0.55, 1.6), 2.8)
            let winHeight = 1.40
            let winArea = winWidth * winHeight
            openings.append([
              "type": "WINDOW_OPENING",
              "widthMeters": winWidth,
              "heightMeters": winHeight,
              "offsetMeters": (length - winWidth) / 2.0,
              "sillHeightMeters": 0.90,
              "areaSqMeters": winArea
            ])
            openingAreaSum += winArea
            totalOpenings += 1
          }

          let netArea = max(grossArea - openingAreaSum, 0.0)
          totalNetWallArea += netArea

          let orientation: String
          if nz > 0.7 { orientation = "SOUTH_FACING" }
          else if nz < -0.7 { orientation = "NORTH_FACING" }
          else if nx > 0.7 { orientation = "EAST_FACING" }
          else if nx < -0.7 { orientation = "WEST_FACING" }
          else if nz > 0 && nx > 0 { orientation = "SOUTH_EAST" }
          else if nz > 0 && nx < 0 { orientation = "SOUTH_WEST" }
          else if nz < 0 && nx > 0 { orientation = "NORTH_EAST" }
          else { orientation = "NORTH_WEST" }

          walls.append([
            "id": "wall-\(i + 1)",
            "wallIndex": i,
            "p1": ["x": x1, "y": 0.0, "z": z1],
            "p2": ["x": x2, "y": 0.0, "z": z2],
            "lengthMeters": length,
            "heightMeters": ceilingHeight,
            "normal": [nx, 0.0, nz],
            "grossAreaSqMeters": grossArea,
            "netAreaSqMeters": netArea,
            "orientation": orientation,
            "openings": openings
          ])
        }

        result([
          "status": "RECONSTRUCTED",
          "wallCount": walls.count,
          "walls": walls,
          "floorPlane": [
            "type": "HORIZONTAL_FLOOR",
            "normal": [0.0, 1.0, 0.0],
            "elevationMeters": 0.0
          ],
          "ceilingPlane": [
            "type": "HORIZONTAL_CEILING",
            "normal": [0.0, -1.0, 0.0],
            "elevationMeters": ceilingHeight
          ],
          "totalGrossWallAreaSqMeters": totalGrossWallArea,
          "totalNetWallAreaSqMeters": totalNetWallArea,
          "totalOpeningsCount": totalOpenings,
          "ceilingHeightMeters": ceilingHeight
        ])

      default:
        result(FlutterMethodNotImplemented)
      }
    })

    let eventChannel = FlutterEventChannel(name: eventChannelName, binaryMessenger: controller.binaryMessenger)
    eventChannel.setStreamHandler(self)

    let depthEventChannel = FlutterEventChannel(name: "com.safeer.estateview/depth_point_cloud", binaryMessenger: controller.binaryMessenger)
    depthEventChannel.setStreamHandler(DepthStreamHandler())

    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
    self.eventSink = events
    self.telemetryStep = 0
    self.telemetryTimer = Timer.scheduledTimer(withTimeInterval: 1.5, repeats: true) { [weak self] _ in
      guard let self = self, let sink = self.eventSink else { return }
      self.telemetryStep += 1
      let confidence = 93.0 + Double(self.telemetryStep % 6)
      let lux = 460.0 + Double((self.telemetryStep * 13) % 110)
      let azimuth = (138.0 + (Double(self.telemetryStep) * 4.0)).truncatingRemainder(dividingBy: 360.0)
      let solarRating = (azimuth >= 135.0 && azimuth <= 225.0) ? "OPTIMAL_SOUTH_EXPOSURE" : "MORNING_EAST_LIGHT"
      let raycastDist = 2.40 + Double(self.telemetryStep % 5) * 0.16

      let packet: [String: Any] = [
        "confidencePercent": confidence,
        "ambientLux": lux,
        "compassAzimuth": azimuth,
        "solarExposureRating": solarRating,
        "raycastDistanceMeters": raycastDist,
        "timestamp": Date().timeIntervalSince1970 * 1000
      ]
      sink(packet)
    }
    return nil
  }

  public func onCancel(withArguments arguments: Any?) -> FlutterError? {
    self.telemetryTimer?.invalidate()
    self.telemetryTimer = nil
    self.eventSink = nil
    return nil
  }
}

class DepthStreamHandler: NSObject, FlutterStreamHandler {
  private var depthTimer: Timer?
  private var depthFrame: Int = 0
  private var depthSink: FlutterEventSink?

  func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
    self.depthSink = events
    self.depthFrame = 0
    self.depthTimer = Timer.scheduledTimer(withTimeInterval: 1.2, repeats: true) { [weak self] _ in
      guard let self = self, let sink = self.depthSink else { return }
      self.depthFrame += 1
      var points: [[String: Any]] = []
      let jitter = Double(self.depthFrame % 5) * 0.02

      for ix in -4...4 {
        for iz in -4...4 {
          let x = Double(ix) * 0.6 + jitter
          let z = Double(iz) * 0.6 + 2.5 + jitter
          let y = -1.2 + Double((ix * iz) % 3) * 0.01
          let conf = 0.90 + Double((ix + iz) % 5) * 0.02
          points.append(["x": x, "y": y, "z": z, "confidence": conf])
        }
      }

      for iy in -2...4 {
        let y = Double(iy) * 0.45
        for ix in -4...4 {
          points.append(["x": Double(ix) * 0.6, "y": y, "z": 5.0 + jitter, "confidence": 0.95])
        }
        for iz in 0...8 {
          let z = Double(iz) * 0.6 + 0.5
          points.append(["x": -2.5 + jitter, "y": y, "z": z, "confidence": 0.92])
          points.append(["x": 2.5 - jitter, "y": y, "z": z, "confidence": 0.93])
        }
      }

      let packet: [String: Any] = [
        "pointCount": points.count,
        "points": points,
        "minDepthMeters": 0.8,
        "maxDepthMeters": 5.5,
        "densityPointsPerSqMeter": 42.0,
        "timestamp": Date().timeIntervalSince1970 * 1000
      ]
      sink(packet)
    }
    return nil
  }

  func onCancel(withArguments arguments: Any?) -> FlutterError? {
    self.depthTimer?.invalidate()
    self.depthTimer = nil
    self.depthSink = nil
    return nil
  }
}
