import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:html/parser.dart' as htmlParser;
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import '../main.dart';
import '../models/workout_model.dart';

class DownloadWorkoutPage extends StatefulWidget {
  @override
  _DownloadWorkoutPageState createState() => _DownloadWorkoutPageState();
}

class _DownloadWorkoutPageState extends State<DownloadWorkoutPage> {
  final TextEditingController _urlController = TextEditingController();
  Workout? _workoutPlan;
  String? _errorMessage;
  List<String> _jsonLinks = [];

  Future<void> _fetchContent() async {
    final url = _urlController.text.trim();
    if (url.isEmpty) {
      setState(() => _errorMessage = "Please enter a valid URL.");
      return;
    }

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final contentType = response.headers['content-type'] ?? "";
        if (contentType.contains("application/json")) {
          _parseWorkoutJson(response.body);
        } else if (contentType.contains("text/html")) {
          _extractJsonLinks(response.body, url);
        } else {
          setState(
              () => _errorMessage = "Unsupported content type: $contentType");
        }
      } else {
        setState(
            () => _errorMessage = "Failed to fetch content. Check the URL.");
      }
    } catch (e) {
      setState(() => _errorMessage = "Error fetching content: $e");
    }
  }

  void _parseWorkoutJson(String jsonStr) {
    try {
      final data = json.decode(jsonStr);
      setState(() {
        _workoutPlan = Workout.fromJson(data);
        _errorMessage = null;
      });
    } catch (e) {
      setState(() => _errorMessage = "Invalid JSON format.");
    }
  }

  void _extractJsonLinks(String htmlContent, String baseUrl) {
    try {
      final document = htmlParser.parse(htmlContent);
      final links = document.querySelectorAll('a[href]');
      List<String> jsonUrls = [];

      for (var link in links) {
        final href = link.attributes['href'];
        if (href != null && href.endsWith('.json')) {
          jsonUrls.add(Uri.parse(baseUrl).resolve(href).toString());
        }
      }

      setState(() {
        _jsonLinks = jsonUrls;
        _errorMessage =
            jsonUrls.isEmpty ? "No JSON links found on the page." : null;
      });
    } catch (e) {
      setState(() => _errorMessage = "Error parsing HTML: $e");
    }
  }

  Future<void> _fetchSelectedWorkout(String jsonUrl) async {
    try {
      final response = await http.get(Uri.parse(jsonUrl));
      if (response.statusCode == 200) {
        _parseWorkoutJson(response.body);
      } else {
        setState(
            () => _errorMessage = "Failed to fetch selected workout plan.");
      }
    } catch (e) {
      setState(() => _errorMessage = "Error fetching workout plan: $e");
    }
  }

  void _saveWorkout() {
    if (_workoutPlan != null) {
      Provider.of<WorkoutProvider>(context, listen: false)
          .addDownloadedPlan(_workoutPlan!);

      // Use go_router instead of Navigator.pop()
      context
          .go('/workout-selection'); // Redirects to the workout selection page
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Download Workout Plan")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _urlController,
              decoration: InputDecoration(
                  labelText: "Workout Plan URL", border: OutlineInputBorder()),
            ),
            SizedBox(height: 10),
            ElevatedButton(
                onPressed: _fetchContent, child: Text("Download Plan")),
            if (_errorMessage != null) ...[
              SizedBox(height: 10),
              Text(_errorMessage!, style: TextStyle(color: Colors.red)),
            ],
            if (_jsonLinks.isNotEmpty) ...[
              SizedBox(height: 20),
              Text("Select a JSON Workout Plan:",
                  style: TextStyle(fontWeight: FontWeight.bold)),
              Expanded(
                child: ListView.builder(
                  itemCount: _jsonLinks.length,
                  itemBuilder: (context, index) {
                    return ListTile(
                      title: Text(_jsonLinks[index]),
                      trailing: ElevatedButton(
                        onPressed: () =>
                            _fetchSelectedWorkout(_jsonLinks[index]),
                        child: Text("Load"),
                      ),
                    );
                  },
                ),
              ),
            ],
            if (_workoutPlan != null) ...[
              SizedBox(height: 20),
              Text("Workout: ${_workoutPlan!.workoutName}",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Expanded(
                child: ListView.builder(
                  itemCount: _workoutPlan!.exercises.length,
                  itemBuilder: (context, index) {
                    final exercise = _workoutPlan!.exercises[index];
                    return ListTile(
                        title: Text(exercise.name),
                        subtitle: Text(
                            "Target: ${exercise.targetOutput} ${exercise.type}"));
                  },
                ),
              ),
              ElevatedButton(
                  onPressed: _saveWorkout, child: Text("Save Workout")),
            ],
          ],
        ),
      ),
    );
  }
}
