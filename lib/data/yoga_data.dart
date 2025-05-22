class YogaPose {
  final String name;
  final String targetArea;
  final String videoAsset;
  final String description;

  YogaPose({
    required this.name,
    required this.targetArea,
    required this.videoAsset,
    required this.description,
  });
}

final List<YogaPose> yogaPoses = [
  YogaPose(
    name: 'Child\'s Pose',
    targetArea: 'Back',
    videoAsset: 'assets/videos/childs_pose.mp4',
    description: 'Kneel on the floor, sit back on your heels, and stretch your arms forward while lowering your forehead to the mat.',
  ),
  YogaPose(
    name: 'Quad Stretch',
    targetArea: 'Legs',
    videoAsset: 'assets/videos/quad_stretch.mp4',
    description: 'Stand or lie on your side and pull your heel toward your glutes, keeping your knees close together.',
  ),
  YogaPose(
    name: 'Cat-Cow',
    targetArea: 'Upper Body',
    videoAsset: 'assets/videos/cat_cow.mp4',
    description: 'Move between arching your back (cat) and lifting your chest (cow) to warm up the spine and shoulders.',
  ),
  YogaPose(
    name: 'Cobra Twists',
    targetArea: 'Back',
    videoAsset: 'assets/videos/cobra_twists.mp4',
    description: 'Lie on your stomach, press up into cobra pose, and gently twist side to side to release tension.',
  ),
  YogaPose(
    name: 'Puppy Pose',
    targetArea: 'Upper Body',
    videoAsset: 'assets/videos/puppy_pose.mp4',
    description: 'Start on all fours and walk your hands forward, keeping hips over knees and lowering your chest.',
  ),
  YogaPose(
    name: 'Thread the Needle',
    targetArea: 'Back',
    videoAsset: 'assets/videos/thread_the_needle.mp4',
    description: 'From hands and knees, thread one arm under the other to stretch the shoulders and upper back.',
  ),
  YogaPose(
    name: 'Butterfly Forward Fold',
    targetArea: 'Hips',
    videoAsset: 'assets/videos/butterfly_forward_fold.mp4',
    description: 'Sit with soles of your feet together and fold forward over your legs to stretch hips and lower back.',
  ),
  YogaPose(
    name: 'Butterfly Stretch',
    targetArea: 'Hips',
    videoAsset: 'assets/videos/butterfly_stretch.mp4',
    description: 'Sit with the soles of your feet together and gently press your knees toward the floor.',
  ),
  YogaPose(
    name: 'Eagle Arms',
    targetArea: 'Upper Body',
    videoAsset: 'assets/videos/eagle_arms.mp4',
    description: 'Wrap one arm under the other and press palms together to stretch shoulders and upper back.',
  ),
  YogaPose(
    name: 'Straddle Forward Fold',
    targetArea: 'Legs',
    videoAsset: 'assets/videos/straddle_forward_fold.mp4',
    description: 'Sit with legs wide apart and fold forward at the hips to stretch inner thighs and hamstrings.',
  ),
  YogaPose(
    name: 'Neck Circles',
    targetArea: 'Neck',
    videoAsset: 'assets/videos/neck_circles.mp4',
    description: 'Slowly roll your head in circles to release neck tension. Switch directions halfway through.',
  ),
  YogaPose(
    name: 'Side-to-Side Stretch',
    targetArea: 'Full Body / Sides',
    videoAsset: 'assets/videos/side_to_side_stretch.mp4',
    description: 'Stand or sit and reach one arm overhead, stretching through the side of your torso.',
  ),
];
