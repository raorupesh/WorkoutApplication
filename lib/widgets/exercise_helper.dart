// lib/helpers/exercise_helper.dart

int getTargetForExercise(String exerciseName, String exerciseType) {
  // Define target values based on exercise type or name
  if (exerciseType == 'Reps') {
    if (exerciseName == 'Push-ups') {
      return 10;
    } else if (exerciseName == 'Squats') {
      return 15;
    }
    else if (exerciseName == 'Bicep Curls') {
      return 5;
    }
  } else if (exerciseType == 'Seconds') {
    if (exerciseName == 'Plank') {
      return 60;
    } else if (exerciseName == 'Cardio') {
      return 120;
    }
  } else if (exerciseType == 'Meters') {
    if (exerciseName == 'Running') {
      return 100;
    } else if (exerciseName == 'Cycling') {
      return 500;
    }
  }

  return 0;
}
