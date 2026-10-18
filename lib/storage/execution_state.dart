import 'dart:convert';

/// Serializable local execution checkpoint. No authentication data is stored.
class ExecutionCheckpoint {
  ExecutionCheckpoint({
    this.selectedTaskId = 'indicator',
    this.darkMode = false,
    Map<String, TaskCheckpoint>? tasks,
  }) : tasks = tasks ?? {};

  String selectedTaskId;
  bool darkMode;
  final Map<String, TaskCheckpoint> tasks;

  TaskCheckpoint forTask(String id) =>
      tasks.putIfAbsent(id, () => TaskCheckpoint());

  Map<String, Object?> toJson() => {
    'schema': 1,
    'selectedTaskId': selectedTaskId,
    'darkMode': darkMode,
    'tasks': tasks.map((id, task) => MapEntry(id, task.toJson())),
  };

  String encode() => jsonEncode(toJson());

  factory ExecutionCheckpoint.decode(String value) {
    final raw = jsonDecode(value);
    if (raw is! Map<String, dynamic> || raw['schema'] != 1) {
      throw const FormatException('Unsupported execution checkpoint');
    }
    final storedTasks = raw['tasks'];
    if (storedTasks is! Map<String, dynamic>) {
      throw const FormatException('Invalid task checkpoint map');
    }
    return ExecutionCheckpoint(
      selectedTaskId: raw['selectedTaskId'] is String
          ? raw['selectedTaskId'] as String
          : 'indicator',
      darkMode: raw['darkMode'] == true,
      tasks: storedTasks.map((id, task) {
        if (task is! Map<String, dynamic>) {
          throw const FormatException('Invalid task checkpoint');
        }
        return MapEntry(id, TaskCheckpoint.fromJson(task));
      }),
    );
  }
}

class TaskCheckpoint {
  TaskCheckpoint({
    this.actionIndex = 0,
    this.verifiedMilestones = 0,
    this.awaitingVerification = false,
    this.note = '',
    this.blocker = '',
    this.detailLevel = 1,
    this.lastTouched,
  });

  int actionIndex;
  int verifiedMilestones;
  bool awaitingVerification;
  String note;
  String blocker;
  int detailLevel;
  DateTime? lastTouched;

  Map<String, Object?> toJson() => {
    'actionIndex': actionIndex,
    'verifiedMilestones': verifiedMilestones,
    'awaitingVerification': awaitingVerification,
    'note': note,
    'blocker': blocker,
    'detailLevel': detailLevel,
    'lastTouched': lastTouched?.toUtc().toIso8601String(),
  };

  factory TaskCheckpoint.fromJson(Map<String, dynamic> json) => TaskCheckpoint(
    actionIndex: json['actionIndex'] is int ? json['actionIndex'] as int : 0,
    verifiedMilestones: json['verifiedMilestones'] is int
        ? json['verifiedMilestones'] as int
        : 0,
    awaitingVerification: json['awaitingVerification'] == true,
    note: json['note'] is String ? json['note'] as String : '',
    blocker: json['blocker'] is String ? json['blocker'] as String : '',
    detailLevel: json['detailLevel'] is int ? json['detailLevel'] as int : 1,
    lastTouched: json['lastTouched'] is String
        ? DateTime.tryParse(json['lastTouched'] as String)
        : null,
  );
}
