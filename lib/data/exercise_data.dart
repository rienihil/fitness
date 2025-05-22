class Exercise {
  final String name;
  final String muscle;
  final String equipment;
  final String videoAsset;
  final String description;

  Exercise({
    required this.name,
    required this.muscle,
    required this.equipment,
    required this.videoAsset,
    required this.description,
  });
}

final List<Exercise> exercises = [
  Exercise(
    name: 'Barbell Squat',
    muscle: 'Legs',
    equipment: 'Barbell',
    videoAsset: 'assets/videos/barbell_squat.mp4',
    description: 'Stand with feet shoulder-width apart, lower your hips until thighs are parallel to the floor, then return to standing.',
  ),
  Exercise(
    name: 'Bench Press',
    muscle: 'Chest',
    equipment: 'Barbell',
    videoAsset: 'assets/videos/bench_press.mp4',
    description: 'Lie on a bench, lower the bar to your chest, and push it back up until your arms are fully extended.',
  ),
  Exercise(
    name: 'Barbell Bicep Curl',
    muscle: 'Arms',
    equipment: 'Dumbbell',
    videoAsset: 'assets/videos/bicep_curl.mp4',
    description: 'Hold a barbell with palms facing forward, curl it toward your shoulders while keeping elbows tucked.',
  ),
  Exercise(
    name: 'Chest Fly',
    muscle: 'Chest',
    equipment: 'Machine',
    videoAsset: 'assets/videos/chest_fly_machine.mp4',
    description: 'Sit on the machine and bring the handles together in front of you in a wide arc, then return slowly.',
  ),
  Exercise(
    name: 'Deadlift',
    muscle: 'Back',
    equipment: 'Barbell',
    videoAsset: 'assets/videos/deadlift.mp4',
    description: 'Lift the barbell from the floor by extending your hips and knees to a standing position, then lower back down.',
  ),
  Exercise(
    name: 'Decline Bench Press',
    muscle: 'Chest',
    equipment: 'Barbell',
    videoAsset: 'assets/videos/decline_bench_press.MOVEMENT',
    description: 'Lie on a decline bench, lower the bar to your lower chest, and press it back up.',
  ),
  Exercise(
    name: 'Hammer Curl',
    muscle: 'Arms',
    equipment: 'Dumbbell',
    videoAsset: 'assets/videos/hammer_curl.mp4',
    description: 'Hold dumbbells with palms facing your body and curl them up to shoulder height.',
  ),
  Exercise(
    name: 'Hip Thrust',
    muscle: 'Legs',
    equipment: 'Barbell',
    videoAsset: 'assets/videos/hip_thrust.mp4',
    description: 'Rest your upper back on a bench, thrust your hips up with a barbell over your pelvis, then lower.',
  ),
  Exercise(
    name: 'Incline Bench Press',
    muscle: 'Chest',
    equipment: 'Barbell',
    videoAsset: 'assets/videos/incline_bench_press.mp4',
    description: 'Lie on an incline bench, lower the bar to your upper chest, and press it back up.',
  ),
  Exercise(
    name: 'Lat Pulldown',
    muscle: 'Back',
    equipment: 'Machine',
    videoAsset: 'assets/videos/lat_pulldown.mp4',
    description: 'Sit at the pulldown machine and pull the bar to your chest while keeping your torso upright.',
  ),
  Exercise(
    name: 'Lateral Raise',
    muscle: 'Shoulders',
    equipment: 'Dumbbell',
    videoAsset: 'assets/videos/lateral_raise.mp4',
    description: 'With a dumbbell in each hand, lift arms to the sides until parallel with the floor, then lower.',
  ),
  Exercise(
    name: 'Leg Extension',
    muscle: 'Legs',
    equipment: 'Machine',
    videoAsset: 'assets/videos/leg_extension.mp4',
    description: 'Sit on the leg extension machine and extend your legs fully, then return to the starting position.',
  ),
  Exercise(
    name: 'Leg Raises',
    muscle: 'Core',
    equipment: 'Bodyweight',
    videoAsset: 'assets/videos/leg_raises.mp4',
    description: 'Lie flat and lift both legs until vertical, then lower slowly without touching the ground.',
  ),
  Exercise(
    name: 'Plank',
    muscle: 'Core',
    equipment: 'Bodyweight',
    videoAsset: 'assets/videos/plank.mp4',
    description: 'Support your body on forearms and toes in a straight line, keeping your core tight.',
  ),
  Exercise(
    name: 'Pull Up',
    muscle: 'Back',
    equipment: 'Bodyweight',
    videoAsset: 'assets/videos/pull_up.mp4',
    description: 'Hang from a bar and pull yourself up until your chin is above the bar, then lower back down.',
  ),
  Exercise(
    name: 'Push Up',
    muscle: 'Chest',
    equipment: 'Bodyweight',
    videoAsset: 'assets/videos/push_up.mp4',
    description: 'Lower your body by bending your elbows, then push back up while keeping your core engaged.',
  ),
  Exercise(
    name: 'Romanian Deadlift',
    muscle: 'Legs',
    equipment: 'Barbell',
    videoAsset: 'assets/videos/romanian_deadlift.mp4',
    description: 'With a slight bend in your knees, hinge at the hips to lower the bar, then return to standing.',
  ),
  Exercise(
    name: 'Russian Twist',
    muscle: 'Core',
    equipment: 'Bodyweight',
    videoAsset: 'assets/videos/russian_twist.mp4',
    description: 'Sit with knees bent, lean back, and twist your torso to each side, optionally holding a weight.',
  ),
  Exercise(
    name: 'Shoulder Press',
    muscle: 'Shoulders',
    equipment: 'Dumbbell',
    videoAsset: 'assets/videos/shoulder_press.mp4',
    description: 'Press dumbbells overhead from shoulder height, then lower them back down slowly.',
  ),
  Exercise(
    name: 'Squat',
    muscle: 'Legs',
    equipment: 'Bodyweight',
    videoAsset: 'assets/videos/squat.mp4',
    description: 'Stand tall, lower your hips as if sitting, then return to standing while keeping your back straight.',
  ),
  Exercise(
    name: 'T-Bar Row',
    muscle: 'Back',
    equipment: 'Barbell',
    videoAsset: 'assets/videos/t_bar_row.mp4',
    description: 'Hinge forward and pull the bar toward your torso, squeezing your back muscles, then lower.',
  ),
  Exercise(
    name: 'Tricep Dips',
    muscle: 'Arms',
    equipment: 'Bodyweight',
    videoAsset: 'assets/videos/tricep_dips.mp4',
    description: 'Lower your body by bending elbows behind you on parallel bars or a bench, then push back up.',
  ),
  Exercise(
    name: 'Tricep Pushdown',
    muscle: 'Arms',
    equipment: 'Machine',
    videoAsset: 'assets/videos/tricep_pushdown.mp4',
    description: 'Stand at a cable machine and push the bar down by extending your elbows fully.',
  ),
];
