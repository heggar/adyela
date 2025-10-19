import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

import '../enums/specialty.dart';

part 'professional.g.dart';

/// Professional (healthcare provider) model
@JsonSerializable()
class Professional extends Equatable {
  final String id;
  final String userId;
  final String tenantId;
  final String firstName;
  final String lastName;
  final String email;
  final String? phoneNumber;
  final String? photoUrl;
  final Specialty specialty;
  final String? bio;
  final String? licenseNumber;
  final List<String>? certifications;
  final int yearsOfExperience;
  final double rating;
  final int reviewCount;
  final bool isVerified;
  final bool isAvailable;
  final Map<String, dynamic>? availability;
  final double? consultationFee;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const Professional({
    required this.id,
    required this.userId,
    required this.tenantId,
    required this.firstName,
    required this.lastName,
    required this.email,
    this.phoneNumber,
    this.photoUrl,
    required this.specialty,
    this.bio,
    this.licenseNumber,
    this.certifications,
    this.yearsOfExperience = 0,
    this.rating = 0.0,
    this.reviewCount = 0,
    this.isVerified = false,
    this.isAvailable = true,
    this.availability,
    this.consultationFee,
    required this.createdAt,
    this.updatedAt,
  });

  /// Get full name
  String get fullName => '$firstName $lastName';

  /// Get display name with title
  String get displayName => 'Dr. $fullName';

  /// Check if profile is complete
  bool get isProfileComplete {
    return phoneNumber != null &&
        bio != null &&
        licenseNumber != null &&
        consultationFee != null;
  }

  factory Professional.fromJson(Map<String, dynamic> json) =>
      _$ProfessionalFromJson(json);

  Map<String, dynamic> toJson() => _$ProfessionalToJson(this);

  @override
  List<Object?> get props => [
        id,
        userId,
        tenantId,
        firstName,
        lastName,
        email,
        phoneNumber,
        photoUrl,
        specialty,
        bio,
        licenseNumber,
        certifications,
        yearsOfExperience,
        rating,
        reviewCount,
        isVerified,
        isAvailable,
        availability,
        consultationFee,
        createdAt,
        updatedAt,
      ];

  Professional copyWith({
    String? id,
    String? userId,
    String? tenantId,
    String? firstName,
    String? lastName,
    String? email,
    String? phoneNumber,
    String? photoUrl,
    Specialty? specialty,
    String? bio,
    String? licenseNumber,
    List<String>? certifications,
    int? yearsOfExperience,
    double? rating,
    int? reviewCount,
    bool? isVerified,
    bool? isAvailable,
    Map<String, dynamic>? availability,
    double? consultationFee,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Professional(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      tenantId: tenantId ?? this.tenantId,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      photoUrl: photoUrl ?? this.photoUrl,
      specialty: specialty ?? this.specialty,
      bio: bio ?? this.bio,
      licenseNumber: licenseNumber ?? this.licenseNumber,
      certifications: certifications ?? this.certifications,
      yearsOfExperience: yearsOfExperience ?? this.yearsOfExperience,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      isVerified: isVerified ?? this.isVerified,
      isAvailable: isAvailable ?? this.isAvailable,
      availability: availability ?? this.availability,
      consultationFee: consultationFee ?? this.consultationFee,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
