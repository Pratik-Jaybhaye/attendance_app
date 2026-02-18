/// Period Model
/// Represents a class period for which attendance can be taken
class Period {
  final String id;
  final String name;

  /// Optional remarks for this period's attendance
  /// Example: "Missed period due to assembly", "Makeup class"
  String remarks;

  Period({required this.id, required this.name, this.remarks = ''});

  /// Factory constructor for creating Period from JSON
  factory Period.fromJson(Map<String, dynamic> json) {
    return Period(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      remarks: json['remarks'] ?? '',
    );
  }

  /// Convert Period to JSON
  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name, 'remarks': remarks};
  }
}
