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

      default:
        result(FlutterMethodNotImplemented)
      }
    })

    let eventChannel = FlutterEventChannel(name: eventChannelName, binaryMessenger: controller.binaryMessenger)
    eventChannel.setStreamHandler(self)

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
