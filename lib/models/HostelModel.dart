import 'package:cloud_firestore/cloud_firestore.dart';

// lib/models/HostelModel.dart
// ─────────────────────────────────────────────────────────────────────────────
// Represents a hostel listing created by an owner.
// Stored in Firestore: /hostels/{hostelId}
// ─────────────────────────────────────────────────────────────────────────────

class HostelModel {
  final String id;              // Firestore document ID
  final String ownerId;         // UID of the owner who created this listing
  final String ownerName;       // Denormalized for display (avoids extra query)
  final String name;            // Hostel display name
  final String description;
  final String city;
  final String address;
  final double latitude;        // For Google Maps pin
  final double longitude;
  final double rentPerMonth;    // in PKR
  final String roomType;        // 'Single' | 'Double' | etc.
  final String genderPreference; // 'Male Only' | 'Female Only' | 'Co-ed'
  final List<String> facilities; // e.g. ['WiFi', 'Mess', 'Security']
  final List<String> images;    // Firebase Storage download URLs
  final bool isAvailable;       // Can students book right now?
  final String status;          // 'pending' | 'approved' | 'rejected'
  final double averageRating;    // Computed from reviews (updated on new review)
  final int totalReviews;
  final int totalRooms;
  final int availableRooms;
  // ── Ranking counters (updated atomically when bookings/complaints change) ──
  final int totalBookings;        // FR-9.1: booking confirmation rate denominator
  final int confirmedBookings;    // FR-9.1: booking confirmation rate numerator
  final int totalComplaints;      // FR-9.1: complaint resolution rate denominator
  final int resolvedComplaints;   // FR-9.1: complaint resolution rate numerator
  final int totalResolutionTimeHours; // FR-9: for complaint resolution speed
  final DateTime createdAt;
  final DateTime updatedAt;

  // Ephemeral property computed locally by ML model for display
  double? smartScore;

  // New getters for ML Ranking features
  double get complaintResolutionRate => totalComplaints == 0 ? 1.0 : resolvedComplaints / totalComplaints;
  double get bookingConfirmationRate => totalBookings == 0 ? 0.0 : confirmedBookings / totalBookings;

  HostelModel({
    required this.id,
    required this.ownerId,
    required this.ownerName,
    required this.name,
    required this.description,
    required this.city,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.rentPerMonth,
    required this.roomType,
    required this.genderPreference,
    required this.facilities,
    required this.images,
    this.isAvailable = true,
    this.status = 'pending',
    this.averageRating = 0.0,
    this.totalReviews = 0,
    this.totalRooms = 1,
    this.availableRooms = 1,
    this.totalBookings = 0,
    this.confirmedBookings = 0,
    this.totalComplaints = 0,
    this.resolvedComplaints = 0,
    this.totalResolutionTimeHours = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  // Helper method for safe DateTime parsing
  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    return DateTime.now();
  }

  // Helper method for safe double parsing
  static double _parseDouble(dynamic value, [double defaultValue = 0.0]) {
    if (value == null) return defaultValue;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? defaultValue;
    return defaultValue;
  }

  // Helper method for safe int parsing
  static int _parseInt(dynamic value, [int defaultValue = 0]) {
    if (value == null) return defaultValue;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? defaultValue;
    return defaultValue;
  }

  // ── fromMap: used when reading from Firestore ──────────────────────────────
  factory HostelModel.fromMap(Map<String, dynamic> map, String id) {
    return HostelModel(
      id: id,
      ownerId: map['ownerId']?.toString() ?? '',
      ownerName: map['ownerName']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      description: map['description']?.toString() ?? '',
      city: map['city']?.toString() ?? '',
      address: map['address']?.toString() ?? '',
      latitude: _parseDouble(map['latitude']),
      longitude: _parseDouble(map['longitude']),
      rentPerMonth: _parseDouble(map['rentPerMonth']),
      roomType: map['roomType']?.toString() ?? 'Single',
      genderPreference: map['genderPreference']?.toString() ?? 'Co-ed',
      facilities: List<String>.from(map['facilities'] ?? []),
      images: List<String>.from(map['images'] ?? []),
      isAvailable: map['isAvailable'] == true,
      status: map['status']?.toString() ?? 'pending',
      averageRating: _parseDouble(map['averageRating']),
      totalReviews: _parseInt(map['totalReviews']),
      totalRooms: _parseInt(map['totalRooms'], 1),
      availableRooms: _parseInt(map['availableRooms'], 1),
      totalBookings: _parseInt(map['totalBookings']),
      confirmedBookings: _parseInt(map['confirmedBookings']),
      totalComplaints: _parseInt(map['totalComplaints']),
      resolvedComplaints: _parseInt(map['resolvedComplaints']),
      totalResolutionTimeHours: _parseInt(map['totalResolutionTimeHours']),
      createdAt: _parseDateTime(map['createdAt']),
      updatedAt: _parseDateTime(map['updatedAt']),
    );
  }

  // ── toMap: used when writing to Firestore ─────────────────────────────────
  Map<String, dynamic> toMap() {
    return {
      'ownerId': ownerId,
      'ownerName': ownerName,
      'name': name,
      'description': description,
      'city': city,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'rentPerMonth': rentPerMonth,
      'roomType': roomType,
      'genderPreference': genderPreference,
      'facilities': facilities,
      'images': images,
      'isAvailable': isAvailable,
      'status': status,
      'averageRating': averageRating,
      'totalReviews': totalReviews,
      'totalRooms': totalRooms,
      'availableRooms': availableRooms,
      'totalBookings': totalBookings,
      'confirmedBookings': confirmedBookings,
      'totalComplaints': totalComplaints,
      'resolvedComplaints': resolvedComplaints,
      'totalResolutionTimeHours': totalResolutionTimeHours,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  // ── copyWith: returns a modified copy (useful in GetX controllers) ─────────
  HostelModel copyWith({
    String? name,
    String? description,
    String? city,
    String? address,
    double? latitude,
    double? longitude,
    double? rentPerMonth,
    String? roomType,
    String? genderPreference,
    List<String>? facilities,
    List<String>? images,
    bool? isAvailable,
    String? status,
    double? averageRating,
    int? totalReviews,
    int? availableRooms,
    int? totalBookings,
    int? confirmedBookings,
    int? totalComplaints,
    int? resolvedComplaints,
    int? totalResolutionTimeHours,
  }) {
    return HostelModel(
      id: id,
      ownerId: ownerId,
      ownerName: ownerName,
      name: name ?? this.name,
      description: description ?? this.description,
      city: city ?? this.city,
      address: address ?? this.address,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      rentPerMonth: rentPerMonth ?? this.rentPerMonth,
      roomType: roomType ?? this.roomType,
      genderPreference: genderPreference ?? this.genderPreference,
      facilities: facilities ?? this.facilities,
      images: images ?? this.images,
      isAvailable: isAvailable ?? this.isAvailable,
      status: status ?? this.status,
      averageRating: averageRating ?? this.averageRating,
      totalReviews: totalReviews ?? this.totalReviews,
      totalRooms: totalRooms,
      availableRooms: availableRooms ?? this.availableRooms,
      totalBookings: totalBookings ?? this.totalBookings,
      confirmedBookings: confirmedBookings ?? this.confirmedBookings,
      totalComplaints: totalComplaints ?? this.totalComplaints,
      resolvedComplaints: resolvedComplaints ?? this.resolvedComplaints,
      totalResolutionTimeHours: totalResolutionTimeHours ?? this.totalResolutionTimeHours,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}




