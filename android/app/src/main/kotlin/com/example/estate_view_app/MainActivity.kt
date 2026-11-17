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
                "reconstructWallPlanes" -> {
                    val ceilingHeight = call.argument<Double>("ceilingHeight") ?: 2.8
                    val n = anchors.size
                    if (n < 3) {
                        result.success(
                            mapOf(
                                "status" to "INSUFFICIENT_ANCHORS",
                                "wallCount" to 0,
                                "walls" to emptyList<Map<String, Any>>(),
                                "floorPlane" to mapOf("type" to "HORIZONTAL_FLOOR", "normal" to listOf(0.0, 1.0, 0.0), "elevationMeters" to 0.0),
                                "ceilingPlane" to mapOf("type" to "HORIZONTAL_CEILING", "normal" to listOf(0.0, -1.0, 0.0), "elevationMeters" to ceilingHeight)
                            )
                        )
                        return@setMethodCallHandler
                    }

                    var centroidX = 0.0
                    var centroidZ = 0.0
                    for (a in anchors) {
                        centroidX += a["x"] ?: 0.0
                        centroidZ += a["z"] ?: (a["y"] ?: 0.0)
                    }
                    centroidX /= n
                    centroidZ /= n

                    val walls = mutableListOf<Map<String, Any>>()
                    var totalGrossWallArea = 0.0
                    var totalNetWallArea = 0.0
                    var totalOpenings = 0

                    for (i in 0 until n) {
                        val p1 = anchors[i]
                        val p2 = anchors[(i + 1) % n]
                        val x1 = p1["x"] ?: 0.0
                        val z1 = p1["z"] ?: (p1["y"] ?: 0.0)
                        val x2 = p2["x"] ?: 0.0
                        val z2 = p2["z"] ?: (p2["y"] ?: 0.0)

                        val dx = x2 - x1
                        val dz = z2 - z1
                        val length = sqrt(dx * dx + dz * dz)
                        if (length < 0.001) continue

                        var nx = -dz / length
                        var nz = dx / length

                        val midX = (x1 + x2) / 2.0
                        val midZ = (z1 + z2) / 2.0

                        val toCentroidX = centroidX - midX
                        val toCentroidZ = centroidZ - midZ
                        if (nx * toCentroidX + nz * toCentroidZ < 0) {
                            nx = -nx
                            nz = -nz
                        }

                        val grossArea = length * ceilingHeight
                        totalGrossWallArea += grossArea

                        val openings = mutableListOf<Map<String, Any>>()
                        var openingAreaSum = 0.0

                        if (i == 0 && length >= 2.0) {
                            val doorWidth = 0.95
                            val doorHeight = 2.10
                            val doorArea = doorWidth * doorHeight
                            openings.add(
                                mapOf(
                                    "type" to "DOOR_OPENING",
                                    "widthMeters" to doorWidth,
                                    "heightMeters" to doorHeight,
                                    "offsetMeters" to 0.45,
                                    "areaSqMeters" to doorArea
                                )
                            )
                            openingAreaSum += doorArea
                            totalOpenings++
                        } else if (length >= 3.2) {
                            val winWidth = (length * 0.55).coerceIn(1.6, 2.8)
                            val winHeight = 1.40
                            val winArea = winWidth * winHeight
                            openings.add(
                                mapOf(
                                    "type" to "WINDOW_OPENING",
                                    "widthMeters" to winWidth,
                                    "heightMeters" to winHeight,
                                    "offsetMeters" to (length - winWidth) / 2.0,
                                    "sillHeightMeters" to 0.90,
                                    "areaSqMeters" to winArea
                                )
                            )
                            openingAreaSum += winArea
                            totalOpenings++
                        }

                        val netArea = (grossArea - openingAreaSum).coerceAtLeast(0.0)
                        totalNetWallArea += netArea

                        val orientation = when {
                            nz > 0.7 -> "SOUTH_FACING"
                            nz < -0.7 -> "NORTH_FACING"
                            nx > 0.7 -> "EAST_FACING"
                            nx < -0.7 -> "WEST_FACING"
                            nz > 0 && nx > 0 -> "SOUTH_EAST"
                            nz > 0 && nx < 0 -> "SOUTH_WEST"
                            nz < 0 && nx > 0 -> "NORTH_EAST"
                            else -> "NORTH_WEST"
                        }

                        walls.add(
                            mapOf(
                                "id" to "wall-${i + 1}",
                                "wallIndex" to i,
                                "p1" to mapOf("x" to x1, "y" to 0.0, "z" to z1),
                                "p2" to mapOf("x" to x2, "y" to 0.0, "z" to z2),
                                "lengthMeters" to length,
                                "heightMeters" to ceilingHeight,
                                "normal" to listOf(nx, 0.0, nz),
                                "grossAreaSqMeters" to grossArea,
                                "netAreaSqMeters" to netArea,
                                "orientation" to orientation,
                                "openings" to openings
                            )
                        )
                    }

                    result.success(
                        mapOf(
                            "status" to "RECONSTRUCTED",
                            "wallCount" to walls.size,
                            "walls" to walls,
                            "floorPlane" to mapOf(
                                "type" to "HORIZONTAL_FLOOR",
                                "normal" to listOf(0.0, 1.0, 0.0),
                                "elevationMeters" to 0.0
                            ),
                            "ceilingPlane" to mapOf(
                                "type" to "HORIZONTAL_CEILING",
                                "normal" to listOf(0.0, -1.0, 0.0),
                                "elevationMeters" to ceilingHeight
                            ),
                            "totalGrossWallAreaSqMeters" to totalGrossWallArea,
                            "totalNetWallAreaSqMeters" to totalNetWallArea,
                            "totalOpeningsCount" to totalOpenings,
                            "ceilingHeightMeters" to ceilingHeight
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
