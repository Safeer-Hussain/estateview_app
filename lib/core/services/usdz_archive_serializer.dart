import 'dart:convert';
import 'dart:typed_data';

import '../../data/models/spatial_export_model.dart';

class UsdzArchiveInspection {
  final bool isValidZip;
  final bool isUncompressedStore;
  final bool is64ByteAligned;
  final int payloadOffset;
  final String entryName;
  final int uncompressedSize;
  final String usdaContent;

  const UsdzArchiveInspection({
    required this.isValidZip,
    required this.isUncompressedStore,
    required this.is64ByteAligned,
    required this.payloadOffset,
    required this.entryName,
    required this.uncompressedSize,
    required this.usdaContent,
  });
}

/// Generates Apple Quick Look compatible .usdz archives containing an uncompressed
/// (STORE) Pixar USDA 1.0 scene aligned on a strict 64-byte boundary.
class UsdzArchiveSerializer {
  static const int _localFileHeaderSig = 0x04034B50;
  static const int _centralDirHeaderSig = 0x02014B50;
  static const int _endOfCentralDirSig = 0x06054B50;
  static const int _usdzAlignmentExtraTag = 0x1986;

  static final List<int> _crc32Table = _buildCrc32Table();

  Uint8List serialize(SpatialSceneGraph scene) {
    final usdaString = generateUsda(scene);
    final payloadBytes = Uint8List.fromList(utf8.encode(usdaString));
    const entryName = 'scene.usda';
    final nameBytes = Uint8List.fromList(utf8.encode(entryName));
    final crc = _computeCrc32(payloadBytes);

    // USDZ requirement: payload start offset must satisfy (offset % 64) == 0.
    // Local header fixed size is 30 bytes + filename length + extra length.
    final baseHeaderLen = 30 + nameBytes.length;
    var extraLen = (64 - (baseHeaderLen % 64)) % 64;
    // Extra field record must be 0 or >= 4 bytes (2-byte header id + 2-byte size)
    if (extraLen > 0 && extraLen < 4) {
      extraLen += 64;
    }

    final extraBytes = Uint8List(extraLen);
    if (extraLen >= 4) {
      final extraView = ByteData.sublistView(extraBytes);
      extraView.setUint16(0, _usdzAlignmentExtraTag, Endian.little);
      extraView.setUint16(2, extraLen - 4, Endian.little);
    }

    final payloadOffset = baseHeaderLen + extraLen;
    final centralDirOffset = payloadOffset + payloadBytes.length;
    final centralDirSize = 46 + nameBytes.length;
    const eocdSize = 22;
    final totalArchiveBytes = centralDirOffset + centralDirSize + eocdSize;

    final out = Uint8List(totalArchiveBytes);
    final view = ByteData.sublistView(out);

    // 1. Local File Header (30 bytes)
    view.setUint32(0, _localFileHeaderSig, Endian.little);
    view.setUint16(4, 20, Endian.little); // version needed: 2.0
    view.setUint16(6, 0x0800, Endian.little); // UTF-8 filename flag
    view.setUint16(8, 0, Endian.little); // compression: 0 = STORE (required)
    view.setUint16(10, 0, Endian.little); // mod time
    view.setUint16(12, 0x5421, Endian.little); // mod date
    view.setUint32(14, crc, Endian.little);
    view.setUint32(18, payloadBytes.length, Endian.little);
    view.setUint32(22, payloadBytes.length, Endian.little);
    view.setUint16(26, nameBytes.length, Endian.little);
    view.setUint16(28, extraLen, Endian.little);
    out.setRange(30, 30 + nameBytes.length, nameBytes);
    if (extraLen > 0) {
      out.setRange(30 + nameBytes.length, payloadOffset, extraBytes);
    }

    // 2. Uncompressed Payload (64-byte aligned)
    out.setRange(payloadOffset, centralDirOffset, payloadBytes);

    // 3. Central Directory File Header (46 bytes)
    var cd = centralDirOffset;
    view.setUint32(cd, _centralDirHeaderSig, Endian.little);
    view.setUint16(cd + 4, 20, Endian.little); // version made by
    view.setUint16(cd + 6, 20, Endian.little); // version needed
    view.setUint16(cd + 8, 0x0800, Endian.little); // UTF-8
    view.setUint16(cd + 10, 0, Endian.little); // STORE
    view.setUint16(cd + 12, 0, Endian.little);
    view.setUint16(cd + 14, 0x5421, Endian.little);
    view.setUint32(cd + 16, crc, Endian.little);
    view.setUint32(cd + 20, payloadBytes.length, Endian.little);
    view.setUint32(cd + 24, payloadBytes.length, Endian.little);
    view.setUint16(cd + 28, nameBytes.length, Endian.little);
    view.setUint16(cd + 30, 0, Endian.little); // no central extra field
    view.setUint16(cd + 32, 0, Endian.little); // comment len
    view.setUint16(cd + 34, 0, Endian.little); // disk number start
    view.setUint16(cd + 36, 0, Endian.little); // internal file attr
    view.setUint32(cd + 38, 0, Endian.little); // external file attr
    view.setUint32(
      cd + 42,
      0,
      Endian.little,
    ); // relative offset of local header
    out.setRange(cd + 46, cd + 46 + nameBytes.length, nameBytes);

    // 4. End of Central Directory Record (22 bytes)
    final eocd = centralDirOffset + centralDirSize;
    view.setUint32(eocd, _endOfCentralDirSig, Endian.little);
    view.setUint16(eocd + 4, 0, Endian.little);
    view.setUint16(eocd + 6, 0, Endian.little);
    view.setUint16(eocd + 8, 1, Endian.little); // total entries on disk
    view.setUint16(eocd + 10, 1, Endian.little); // total entries
    view.setUint32(eocd + 12, centralDirSize, Endian.little);
    view.setUint32(eocd + 16, centralDirOffset, Endian.little);
    view.setUint16(eocd + 20, 0, Endian.little); // zip comment len

    return out;
  }

