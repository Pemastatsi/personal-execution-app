import 'dart:math';

String newLocalId() {
  final random = Random.secure();
  final suffix = List<int>.generate(8, (_) => random.nextInt(256))
      .map((value) => value.toRadixString(16).padLeft(2, '0'))
      .join();
  return '${DateTime.now().microsecondsSinceEpoch}-$suffix';
}

class WorkProject {
  const WorkProject({
    required this.id,
    required this.name,
    required this.createdAt,
  });

  final String id;
  final String name;
  final DateTime createdAt;

  factory WorkProject.fromRow(Map<String, Object?> row) => WorkProject(
        id: row['id']! as String,
        name: row['name']! as String,
        createdAt: DateTime.parse(row['created_at']! as String),
      );
}

class WorkItem {
  const WorkItem({
    required this.id,
    required this.title,
    required this.description,
    required this.nextAction,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.projectId,
  });

  final String id;
  final String? projectId;
  final String title;
  final String description;
  final String nextAction;
  final String status; // active or completed
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get completed => status == 'completed';

  factory WorkItem.fromRow(Map<String, Object?> row) => WorkItem(
        id: row['id']! as String,
        projectId: row['project_id'] as String?,
        title: row['title']! as String,
        description: row['description']! as String,
        nextAction: row['next_action']! as String,
        status: row['status']! as String,
        createdAt: DateTime.parse(row['created_at']! as String),
        updatedAt: DateTime.parse(row['updated_at']! as String),
      );
}

class WorkMilestone {
  const WorkMilestone({
    required this.id,
    required this.taskId,
    required this.title,
    required this.criteria,
    required this.evidence,
    required this.position,
    this.verifiedAt,
  });

  final String id;
  final String taskId;
  final String title;
  final String criteria;
  final String evidence;
  final int position;
  final DateTime? verifiedAt;

  bool get verified => verifiedAt != null;

  factory WorkMilestone.fromRow(Map<String, Object?> row) => WorkMilestone(
        id: row['id']! as String,
        taskId: row['task_id']! as String,
        title: row['title']! as String,
        criteria: row['criteria']! as String,
        evidence: row['evidence']! as String,
        position: row['position']! as int,
        verifiedAt: row['verified_at'] == null
            ? null
            : DateTime.parse(row['verified_at']! as String),
      );
}
