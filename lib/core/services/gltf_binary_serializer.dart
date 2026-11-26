import 'dart:convert';
import 'dart:typed_data';

import '../../data/models/spatial_export_model.dart';

class GltfArchiveInspection {
  final bool isValidGlb;
  final int version;
  final int declaredTotalLength;
  final int actualTotalLength;
  final int jsonChunkLength;
  final int binChunkLength;
  final int nodeCount;
  final int meshCount;
  final int totalVertexCount;
  final int totalTriangleCount;
  final List<String> nodeNames;
  final Map<String, dynamic> gltfJson;

  const GltfArchiveInspection({
    required this.isValidGlb,
    required this.version,
    required this.declaredTotalLength,
    required this.actualTotalLength,
    required this.jsonChunkLength,
    required this.binChunkLength,
    required this.nodeCount,
    required this.meshCount,
    required this.totalVertexCount,
    required this.totalTriangleCount,
    required this.nodeNames,
    required this.gltfJson,
  });
}

/// Khronos glTF 2.0 Binary (.glb) serializer for architectural room meshes and furniture staging.
class GltfBinarySerializer {
  static const int glbMagic = 0x46546C67; // "glTF"
  static const int glbVersion = 2;
  static const int chunkTypeJson = 0x4E4F534A; // "JSON"
  static const int chunkTypeBin = 0x004E4942; // "BIN\0"

  static const int targetArrayBuffer = 34962;
  static const int targetElementArrayBuffer = 34963;
  static const int componentTypeFloat = 5126;
  static const int componentTypeUnsignedShort = 5123;

  Uint8List serialize(SpatialSceneGraph scene) {
    final nodes = <Map<String, dynamic>>[];
    final meshes = <Map<String, dynamic>>[];
    final accessors = <Map<String, dynamic>>[];
    final bufferViews = <Map<String, dynamic>>[];
    final binBuilder = BytesBuilder(copy: false);

    int writeAlignedBufferChunk(Uint8List rawBytes, int target) {
      // Pad buffer offset to 4 bytes before appending
      final currentOffset = binBuilder.length;
      final padBefore = (4 - (currentOffset % 4)) % 4;
      for (int i = 0; i < padBefore; i++) {
        binBuilder.addByte(0);
      }
      final alignedOffset = binBuilder.length;
      binBuilder.add(rawBytes);

      final viewIndex = bufferViews.length;
      bufferViews.add({
        'buffer': 0,
        'byteOffset': alignedOffset,
        'byteLength': rawBytes.length,
        'target': target,
      });
      return viewIndex;
    }

    int visitNode(MeshNodeData data) {
      final myIndex = nodes.length;
      final nodeMap = <String, dynamic>{
        'name': data.name,
        if (data.translation != null) 'translation': data.translation,
        if (data.rotationQuat != null) 'rotation': data.rotationQuat,
        if (data.scale != null) 'scale': data.scale,
      };
      nodes.add(nodeMap);

      if (data.hasMesh) {
        final posBytes = data.positions!.buffer.asUint8List(
          data.positions!.offsetInBytes,
          data.positions!.lengthInBytes,
        );
        final normBytes = data.normals!.buffer.asUint8List(
          data.normals!.offsetInBytes,
          data.normals!.lengthInBytes,
        );
        final idxBytes = data.indices!.buffer.asUint8List(
          data.indices!.offsetInBytes,
          data.indices!.lengthInBytes,
        );

        final posViewIdx = writeAlignedBufferChunk(posBytes, targetArrayBuffer);
        final normViewIdx = writeAlignedBufferChunk(
          normBytes,
          targetArrayBuffer,
        );
        final idxViewIdx = writeAlignedBufferChunk(
          idxBytes,
          targetElementArrayBuffer,
        );

        final posAccIdx = accessors.length;
        accessors.add({
          'bufferView': posViewIdx,
          'byteOffset': 0,
          'componentType': componentTypeFloat,
          'count': data.vertexCount,
          'type': 'VEC3',
          'min': data.computeMinBounds(),
          'max': data.computeMaxBounds(),
        });

        final normAccIdx = accessors.length;
        accessors.add({
          'bufferView': normViewIdx,
          'byteOffset': 0,
          'componentType': componentTypeFloat,
          'count': data.vertexCount,
          'type': 'VEC3',
        });

        final idxAccIdx = accessors.length;
        accessors.add({
          'bufferView': idxViewIdx,
          'byteOffset': 0,
          'componentType': componentTypeUnsignedShort,
          'count': data.indices!.length,
          'type': 'SCALAR',
        });

        final meshIdx = meshes.length;
        meshes.add({
          'name': '${data.name}_Mesh',
          'primitives': [
            {
              'attributes': {'POSITION': posAccIdx, 'NORMAL': normAccIdx},
              'indices': idxAccIdx,
              'material': data.materialIndex,
              'mode': 4, // TRIANGLES
            },
          ],
        });
        nodeMap['mesh'] = meshIdx;
      }

      if (data.children.isNotEmpty) {
        final childIndices = <int>[];
        for (final child in data.children) {
          childIndices.add(visitNode(child));
        }
        nodeMap['children'] = childIndices;
      }

      return myIndex;
    }

    final rootIndex = visitNode(scene.rootNode);

    // Pad total binary buffer length to multiple of 4
    final binPad = (4 - (binBuilder.length % 4)) % 4;
    for (int i = 0; i < binPad; i++) {
      binBuilder.addByte(0);
    }
    final binBytes = binBuilder.takeBytes();

    final gltfJson = <String, dynamic>{
      'asset': {
        'version': '2.0',
        'generator': 'EstateView Architectural Spatial Studio',
      },
      'scene': 0,
      'scenes': [
        {
          'name': scene.roomName,
          'nodes': [rootIndex],
        },
      ],
      'nodes': nodes,
      'meshes': meshes,
      'materials': scene.materials.map((m) {
        return {
          'name': m.name,
          'pbrMetallicRoughness': {
            'baseColorFactor': m.baseColorFactor,
            'metallicFactor': m.metallic,
            'roughnessFactor': m.roughness,
          },
          'doubleSided': true,
          if (m.transparent) 'alphaMode': 'BLEND',
        };
      }).toList(),
      'buffers': [
        {'byteLength': binBytes.length},
      ],
      'bufferViews': bufferViews,
      'accessors': accessors,
    };

    final rawJsonBytes = utf8.encode(jsonEncode(gltfJson));
    final jsonPad = (4 - (rawJsonBytes.length % 4)) % 4;
    final jsonChunkLength = rawJsonBytes.length + jsonPad;

    final totalLength = 12 + (8 + jsonChunkLength) + (8 + binBytes.length);

    final out = ByteData(totalLength);
    // 12-byte GLB header
    out.setUint32(0, glbMagic, Endian.little);
    out.setUint32(4, glbVersion, Endian.little);
    out.setUint32(8, totalLength, Endian.little);

    // Chunk 0: JSON header + padded UTF-8 payload
    var cursor = 12;
    out.setUint32(cursor, jsonChunkLength, Endian.little);
    out.setUint32(cursor + 4, chunkTypeJson, Endian.little);
    cursor += 8;
    final outBytes = out.buffer.asUint8List();
    outBytes.setRange(cursor, cursor + rawJsonBytes.length, rawJsonBytes);
    for (int i = 0; i < jsonPad; i++) {
      outBytes[cursor + rawJsonBytes.length + i] = 0x20; // ASCII space padding
    }
    cursor += jsonChunkLength;

    // Chunk 1: BIN header + payload
    out.setUint32(cursor, binBytes.length, Endian.little);
    out.setUint32(cursor + 4, chunkTypeBin, Endian.little);
    cursor += 8;
    outBytes.setRange(cursor, cursor + binBytes.length, binBytes);

    return outBytes;
  }

