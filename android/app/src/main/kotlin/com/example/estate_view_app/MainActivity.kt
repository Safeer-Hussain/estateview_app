package com.example.estate_view_app

import android.os.Handler
import android.os.Looper
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import kotlin.math.abs
import kotlin.math.sqrt

class MainActivity : FlutterActivity() {
    private val methodChannelName = "com.safeer.estateview/ar_spatial"
    private val eventChannelName = "com.safeer.estateview/spatial_telemetry"
    private val depthEventChannelName = "com.safeer.estateview/depth_point_cloud"

    private val anchors = mutableListOf<Map<String, Double>>()
    private var telemetryHandler: Handler? = null
    private var telemetryRunnable: Runnable? = null
    private var telemetryStep = 0

    private var depthHandler: Handler? = null
    private var depthRunnable: Runnable? = null
    private var depthFrame = 0

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, methodChannelName).setMethodCallHandler { call, result ->
            when (call.method) {
                "initializeArSession" -> {
                    anchors.clear()
                    result.success(
                        mapOf(
                            "status" to "INITIALIZED",
                            "trackingState" to "TRACKING_ACTIVE",
                            "arEngine" to "ARCore_Spatial_V2",
                            "timestamp" to System.currentTimeMillis()
                        )
                    )
                }
                "placeCornerAnchor" -> {
                    val x = call.argument<Double>("x") ?: 0.0
                    val y = call.argument<Double>("y") ?: 0.0
                    val z = call.argument<Double>("z") ?: 0.0
                    val anchor = mapOf("x" to x, "y" to y, "z" to z)
                    anchors.add(anchor)
                    result.success(
                        mapOf(
                            "anchorCount" to anchors.size,
                            "latestAnchor" to anchor,
                            "status" to "ANCHOR_PLACED"
                        )
                    )
                }
                "computeRoomPolygonArea" -> {
                    if (anchors.size < 3) {
                        result.success(
                            mapOf(
                                "areaSqMeters" to 0.0,
                                "areaSqFeet" to 0.0,
                                "perimeterMeters" to 0.0,
                                "perimeterFeet" to 0.0,
                                "pointCount" to anchors.size,
                                "isClosed" to false
                            )
                        )
                        return@setMethodCallHandler
                    }

                    // Shoelace formula in 2D plane (x, z or x, y)
                    var areaSum = 0.0
                    var perimeter = 0.0
                    val n = anchors.size
                    for (i in 0 until n) {
                        val p1 = anchors[i]
                        val p2 = anchors[(i + 1) % n]
                        val x1 = p1["x"] ?: 0.0
                        val z1 = p1["z"] ?: (p1["y"] ?: 0.0)
                        val x2 = p2["x"] ?: 0.0
                        val z2 = p2["z"] ?: (p2["y"] ?: 0.0)

                        areaSum += (x1 * z2) - (x2 * z1)
                        val dx = x2 - x1
                        val dz = z2 - z1
                        perimeter += sqrt(dx * dx + dz * dz)
                    }
                    val areaMeters = abs(areaSum) / 2.0
                    val areaFeet = areaMeters * 10.7639
                    val perimeterFeet = perimeter * 3.28084

                    result.success(
                        mapOf(
                            "areaSqMeters" to areaMeters,
                            "areaSqFeet" to areaFeet,
                            "perimeterMeters" to perimeter,
                            "perimeterFeet" to perimeterFeet,
                            "pointCount" to n,
                            "isClosed" to true
                        )
                    )
                }
                "resetSpatialAnchors" -> {
                    anchors.clear()
                    result.success(
                        mapOf(
                            "status" to "RESET",
                            "anchorCount" to 0
                        )
                    )
                }
                else -> {
                    result.notImplemented()
                }
            }
        }

        EventChannel(flutterEngine.dartExecutor.binaryMessenger, eventChannelName).setStreamHandler(
            object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    telemetryHandler = Handler(Looper.getMainLooper())
                    telemetryRunnable = object : Runnable {
                        override fun run() {
                            telemetryStep++
                            val confidence = 91.0 + (telemetryStep % 7)
                            val lux = 450.0 + (telemetryStep * 11 % 120)
                            val azimuth = (142.5 + (telemetryStep * 4.2)) % 360.0
                            val solarRating = if (azimuth in 135.0..225.0) {
                                "OPTIMAL_SOUTH_EXPOSURE"
                            } else if (azimuth in 45.0..135.0) {
                                "MORNING_EAST_LIGHT"
                            } else {
                                "DIFFUSED_NORTH_LIGHT"
                            }
                            val raycastDist = 2.30 + ((telemetryStep % 6) * 0.18)

                            val telemetryPacket = mapOf(
                                "confidencePercent" to confidence,
                                "ambientLux" to lux,
                                "compassAzimuth" to azimuth,
                                "solarExposureRating" to solarRating,
                                "raycastDistanceMeters" to raycastDist,
                                "timestamp" to System.currentTimeMillis()
                            )
                            events?.success(telemetryPacket)
                            telemetryHandler?.postDelayed(this, 1500)
                        }
                    }
                    telemetryHandler?.post(telemetryRunnable!!)
                }

                override fun onCancel(arguments: Any?) {
                    telemetryRunnable?.let { telemetryHandler?.removeCallbacks(it) }
                    telemetryHandler = null
                    telemetryRunnable = null
                }
            }
        )

        EventChannel(flutterEngine.dartExecutor.binaryMessenger, depthEventChannelName).setStreamHandler(
            object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    depthHandler = Handler(Looper.getMainLooper())
                    depthRunnable = object : Runnable {
                        override fun run() {
                            depthFrame++
                            val pointsList = mutableListOf<Map<String, Double>>()

                            // Generate realistic room enclosure point cloud (floor, walls, ceiling)
                            val jitter = (depthFrame % 5) * 0.02
                            // Floor grid (-2.5 to 2.5 on X and Z)
                            for (ix in -4..4) {
                                for (iz in -4..4) {
                                    val x = ix * 0.6 + jitter
                                    val z = iz * 0.6 + 2.5 + jitter
                                    val y = -1.2 + ((ix * iz) % 3) * 0.01
                                    val conf = 0.90 + ((ix + iz) % 5) * 0.02
                                    pointsList.add(mapOf("x" to x, "y" to y, "z" to z, "confidence" to conf))
                                }
                            }

                            // Wall vertical planes (left, back, right)
                            for (iy in -2..4) {
                                val y = iy * 0.45
                                // Back wall (z = 5.0)
                                for (ix in -4..4) {
                                    val x = ix * 0.6
                                    pointsList.add(mapOf("x" to x, "y" to y, "z" to 5.0 + jitter, "confidence" to 0.95))
                                }
                                // Left wall (x = -2.5)
                                for (iz in 0..8) {
                                    val z = iz * 0.6 + 0.5
                                    pointsList.add(mapOf("x" to -2.5 + jitter, "y" to y, "z" to z, "confidence" to 0.92))
                                }
                                // Right wall (x = 2.5)
                                for (iz in 0..8) {
                                    val z = iz * 0.6 + 0.5
                                    pointsList.add(mapOf("x" to 2.5 - jitter, "y" to y, "z" to z, "confidence" to 0.93))
                                }
                            }

                            val packet = mapOf(
                                "pointCount" to pointsList.size,
                                "points" to pointsList,
                                "minDepthMeters" to 0.8,
                                "maxDepthMeters" to 5.5,
                                "densityPointsPerSqMeter" to 42.0,
                                "timestamp" to System.currentTimeMillis()
                            )
                            events?.success(packet)
                            depthHandler?.postDelayed(this, 1200)
                        }
                    }
                    depthHandler?.post(depthRunnable!!)
                }

                override fun onCancel(arguments: Any?) {
                    depthRunnable?.let { depthHandler?.removeCallbacks(it) }
                    depthHandler = null
                    depthRunnable = null
                }
            }
        )
    }
}
