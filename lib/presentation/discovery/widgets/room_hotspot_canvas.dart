import 'package:flutter/material.dart';

import '../../../data/models/floorplan_model.dart';

class RoomHotspotCanvas extends StatefulWidget {
  final FloorplanData floorplan;
  final ValueChanged<RoomHotspot>? onRoomSelected;

  const RoomHotspotCanvas({
    super.key,
    required this.floorplan,
    this.onRoomSelected,
  });

  @override
  State<RoomHotspotCanvas> createState() => _RoomHotspotCanvasState();
}

class _RoomHotspotCanvasState extends State<RoomHotspotCanvas> {
  RoomHotspot? _selectedRoom;

  @override
  void initState() {
    super.initState();
    if (widget.floorplan.rooms.isNotEmpty) {
      _selectedRoom = widget.floorplan.rooms.first;
    }
  }

  void _selectRoom(RoomHotspot room) {
    setState(() {
      _selectedRoom = room;
    });
    widget.onRoomSelected?.call(room);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      physics: const ClampingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Interactive Blueprint Vector Canvas
          AspectRatio(
            aspectRatio: 1.5,
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Stack(
                  children: [
                    // Vector Canvas
                    CustomPaint(
                      size: Size(constraints.maxWidth, constraints.maxHeight),
                      painter: _BlueprintPainter(
                        colorScheme: colors,
                        selectedRoom: _selectedRoom,
                      ),
                    ),

                    // Room Hotspot Touch Targets
                    ...widget.floorplan.rooms.map((room) {
                      final left =
                          room.relativePosition.dx * constraints.maxWidth - 20;
                      final top =
                          room.relativePosition.dy * constraints.maxHeight - 20;
                      final isSelected = _selectedRoom?.id == room.id;

                      return Positioned(
                        left: left,
                        top: top,
                        child: GestureDetector(
                          onTap: () => _selectRoom(room),
                          behavior: HitTestBehavior.opaque,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            width: isSelected ? 44 : 38,
                            height: isSelected ? 44 : 38,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isSelected
                                  ? colors.primary
                                  : colors.surfaceContainerHighest.withOpacity(
                                      0.9,
                                    ),
                              border: Border.all(
                                color: isSelected
                                    ? colors.onPrimary
                                    : colors.outline,
                                width: isSelected ? 2.5 : 1.2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color:
                                      (isSelected
                                              ? colors.primary
                                              : colors.shadow)
                                          .withOpacity(0.4),
                                  blurRadius: isSelected ? 12 : 4,
                                  spreadRadius: isSelected ? 2 : 0,
                                ),
                              ],
                            ),
                            child: Icon(
                              isSelected ? Icons.check : Icons.touch_app,
                              size: 18,
                              color: isSelected
                                  ? colors.onPrimary
                                  : colors.primary,
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                );
              },
            ),
          ),

          const SizedBox(height: 12),

          // Room Selection Chips Row
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              children: widget.floorplan.rooms.map((room) {
                final isSelected = _selectedRoom?.id == room.id;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(room.name),
                    selected: isSelected,
                    selectedColor: colors.primaryContainer,
                    labelStyle: TextStyle(
                      color: isSelected
                          ? colors.onPrimaryContainer
                          : colors.onSurface,
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w500,
                      fontSize: 12,
                    ),
                    onSelected: (selected) {
                      if (selected) _selectRoom(room);
                    },
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 12),

          // Selected Room Detail Card
          if (_selectedRoom != null)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: colors.surfaceContainer,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: colors.outlineVariant),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          _selectedRoom!.name,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: colors.onSurface,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: colors.primary.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${_selectedRoom!.widthFt.toInt()}ft x ${_selectedRoom!.lengthFt.toInt()}ft (${_selectedRoom!.areaSqFt.toInt()} sq.ft)',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: colors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.layers_outlined,
                        size: 14,
                        color: colors.secondary,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Flooring: ${_selectedRoom!.flooringType}',
                          style: TextStyle(
                            fontSize: 12,
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.wb_sunny_outlined,
                        size: 14,
                        color: colors.secondary,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Orientation: ${_selectedRoom!.sunOrientation}',
                          style: TextStyle(
                            fontSize: 12,
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _selectedRoom!.description,
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
    );
  }
}

class _BlueprintPainter extends CustomPainter {
  final ColorScheme colorScheme;
  final RoomHotspot? selectedRoom;

  _BlueprintPainter({required this.colorScheme, required this.selectedRoom});

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Background blueprint fill
    final bgPaint = Paint()
      ..color = colorScheme.surfaceContainerHighest.withOpacity(0.35)
      ..style = PaintingStyle.fill;
    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      const Radius.circular(16),
    );
    canvas.drawRRect(rrect, bgPaint);

    // 2. Architectural Blueprint Grid
    final gridPaint = Paint()
      ..color = colorScheme.outline.withOpacity(0.2)
      ..strokeWidth = 0.8;
    const step = 24.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // 3. Exterior architectural perimeter walls
    final wallPaint = Paint()
      ..color = colorScheme.onSurface.withOpacity(0.7)
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke;

    const inset = 24.0;
    final outerRect = Rect.fromLTWH(
      inset,
      inset,
      size.width - inset * 2,
      size.height - inset * 2,
    );
    canvas.drawRect(outerRect, wallPaint);

    // 4. Interior partition walls
    final partitionPaint = Paint()
      ..color = colorScheme.onSurface.withOpacity(0.5)
      ..strokeWidth = 1.8;

    final midX = size.width * 0.52;
    final midY = size.height * 0.52;

    // Vertical partition
    canvas.drawLine(
      Offset(midX, inset),
      Offset(midX, size.height - inset),
      partitionPaint,
    );
    // Horizontal partition
    canvas.drawLine(
      Offset(inset, midY),
      Offset(size.width - inset, midY),
      partitionPaint,
    );

    // Doorway opening gaps
    final doorGapPaint = Paint()
      ..color = colorScheme.surface
      ..strokeWidth = 4.0;
    canvas.drawLine(
      Offset(midX, midY - 24),
      Offset(midX, midY + 4),
      doorGapPaint,
    );
    canvas.drawLine(
      Offset(midX - 24, midY),
      Offset(midX + 4, midY),
      doorGapPaint,
    );

    // 5. Highlight zone for selected room
    if (selectedRoom != null) {
      final highlightPaint = Paint()
        ..color = colorScheme.primary.withOpacity(0.12)
        ..style = PaintingStyle.fill;

      Rect highlightRect;
      if (selectedRoom!.relativePosition.dx < 0.5 &&
          selectedRoom!.relativePosition.dy < 0.5) {
        highlightRect = Rect.fromLTWH(inset, inset, midX - inset, midY - inset);
      } else if (selectedRoom!.relativePosition.dx >= 0.5 &&
          selectedRoom!.relativePosition.dy < 0.5) {
        highlightRect = Rect.fromLTWH(
          midX,
          inset,
          size.width - inset - midX,
          midY - inset,
        );
      } else if (selectedRoom!.relativePosition.dx < 0.5 &&
          selectedRoom!.relativePosition.dy >= 0.5) {
        highlightRect = Rect.fromLTWH(
          inset,
          midY,
          midX - inset,
          size.height - inset - midY,
        );
      } else {
        highlightRect = Rect.fromLTWH(
          midX,
          midY,
          size.width - inset - midX,
          size.height - inset - midY,
        );
      }
      canvas.drawRect(highlightRect, highlightPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _BlueprintPainter oldDelegate) {
    return oldDelegate.colorScheme != colorScheme ||
        oldDelegate.selectedRoom?.id != selectedRoom?.id;
  }
}