  /// Generates Pixar/Apple USDA 1.0 text scene representation for Quick Look.
  String generateUsda(SpatialSceneGraph scene) {
    final buf = StringBuffer();
    buf.writeln('#usda 1.0');
    buf.writeln('(');
    buf.writeln('    defaultPrim = "EstateViewRoom"');
    buf.writeln(
      '    doc = "EstateView 3D Floorplan Export - ${_escapeString(scene.roomName)}"',
    );
    buf.writeln('    metersPerUnit = 1');
    buf.writeln('    upAxis = "Y"');
    buf.writeln(')');
    buf.writeln();
    buf.writeln('def Xform "EstateViewRoom" (');
    buf.writeln('    kind = "assembly"');
    buf.writeln(')');
    buf.writeln('{');

    // Materials scope
    buf.writeln('    def Scope "Materials"');
    buf.writeln('    {');
    for (final mat in scene.materials) {
      final c = mat.baseColorFactor;
      buf.writeln('        def Material "${mat.name}"');
      buf.writeln('        {');
      buf.writeln(
        '            token outputs:surface.connect = </EstateViewRoom/Materials/${mat.name}/PreviewSurface.outputs:surface>',
      );
      buf.writeln();
      buf.writeln('            def Shader "PreviewSurface"');
      buf.writeln('            {');
      buf.writeln(
        '                uniform token info:id = "UsdPreviewSurface"',
      );
      buf.writeln(
        '                color3f inputs:diffuseColor = (${c[0].toStringAsFixed(3)}, ${c[1].toStringAsFixed(3)}, ${c[2].toStringAsFixed(3)})',
      );
      buf.writeln(
        '                float inputs:metallic = ${mat.metallic.toStringAsFixed(2)}',
      );
      buf.writeln(
        '                float inputs:roughness = ${mat.roughness.toStringAsFixed(2)}',
      );
      if (mat.transparent) {
        buf.writeln(
          '                float inputs:opacity = ${c[3].toStringAsFixed(2)}',
        );
      }
      buf.writeln('                token outputs:surface');
      buf.writeln('            }');
      buf.writeln('        }');
    }
    buf.writeln('    }');
    buf.writeln();

    for (final child in scene.rootNode.children) {
      _writeNodeUsda(buf, child, scene.materials, indent: '    ');
    }

    buf.writeln('}');
    return buf.toString();
  }

  void _writeNodeUsda(
    StringBuffer buf,
    MeshNodeData node,
    List<SpatialMaterialSpec> materials, {
    required String indent,
  }) {
    final sanitized = node.name.replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '_');

