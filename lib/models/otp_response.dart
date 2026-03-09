/// OTP Response Model
/// Represents OTP-related API responses
class OtpResponse {
  final String? otpId;
  final String phoneNumber;
  final String? otp;
  final int? attempts;
  final int? maxAttempts;
  final DateTime? expiryTime;
  final bool isConfirmed;
  final bool success;
  final String? message;

  OtpResponse({
    this.otpId,
    required this.phoneNumber,
    this.otp,
    this.attempts = 0,
    this.maxAttempts = 5,
    this.expiryTime,
    this.isConfirmed = false,
    this.success = false,
    this.message,
  });

  /// Factory constructor for creating OtpResponse from JSON
  factory OtpResponse.fromJson(Map<String, dynamic> json) {
    return OtpResponse(
      otpId: json['otpId'] ?? json['id'],
      phoneNumber: json['phoneNumber'] ?? json['phone'] ?? '',
      otp: json['otp'] ?? json['otpCode'],
      attempts: json['attempts'] ?? json['attempt_count'] ?? 0,
      maxAttempts: json['maxAttempts'] ?? json['max_attempts'] ?? 5,
      expiryTime: json['expiryTime'] != null
          ? DateTime.tryParse(json['expiryTime'])
          : null,
      isConfirmed: json['isConfirmed'] == true || json['is_confirmed'] == 1,
      success: json['success'] == true || json['isSuccess'] == true,
      message: json['message'] ?? json['responseMessage'],
    );
  }

  /// Convert OtpResponse to JSON
  Map<String, dynamic> toJson() {
    return {
      'otpId': otpId,
      'phoneNumber': phoneNumber,
      'otp': otp,
      'attempts': attempts,
      'maxAttempts': maxAttempts,
      'expiryTime': expiryTime?.toIso8601String(),
      'isConfirmed': isConfirmed,
      'success': success,
      'message': message,
    };
  }

  @override
  String toString() =>
      'OtpResponse(phone: $phoneNumber, attempts: $attempts/$maxAttempts, confirmed: $isConfirmed)';
}
