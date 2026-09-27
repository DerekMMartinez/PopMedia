class Report{
  final int issue_id;
  final String type;
  final String reason;
  final String associated_id;
  final String reporter;
  final DateTime created_at;
  final bool resolved;

  Report({required this.issue_id, required this.type, required this.reason, required this.associated_id, required this.reporter, required this.created_at, required this.resolved});

  factory Report.fromJson(Map<String, dynamic> dict) {
    return Report(
      issue_id: dict['issue_id'],
      type: dict['type'],
      reason: dict['reason'],
      associated_id: dict['associated_id'],
      reporter: dict['reporter'],
      created_at: DateTime.parse(dict['created_at']),
      resolved: dict['resolved'] as bool,
    );
  }
}