    if (node.hasMesh) {
      buf.writeln('${indent}def Mesh "$sanitized" (');
      buf.writeln('$indent    prepend apiSchemas = ["MaterialBindingAPI"]');
      buf.writeln('$indent)');
      buf.writeln('$indent{');

      if (node.translation != null ||
          node.rotationQuat != null ||
          node.scale != null) {
        final ops = <String>[];
        if (node.translation != null) {
          final t = node.translation!;
          buf.writeln(
            '$indent    double3 xformOp:translate = (${t[0].toStringAsFixed(4)}, ${t[1].toStringAsFixed(4)}, ${t[2].toStringAsFixed(4)})',
          );
          ops.add('"xformOp:translate"');
        }
        if (node.rotationQuat != null) {
          final q = node.rotationQuat!;
          buf.writeln(
            '$indent    quatf xformOp:orient = (${q[3].toStringAsFixed(5)}, ${q[0].toStringAsFixed(5)}, ${q[1].toStringAsFixed(5)}, ${q[2].toStringAsFixed(5)})',
          );
          ops.add('"xformOp:orient"');
        }
        if (node.scale != null) {
          final s = node.scale!;
          buf.writeln(
            '$indent    float3 xformOp:scale = (${s[0].toStringAsFixed(4)}, ${s[1].toStringAsFixed(4)}, ${s[2].toStringAsFixed(4)})',
          );
          ops.add('"xformOp:scale"');
        }
        buf.writeln(
          '$indent    uniform token[] xformOpOrder = [${ops.join(', ')}]',
        );
      }

      final minB = node.computeMinBounds();
      final maxB = node.computeMaxBounds();
      buf.writeln(
        '$indent    float3[] extent = [(${minB[0].toStringAsFixed(4)}, ${minB[1].toStringAsFixed(4)}, ${minB[2].toStringAsFixed(4)}), (${maxB[0].toStringAsFixed(4)}, ${maxB[1].toStringAsFixed(4)}, ${maxB[2].toStringAsFixed(4)})]',
      );

      final triCounts = List.filled(node.triangleCount, '3').join(', ');
      buf.writeln('$indent    int[] faceVertexCounts = [$triCounts]');
      buf.writeln(
        '$indent    int[] faceVertexIndices = [${node.indices!.join(', ')}]',
      );

      final matName = materials[node.materialIndex!].name;
      buf.writeln(
        '$indent    rel material:binding = </EstateViewRoom/Materials/$matName>',
      );

      final pos = node.positions!;
      final pts = <String>[];
      for (int i = 0; i < pos.length; i += 3) {
        pts.add(
          '(${pos[i].toStringAsFixed(4)}, ${pos[i + 1].toStringAsFixed(4)}, ${pos[i + 2].toStringAsFixed(4)})',
        );
      }
      buf.writeln('$indent    point3f[] points = [${pts.join(', ')}]');

      final norm = node.normals!;
      final nrms = <String>[];
      for (int i = 0; i < norm.length; i += 3) {
        nrms.add(
          '(${norm[i].toStringAsFixed(4)}, ${norm[i + 1].toStringAsFixed(4)}, ${norm[i + 2].toStringAsFixed(4)})',
        );
      }
      buf.writeln('$indent    normal3f[] normals = [${nrms.join(', ')}] (');
      buf.writeln('$indent        interpolation = "vertex"');
      buf.writeln('$indent    )');
      buf.writeln('$indent    uniform token subdivisionScheme = "none"');

      for (final child in node.children) {
        buf.writeln();
        _writeNodeUsda(buf, child, materials, indent: '$indent    ');
      }

      buf.writeln('$indent}');
    } else {
      buf.writeln('${indent}def Xform "$sanitized"');
      buf.writeln('$indent{');
      for (final child in node.children) {
        _writeNodeUsda(buf, child, materials, indent: '$indent    ');
      }
      buf.writeln('$indent}');
    }
  }

  /// Parses a generated USDZ ZIP archive to verify Quick Look alignment and structure.
  UsdzArchiveInspection inspectUsdz(Uint8List bytes) {
    if (bytes.length < 64) {
      throw const FormatException('USDZ archive too short.');
    }

    final view = ByteData.sublistView(bytes);
    final sig = view.getUint32(0, Endian.little);
    final compression = view.getUint16(8, Endian.little);
    final crcStored = view.getUint32(14, Endian.little);
    final compSize = view.getUint32(18, Endian.little);
    final uncompSize = view.getUint32(22, Endian.little);
    final nameLen = view.getUint16(26, Endian.little);
    final extraLen = view.getUint16(28, Endian.little);

    final entryName = utf8.decode(bytes.sublist(30, 30 + nameLen));
    final payloadOffset = 30 + nameLen + extraLen;
    final payload = bytes.sublist(payloadOffset, payloadOffset + uncompSize);
    final crcActual = _computeCrc32(payload);

    final isValidZip =
        sig == _localFileHeaderSig &&
        compSize == uncompSize &&
        crcStored == crcActual;

    return UsdzArchiveInspection(
      isValidZip: isValidZip,
      isUncompressedStore: compression == 0,
      is64ByteAligned: payloadOffset % 64 == 0,
      payloadOffset: payloadOffset,
      entryName: entryName,
      uncompressedSize: uncompSize,
      usdaContent: utf8.decode(payload),
    );
  }

  static String _escapeString(String input) {
    return input.replaceAll('"', '\\"').replaceAll('\n', ' ');
  }

  static List<int> _buildCrc32Table() {
    final table = List<int>.filled(256, 0);
    for (int i = 0; i < 256; i++) {
      var c = i;
      for (int j = 0; j < 8; j++) {
        c = (c & 1) != 0 ? (0xEDB88320 ^ (c >>> 1)) : (c >>> 1);
      }
      table[i] = c;
    }
    return table;
  }

  static int _computeCrc32(Uint8List bytes) {
    var crc = 0xFFFFFFFF;
    for (final b in bytes) {
      crc = _crc32Table[(crc ^ b) & 0xFF] ^ (crc >>> 8);
    }
    return crc ^ 0xFFFFFFFF;
  }
}
