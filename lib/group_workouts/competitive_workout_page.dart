import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';

class CompetitiveWorkoutDetailsPage extends StatelessWidget {
  final String workoutCode;
  final Map<String, dynamic> workoutData;

  const CompetitiveWorkoutDetailsPage(
      {Key? key, required this.workoutCode, required this.workoutData})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final exercises = workoutData['exercises'] as List<dynamic>;

    return Scaffold(
      appBar: AppBar(
        title: Text('Competitive Workout'),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => context.go('/workoutPlanSelection'),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              "Workout Code: $workoutCode",
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.teal),
            ),
            SizedBox(height: 10),
            QrImageView(
              data: workoutCode,
              size: 180,
              backgroundColor: Colors.white,
              embeddedImageStyle: QrEmbeddedImageStyle(size: Size(60, 60)),
            ),
            SizedBox(height: 20),
            Text(
              "Share this code with others to compete!",
              style: TextStyle(fontSize: 16, color: Colors.black54),
            ),
            SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: exercises.length,
                itemBuilder: (context, index) {
                  final exercise = exercises[index];
                  return Card(
                    elevation: 3,
                    margin: EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    child: ListTile(
                      title: Text(
                        exercise['name'],
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.teal.shade800),
                      ),
                      subtitle: Text(
                        "Target: ${exercise['targetOutput']} ${exercise['type']}",
                        style: TextStyle(
                            fontSize: 16, color: Colors.grey.shade700),
                      ),
                      trailing: ElevatedButton(
                        onPressed: () {
                          // TODO: Implement tracking progress logic
                        },
                        child: Text("Complete"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
