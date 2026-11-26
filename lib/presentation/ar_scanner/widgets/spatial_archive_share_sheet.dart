import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/di/injection.dart';
import '../../../core/services/gltf_binary_serializer.dart';
import '../../../core/services/spatial_archive_export_service.dart';
import '../../../core/services/usdz_archive_serializer.dart';
import '../../../core/utils/app_feedback.dart';
import '../../../data/models/plane_reconstruction_model.dart';
import '../../../data/models/spatial_export_model.dart';
import '../../../data/models/staged_furniture_model.dart';
import '../../../data/repositories/spatial_archive_repository.dart';

class SpatialArchiveShareSheet extends StatefulWidget {
  final String propertyId;
  final String roomName;
  final List<Offset> anchors;
  final RoomEnclosureModel? existingEnclosure;
  final List<StagedFurnitureModel> stagedFurniture;
  final bool anchorsAlreadyInMeters;
  final SpatialArchiveExportService? exportService;
  final SpatialArchiveRepository? archiveRepository;

  const SpatialArchiveShareSheet({
    super.key,
    required this.propertyId,
    required this.roomName,
    required this.anchors,
    this.existingEnclosure,
    this.stagedFurniture = const [],
    this.anchorsAlreadyInMeters = false,
    this.exportService,
    this.archiveRepository,
  });

