import 'package:flutter/material.dart';

import '../../../core/di/injection.dart';
import '../../../core/utils/app_feedback.dart';
import '../../../data/models/property_model.dart';
import '../../../data/models/tour_booking_model.dart';
import '../../../data/repositories/tour_repository.dart';

class ScheduleViewingModal extends StatefulWidget {
  final PropertyModel property;

  const ScheduleViewingModal({super.key, required this.property});

  static Future<void> show(BuildContext context, PropertyModel property) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ScheduleViewingModal(property: property),
    );
  }

  @override
  State<ScheduleViewingModal> createState() => _ScheduleViewingModalState();
}

class _ScheduleViewingModalState extends State<ScheduleViewingModal> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController(text: 'Safeer Hussain');
  final _emailController = TextEditingController(text: 'safeer@estateview.io');
  final _phoneController = TextEditingController(text: '+92 300 8472911');
  final _notesController = TextEditingController();

  String _tourType = 'In-Person VIP Tour';
  String _timeSlot = '11:00 AM - 12:00 PM';
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 2));
  bool _isSubmitting = false;

  final List<String> _timeSlots = [
    '09:00 AM - 10:00 AM',
    '11:00 AM - 12:00 PM',
    '02:00 PM - 03:00 PM',
    '04:00 PM - 05:00 PM',
    '06:00 PM - 07:00 PM',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submitBooking() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final dateStr =
          '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}';

      final booking = TourBookingModel(
        id: 'tour-${DateTime.now().millisecondsSinceEpoch}',
        propertyId: widget.property.id,
        propertyTitle: widget.property.title,
        date: dateStr,
        timeSlot: _timeSlot,
        tourType: _tourType,
        contactName: _nameController.text.trim(),
        contactEmail: _emailController.text.trim(),
        contactPhone: _phoneController.text.trim(),
        notes: _notesController.text.trim(),
        status: 'CONFIRMED',
        createdAt: DateTime.now().millisecondsSinceEpoch,
      );

      final tourRepo = sl<TourRepository>();
      await tourRepo.bookTour(booking);

      if (mounted) {
        Navigator.of(context).pop();
        AppFeedback.showSuccess(
          context,
          'Private viewing scheduled for $dateStr ($_timeSlot). Advisor assigned: ${widget.property.advisorName}.',
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        AppFeedback.showError(context, 'Failed to schedule viewing: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

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
          child: Form(
            key: _formKey,
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
                        Icons.calendar_month_outlined,
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
                            'Schedule Private Viewing',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: colors.onSurface,
                            ),
                          ),
                          Text(
                            widget.property.title,
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

                // Tour Type Selector (In-Person vs 4K Spatial Walkthrough)
                Text(
                  'Viewing Experience Type',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: colors.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: ChoiceChip(
                        label: const Center(child: Text('In-Person VIP Tour')),
                        selected: _tourType == 'In-Person VIP Tour',
                        selectedColor: colors.primaryContainer,
                        labelStyle: TextStyle(
                          color: _tourType == 'In-Person VIP Tour'
                              ? colors.onPrimaryContainer
                              : colors.onSurface,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                        onSelected: (selected) {
                          if (selected) {
                            setState(() => _tourType = 'In-Person VIP Tour');
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ChoiceChip(
                        label: const Center(child: Text('Live 4K Walkthrough')),
                        selected: _tourType == 'Live 4K Spatial Walkthrough',
                        selectedColor: colors.primaryContainer,
                        labelStyle: TextStyle(
                          color: _tourType == 'Live 4K Spatial Walkthrough'
                              ? colors.onPrimaryContainer
                              : colors.onSurface,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                        onSelected: (selected) {
                          if (selected) {
                            setState(
                              () => _tourType = 'Live 4K Spatial Walkthrough',
                            );
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Date Picker Tile
                Text(
                  'Select Viewing Date',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: colors.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _selectedDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 60)),
                    );
                    if (picked != null) {
                      setState(() => _selectedDate = picked);
                    }
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: colors.surfaceContainer,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: colors.outlineVariant),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: colors.onSurface,
                          ),
                        ),
                        Icon(
                          Icons.edit_calendar,
                          size: 18,
                          color: colors.primary,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Time Slot Dropdown
                Text(
                  'Preferred Time Slot',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: colors.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _timeSlot,
                  items: _timeSlots
                      .map(
                        (slot) =>
                            DropdownMenuItem(value: slot, child: Text(slot)),
                      )
                      .toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _timeSlot = val);
                  },
                  decoration: const InputDecoration(
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Contact Name Input
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Full Name',
                    prefixIcon: Icon(Icons.person_outline, size: 20),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Please provide your full legal name.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),

                // Contact Email & Phone
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'Email Address',
                          prefixIcon: Icon(Icons.email_outlined, size: 20),
                        ),
                        validator: (val) {
                          if (val == null || !val.contains('@')) {
                            return 'Valid email required.';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          labelText: 'Phone Number',
                          prefixIcon: Icon(Icons.phone_outlined, size: 20),
                        ),
                        validator: (val) {
                          if (val == null || val.trim().length < 8) {
                            return 'Valid phone required.';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Specific Inspection Notes
                TextFormField(
                  controller: _notesController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Architectural Inspection Notes / Inquiries',
                    hintText: 'e.g., Focus on solar array capacity, HVAC inspection...',
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 20),

                // Confirm Button
                ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitBooking,
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text(
                          'Confirm Viewing Reservation',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
