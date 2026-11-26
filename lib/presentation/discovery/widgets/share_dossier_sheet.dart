import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/utils/app_feedback.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../data/models/property_model.dart';
import '../../ar_scanner/widgets/spatial_archive_share_sheet.dart';

class ShareDossierSheet extends StatelessWidget {
  final PropertyModel property;
  final bool isPkr;

  const ShareDossierSheet({
    super.key,
    required this.property,
    required this.isPkr,
  });

  static void show(BuildContext context, PropertyModel property, bool isPkr) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => ShareDossierSheet(property: property, isPkr: isPkr),
    );
  }

  String _generateFormattedBrief() {
    final priceStr = CurrencyFormatter.format(
      usdAmount: property.priceUsd,
      pkrAmount: property.pricePkr,
      isPkr: isPkr,
    );
    final pricePerSqFt = property.areaSqFt > 0
        ? (property.priceUsd / property.areaSqFt).toStringAsFixed(1)
        : '0';

    return '''
=============================================
ESTATEVIEW ARCHITECTURAL DOSSIER
=============================================
Property: ${property.title}
Subtitle: ${property.subtitle}
Price: $priceStr (${property.listingType.toUpperCase()})
Location: ${property.address}, ${property.city}
Coordinates: ${property.latitude.toStringAsFixed(4)}, ${property.longitude.toStringAsFixed(4)}
Specs: ${property.bedrooms} Beds | ${property.bathrooms} Baths | ${property.areaSqFt.toInt()} Sq.Ft
Metric: \$$pricePerSqFt/sq.ft

Key Amenities:
${property.amenities.map((a) => '• $a').join('\n')}

Assigned Portfolio Partner:
${property.advisorName} (${property.advisorRole})
Direct Inquiries: ${property.advisorPhone}

Access Interactive Blueprint & AR Measurement:
https://estateview.internal/property/${property.id}
=============================================
''';
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final brief = _generateFormattedBrief();

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colors.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: colors.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.share_outlined,
                      color: colors.onPrimaryContainer,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Export Property Dossier',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: colors.onSurface,
                          ),
                        ),
                        Text(
                          property.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 12),

              // Preview Dossier Box
              Container(
                height: 180,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colors.surfaceContainer,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: colors.outlineVariant),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    brief,
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 11,
                      color: colors.onSurfaceVariant,
                      height: 1.4,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Action buttons
              ElevatedButton.icon(
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: brief));
                  if (context.mounted) {
                    Navigator.of(context).pop();
                    AppFeedback.showSuccess(
                      context,
                      'Formatted Architectural Dossier copied to clipboard.',
                    );
                  }
                },
                icon: const Icon(Icons.copy, size: 18),
                label: const Text(
                  'Copy Formatted Brief to Clipboard',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(height: 8),

              OutlinedButton.icon(
                onPressed: () {
                  Navigator.of(context).pop();
                  AppFeedback.showInfo(
                    context,
                    'Investment Summary Exported to Portfolio Documents.',
                  );
                },
                icon: const Icon(Icons.download_outlined, size: 18),
                label: const Text('Export Investment Summary (PDF/JSON)'),
              ),
              const SizedBox(height: 8),

              OutlinedButton.icon(
                onPressed: () {
                  final primaryRoom = property.floorplan.rooms.isNotEmpty
                      ? property.floorplan.rooms.first
                      : null;
                  final widthMeters = (primaryRoom?.widthFt ?? 20.0) * 0.3048;
                  final depthMeters = (primaryRoom?.lengthFt ?? 15.0) * 0.3048;
                  final meterAnchors = [
                    const Offset(0.0, 0.0),
                    Offset(widthMeters, 0.0),
                    Offset(widthMeters, depthMeters),
                    Offset(0.0, depthMeters),
                  ];
                  Navigator.of(context).pop();
                  SpatialArchiveShareSheet.show(
                    context,
                    propertyId: property.id,
                    roomName: '${property.title} Blueprint',
                    anchors: meterAnchors,
                    anchorsAlreadyInMeters: true,
                  );
                },
                icon: const Icon(Icons.archive_outlined, size: 18),
                label: const Text('Export 3D Blueprint (.GLB / .USDZ)'),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}
