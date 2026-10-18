/// Demonstration-only tasks. No user task data or cloud APIs are included.
class DemoTask {
  const DemoTask({
    required this.id,
    required this.title,
    required this.description,
    required this.project,
    required this.action,
    required this.followUpAction,
    required this.microSteps,
    required this.completionCriteria,
    required this.milestoneProgress,
  });

  final String id;
  final String title;
  final String description;
  final String project;
  final String action;
  final String followUpAction;
  final List<String> microSteps;
  final List<String> completionCriteria;
  final String milestoneProgress;
}

const demoTasks = <DemoTask>[
  DemoTask(
    id: 'indicator',
    title: 'Build a trading indicator',
    description: 'Resolve a compiler error before continuing.',
    project: 'Trading indicator',
    action: 'Open the editor and locate the error list.',
    followUpAction: 'Record the first error and its line number.',
    microSteps: [
      'Open your indicator in the editor',
      'Locate the compiler error list',
      'Record the first error message',
    ],
    completionCriteria: [
      'The editor is open',
      'The error list is visible',
      'The next issue is identified',
    ],
    milestoneProgress: '2 of 5 outcomes verified',
  ),
  DemoTask(
    id: 'application',
    title: 'Send an application form',
    description: 'Gather the required paperwork without distraction.',
    project: 'Personal admin',
    action: 'Find the required ID document.',
    followUpAction: 'Review the form for missing required fields.',
    microSteps: [
      'Open the application requirements',
      'Find your required ID document',
      'Confirm that the document is valid',
    ],
    completionCriteria: [
      'Document requirements checked',
      'Required ID located',
      'Ready to review the form',
    ],
    milestoneProgress: '1 of 3 outcomes verified',
  ),
  DemoTask(
    id: 'lightbulb',
    title: 'Replace a household light bulb',
    description: 'Finish one postponed household task.',
    project: 'Household',
    action: 'Check the bulb type and turn off the power.',
    followUpAction: 'Replace the bulb once it is cool.',
    microSteps: [
      'Turn off the fixture',
      'Let the old bulb cool',
      'Check the replacement bulb type',
    ],
    completionCriteria: [
      'Power off',
      'Bulb type confirmed',
      'Safe to replace',
    ],
    milestoneProgress: '0 of 1 outcomes verified',
  ),
];
