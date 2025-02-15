int getTargetForExercise(String exerciseName, String exerciseType) {
  // Define target values based on exercise type or name
  if (exerciseType == 'Reps') {
    if (exerciseName == 'Push-ups') {
      return 10;
    } else if (exerciseName == 'Squats') {
      return 10;
    } else if (exerciseName == 'Bicep Curls') {
      return 10;
    }
  } else if (exerciseType == 'Seconds') {
    if (exerciseName == 'Plank') {
      return 10;
    } else if (exerciseName == 'Cardio') {
      return 10;
    }
  } else if (exerciseType == 'Meters') {
    if (exerciseName == 'Running') {
      return 100;
    } else if (exerciseName == 'Cycling') {
      return 100;
    }
  }

  return 0;
}