  static Future<void> show(
    BuildContext context, {
    required String propertyId,
    required String roomName,
    required List<Offset> anchors,
    RoomEnclosureModel? existingEnclosure,
    List<StagedFurnitureModel> stagedFurniture = const [],
    bool anchorsAlreadyInMeters = false,
  }) {
    final colors = Theme.of(context).colorScheme;
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (bottomSheetContext) {
        return Container(
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(bottomSheetContext).viewInsets.bottom,
          ),
          child: SafeArea(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(bottomSheetContext).size.height * 0.88,
              ),
              child: SpatialArchiveShareSheet(
                propertyId: propertyId,
                roomName: roomName,
                anchors: anchors,
                existingEnclosure: existingEnclosure,
                stagedFurniture: stagedFurniture,
                anchorsAlreadyInMeters: anchorsAlreadyInMeters,
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  State<SpatialArchiveShareSheet> createState() =>
      _SpatialArchiveShareSheetState();
}

class _SpatialArchiveShareSheetState extends State<SpatialArchiveShareSheet> {
  SpatialArchiveFormat _selectedFormat = SpatialArchiveFormat.bundle;
  double _ceilingHeightMeters = 2.8;
  bool _includeFurniture = true;
  bool _isExporting = false;
  bool _showSchemaInspector = false;
  bool _inspectUsdaTab = false;

  SpatialArchiveExportBundle? _previewBundle;
  GltfArchiveInspection? _glbInspection;
  UsdzArchiveInspection? _usdzInspection;
  SpatialExportRecord? _savedRecord;

  late final SpatialArchiveExportService _service;
  SpatialArchiveRepository? _archiveRepo;

  @override
  void initState() {
    super.initState();
    _service =
        widget.exportService ??
        (sl.isRegistered<SpatialArchiveExportService>()
            ? sl<SpatialArchiveExportService>()
            : SpatialArchiveExportService());
    _archiveRepo =
        widget.archiveRepository ??
        (sl.isRegistered<SpatialArchiveRepository>()
            ? sl<SpatialArchiveRepository>()
            : null);
    _includeFurniture = widget.stagedFurniture.isNotEmpty;
    if (widget.existingEnclosure != null) {
      _ceilingHeightMeters = widget.existingEnclosure!.ceilingHeightMeters
          .clamp(2.4, 4.2);
    }
    _computePreviewSync();
    _rebuildPreview();
  }

  void _computePreviewSync() {
    final sceneGraph = _service.buildSceneGraphSync(
      roomName: widget.roomName,
      viewportAnchors: widget.anchors,
      existingEnclosure: widget.existingEnclosure,
      ceilingHeightMeters: _ceilingHeightMeters,
      stagedFurniture: _includeFurniture ? widget.stagedFurniture : const [],
      anchorsAlreadyInMeters: widget.anchorsAlreadyInMeters,
    );
    _applyScenePreview(sceneGraph, updateState: false);
  }

  void _applyScenePreview(
    SpatialSceneGraph sceneGraph, {
    required bool updateState,
  }) {
    final preview = _service.serializePreview(
      propertyId: widget.propertyId,
      sceneGraph: sceneGraph,
      format: _selectedFormat,
    );

    final glbInspect = preview.glbBytes != null
        ? _service.inspectGlbBytes(preview.glbBytes!)
        : null;
    final usdzInspect = preview.usdzBytes != null
        ? _service.inspectUsdzBytes(preview.usdzBytes!)
        : null;

    if (updateState) {
      setState(() {
        _previewBundle = preview;
        _glbInspection = glbInspect;
        _usdzInspection = usdzInspect;
      });
    } else {
      _previewBundle = preview;
      _glbInspection = glbInspect;
      _usdzInspection = usdzInspect;
    }
  }

  Future<void> _rebuildPreview() async {
    final sceneGraph = await _service.buildSceneGraph(
      roomName: widget.roomName,
      viewportAnchors: widget.anchors,
      existingEnclosure: widget.existingEnclosure,
      ceilingHeightMeters: _ceilingHeightMeters,
      stagedFurniture: _includeFurniture ? widget.stagedFurniture : const [],
      anchorsAlreadyInMeters: widget.anchorsAlreadyInMeters,
    );

    if (!mounted) return;
    _applyScenePreview(sceneGraph, updateState: true);
  }

  Future<void> _executeExport({bool triggerNativeAction = false}) async {
    setState(() => _isExporting = true);
    try {
      final bundle = await _service.exportRoomArchive(
        propertyId: widget.propertyId,
        roomName: widget.roomName,
        viewportAnchors: widget.anchors,
        existingEnclosure: widget.existingEnclosure,
        ceilingHeightMeters: _ceilingHeightMeters,
        stagedFurniture: _includeFurniture ? widget.stagedFurniture : const [],
        format: _selectedFormat,
        anchorsAlreadyInMeters: widget.anchorsAlreadyInMeters,
      );

      if (_archiveRepo != null) {
        await _archiveRepo!.saveExportRecord(bundle.record);
      }

      if (triggerNativeAction) {
        if (bundle.record.usdzPath != null &&
            _selectedFormat == SpatialArchiveFormat.usdz) {
          await _service.previewUsdzQuickLook(bundle.record.usdzPath!);
        } else {
          final paths = <String>[
            if (bundle.record.glbPath != null) bundle.record.glbPath!,
            if (bundle.record.usdzPath != null) bundle.record.usdzPath!,
          ];
          await _service.shareSpatialArchive(
            filePaths: paths,
            title: '${widget.roomName} Interactive 3D Archive',
          );
        }
      }

      if (!mounted) return;
      setState(() {
        _isExporting = false;
        _savedRecord = bundle.record;
      });

      AppFeedback.showSuccess(
        context,
        triggerNativeAction
            ? 'Dispatched interactive 3D archive (${bundle.record.vertexCount} vertices).'
            : 'Saved 3D archive to local workspace (${_formatBytes(bundle.record.totalBytes)}).',
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isExporting = false);
      AppFeedback.showError(context, 'Archive export failed: $e');
    }
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    return '${(bytes / 1024.0).toStringAsFixed(1)} KB';
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final preview = _previewBundle;

    return SingleChildScrollView(
      physics: const ClampingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Container(
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                color: colors.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: colors.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.archive_outlined,
                  size: 22,
                  color: colors.onPrimaryContainer,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Export Interactive 3D Archive',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: colors.onSurface,
                      ),
                    ),
                    Text(
                      '${widget.roomName} | glTF 2.0 & Apple Quick Look USDZ',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Format Selector
          Text(
            'Archive Output Format',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: colors.onSurface,
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _buildFormatChip(
                colors,
                format: SpatialArchiveFormat.glb,
                label: 'glTF 2.0 (.glb)',
                icon: Icons.view_in_ar_outlined,
              ),
              _buildFormatChip(
                colors,
                format: SpatialArchiveFormat.usdz,
                label: 'Quick Look (.usdz)',
                icon: Icons.apple,
              ),
              _buildFormatChip(
                colors,
                format: SpatialArchiveFormat.bundle,
                label: '3D Bundle (Both)',
                icon: Icons.folder_zip_outlined,
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Ceiling Height & Furniture Controls
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: colors.surfaceContainer,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colors.outlineVariant),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(Icons.height, size: 16, color: colors.primary),
                    const SizedBox(width: 6),
                    Text(
                      'Extrusion Height: ${_ceilingHeightMeters.toStringAsFixed(1)}m',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: colors.onSurface,
                      ),
                    ),
                    Expanded(
                      child: Slider(
                        value: _ceilingHeightMeters,
                        min: 2.4,
                        max: 4.2,
                        divisions: 9,
                        onChanged: (val) {
                          setState(() => _ceilingHeightMeters = val);
                          _rebuildPreview();
                        },
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Icon(
                      Icons.chair_outlined,
                      size: 16,
                      color: colors.secondary,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Include Staged 3D Furniture (${widget.stagedFurniture.length} assets)',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: colors.onSurface,
                        ),
                      ),
                    ),
                    Switch.adaptive(
                      value: _includeFurniture,
                      onChanged: widget.stagedFurniture.isEmpty
                          ? null
                          : (val) {
                              setState(() => _includeFurniture = val);
                              _rebuildPreview();
                            },
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Diagnostics Summary Card
          if (preview != null) ...[
            _buildDiagnosticsCard(colors, preview),
            const SizedBox(height: 10),
          ],

          // Toggleable Schema Inspector
          if (preview != null) ...[
            InkWell(
              onTap: () => setState(() {
                _showSchemaInspector = !_showSchemaInspector;
              }),
              borderRadius: BorderRadius.circular(10),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Icon(
                      Icons.account_tree_outlined,
                      size: 16,
                      color: colors.primary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _showSchemaInspector
                          ? 'Hide Scene Node Hierarchy & Schema'
                          : 'Inspect glTF Node Hierarchy & USDA Schema',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: colors.primary,
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      _showSchemaInspector
                          ? Icons.expand_less
                          : Icons.expand_more,
                      size: 18,
                      color: colors.primary,
                    ),
                  ],
                ),
              ),
            ),
            if (_showSchemaInspector) _buildSchemaPreviewBox(colors, preview),
            const SizedBox(height: 10),
          ],

          // Confirmation Banner when saved
          if (_savedRecord != null) ...[
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: colors.primaryContainer,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: colors.primary),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Archive Written & Verified',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: colors.onPrimaryContainer,
                    ),
                  ),
                  if (_savedRecord!.glbPath != null)
                    Text(
                      'GLB: ${_savedRecord!.glbPath}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 10,
                        color: colors.onPrimaryContainer,
                      ),
                    ),
                  if (_savedRecord!.usdzPath != null)
                    Text(
                      'USDZ: ${_savedRecord!.usdzPath}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 10,
                        color: colors.onPrimaryContainer,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 10),
          ],

          // Action CTAs
          ElevatedButton.icon(
            onPressed: _isExporting
                ? null
                : () => _executeExport(triggerNativeAction: false),
            icon: _isExporting
                ? SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        colors.onPrimary,
                      ),
                    ),
                  )
                : const Icon(Icons.save_alt_outlined, size: 18),
            label: Text(
              _isExporting
                  ? 'Serializing Binary 3D Mesh...'
                  : 'Export & Save 3D Archive',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _isExporting
                      ? null
                      : () => _executeExport(triggerNativeAction: true),
                  icon: const Icon(Icons.ios_share_outlined, size: 16),
                  label: Text(
                    _selectedFormat == SpatialArchiveFormat.usdz
                        ? 'Quick Look'
                        : 'Share Archive',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: preview == null
                      ? null
                      : () async {
                          await Clipboard.setData(
                            ClipboardData(
                              text: preview.sceneGraph.toHierarchySummaryJson(),
                            ),
                          );
                          if (context.mounted) {
                            AppFeedback.showInfo(
                              context,
                              'Copied 3D glTF hierarchy manifest to clipboard.',
                            );
                          }
                        },
                  icon: const Icon(Icons.copy_all_outlined, size: 16),
                  label: const Text(
                    'Copy Manifest',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFormatChip(
    ColorScheme colors, {
    required SpatialArchiveFormat format,
    required String label,
    required IconData icon,
  }) {
    final isSelected = _selectedFormat == format;
    return ChoiceChip(
      avatar: Icon(
        icon,
        size: 15,
        color: isSelected ? colors.onPrimaryContainer : colors.onSurfaceVariant,
      ),
      label: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: isSelected ? colors.onPrimaryContainer : colors.onSurface,
        ),
      ),
      selected: isSelected,
      selectedColor: colors.primaryContainer,
      onSelected: (selected) {
        if (selected) {
          setState(() => _selectedFormat = format);
          _rebuildPreview();
        }
      },
    );
  }

  Widget _buildDiagnosticsCard(
    ColorScheme colors,
    SpatialArchiveExportBundle preview,
  ) {
    final g = preview.sceneGraph;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildDiagMetric(colors, 'Nodes', '${g.totalNodeCount}'),
              _buildDiagMetric(colors, 'Vertices', '${g.totalVertexCount}'),
              _buildDiagMetric(colors, 'Triangles', '${g.totalTriangleCount}'),
              _buildDiagMetric(
                colors,
                'Size',
                _formatBytes(preview.record.totalBytes),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: [
              if (_glbInspection != null && _glbInspection!.isValidGlb)
                _buildCompliancePill(
                  colors,
                  'glTF 2.0 Binary Verified',
                  Icons.verified_outlined,
                ),
              if (_usdzInspection != null &&
                  _usdzInspection!.is64ByteAligned &&
                  _usdzInspection!.isUncompressedStore)
                _buildCompliancePill(
                  colors,
                  'USDZ Quick Look 64B Aligned',
                  Icons.check_circle_outline,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDiagMetric(ColorScheme colors, String label, String value) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 10, color: colors.onSurfaceVariant),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: colors.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompliancePill(ColorScheme colors, String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: colors.secondaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: colors.onSecondaryContainer),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: colors.onSecondaryContainer,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSchemaPreviewBox(
    ColorScheme colors,
    SpatialArchiveExportBundle preview,
  ) {
    final text = _inspectUsdaTab
        ? (_usdzInspection?.usdaContent ??
              UsdzArchiveSerializer().generateUsda(preview.sceneGraph))
        : preview.sceneGraph.toHierarchySummaryJson();

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              ChoiceChip(
                label: const Text(
                  'glTF Node Tree',
                  style: TextStyle(fontSize: 10),
                ),
                selected: !_inspectUsdaTab,
                onSelected: (_) => setState(() => _inspectUsdaTab = false),
              ),
              const SizedBox(width: 6),
              ChoiceChip(
                label: const Text(
                  'USDA 1.0 Primitives',
                  style: TextStyle(fontSize: 10),
                ),
                selected: _inspectUsdaTab,
                onSelected: (_) => setState(() => _inspectUsdaTab = true),
              ),
            ],
          ),
          const SizedBox(height: 6),
          SizedBox(
            height: 140,
            child: SingleChildScrollView(
              child: Text(
                text,
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 10,
                  color: colors.onSurfaceVariant,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