  /// Parses and validates a binary GLB file, extracting hierarchy and mesh counts.
  GltfArchiveInspection inspectGlb(Uint8List bytes) {
    if (bytes.length < 20) {
      throw const FormatException('GLB buffer too short for valid header.');
    }

    final view = ByteData.sublistView(bytes);
    final magic = view.getUint32(0, Endian.little);
    final version = view.getUint32(4, Endian.little);
    final totalLength = view.getUint32(8, Endian.little);

    final jsonChunkLen = view.getUint32(12, Endian.little);
    final jsonType = view.getUint32(16, Endian.little);

    if (magic != glbMagic ||
        version != glbVersion ||
        jsonType != chunkTypeJson) {
      throw const FormatException('Invalid GLB header or JSON chunk magic.');
    }

    const jsonStart = 20;
    final jsonEnd = jsonStart + jsonChunkLen;
    final jsonStr = utf8.decode(bytes.sublist(jsonStart, jsonEnd)).trimRight();
    final jsonMap = jsonDecode(jsonStr) as Map<String, dynamic>;

    int binChunkLen = 0;
    if (bytes.length >= jsonEnd + 8) {
      binChunkLen = view.getUint32(jsonEnd, Endian.little);
      final binType = view.getUint32(jsonEnd + 4, Endian.little);
      if (binType != chunkTypeBin) {
        throw const FormatException('Invalid GLB BIN chunk header.');
      }
    }

    final nodes = (jsonMap['nodes'] as List<dynamic>? ?? [])
        .cast<Map<String, dynamic>>();
    final meshes = (jsonMap['meshes'] as List<dynamic>? ?? [])
        .cast<Map<String, dynamic>>();
    final accessors = (jsonMap['accessors'] as List<dynamic>? ?? [])
        .cast<Map<String, dynamic>>();

    var vertexSum = 0;
    var indexSum = 0;
    for (final mesh in meshes) {
      final primitives = (mesh['primitives'] as List<dynamic>? ?? [])
          .cast<Map<String, dynamic>>();
      for (final prim in primitives) {
        final attrs = prim['attributes'] as Map<String, dynamic>? ?? {};
        final posIdx = attrs['POSITION'] as int?;
        final idxAcc = prim['indices'] as int?;
        if (posIdx != null && posIdx < accessors.length) {
          vertexSum += (accessors[posIdx]['count'] as num?)?.toInt() ?? 0;
        }
        if (idxAcc != null && idxAcc < accessors.length) {
          indexSum += (accessors[idxAcc]['count'] as num?)?.toInt() ?? 0;
        }
      }
    }

    final nodeNames = nodes
        .map((n) => n['name'] as String? ?? '')
        .where((s) => s.isNotEmpty)
        .toList();

    return GltfArchiveInspection(
      isValidGlb:
          magic == glbMagic &&
          version == glbVersion &&
          totalLength == bytes.length &&
          jsonChunkLen % 4 == 0 &&
          binChunkLen % 4 == 0,
      version: version,
      declaredTotalLength: totalLength,
      actualTotalLength: bytes.length,
      jsonChunkLength: jsonChunkLen,
      binChunkLength: binChunkLen,
      nodeCount: nodes.length,
      meshCount: meshes.length,
      totalVertexCount: vertexSum,
      totalTriangleCount: indexSum ~/ 3,
      nodeNames: nodeNames,
      gltfJson: jsonMap,
    );
  }
}
