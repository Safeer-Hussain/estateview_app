class TourBookingModel {
  final String id;
  final String propertyId;
  final String propertyTitle;
  final String date;
  final String timeSlot;
  final String
  tourType; // 'In-Person VIP Tour' or 'Live 4K Spatial Walkthrough'
  final String contactName;
  final String contactEmail;
  final String contactPhone;
  final String notes;
  final String status; // 'CONFIRMED', 'PENDING', 'COMPLETED'
  final int createdAt;

  const TourBookingModel({
    required this.id,
    required this.propertyId,
    required this.propertyTitle,
    required this.date,
    required this.timeSlot,
    required this.tourType,
    required this.contactName,
    required this.contactEmail,
    required this.contactPhone,
    required this.notes,
    required this.status,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'property_id': propertyId,
      'property_title': propertyTitle,
      'date': date,
      'time_slot': timeSlot,
      'tour_type': tourType,
      'contact_name': contactName,
      'contact_email': contactEmail,
      'contact_phone': contactPhone,
      'notes': notes,
      'status': status,
      'created_at': createdAt,
    };
  }

  factory TourBookingModel.fromMap(Map<String, dynamic> map) {
    return TourBookingModel(
      id: map['id'] as String,
      propertyId: map['property_id'] as String,
      propertyTitle: map['property_title'] as String,
      date: map['date'] as String,
      timeSlot: map['time_slot'] as String,
      tourType: map['tour_type'] as String,
      contactName: map['contact_name'] as String,
      contactEmail: map['contact_email'] as String,
      contactPhone: map['contact_phone'] as String,
      notes: map['notes'] as String,
      status: map['status'] as String,
      createdAt: map['created_at'] as int,
    );
  }
}
