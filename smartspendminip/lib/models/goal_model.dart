class GoalModel {
  final String id;
  final String title;
  final double targetAmount;
  final double currentAmount;
  final DateTime deadline;
  final String icon; // Store an icon name or emoji

  GoalModel({
    required this.id,
    required this.title,
    required this.targetAmount,
    required this.currentAmount,
    required this.deadline,
    required this.icon,
  });

  // Calculate progress percentage for UI
  double get progress => currentAmount / targetAmount;

  // Calculate remaining amount needed
  double get remainingAmount => targetAmount - currentAmount;
}