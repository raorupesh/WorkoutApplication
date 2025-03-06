import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:html/parser.dart' as htmlParser;
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import '../main.dart';
import '../models/workout_model.dart';
import '../widgets/recent_performance_widget.dart';

class DownloadWorkoutPage extends StatefulWidget {
  @override
  _DownloadWorkoutPageState createState() => _DownloadWorkoutPageState();
}

class _DownloadWorkoutPageState extends State<DownloadWorkoutPage> {
  final TextEditingController _urlController = TextEditingController();
  Workout? _workoutPlan;
  String? _errorMessage;
  List<String> _jsonLinks = [];
  bool _isLoading = false;

  Future<void> _fetchContent() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _jsonLinks = [];
      _workoutPlan = null;
    });

    final url = _urlController.text.trim();
    if (url.isEmpty) {
      setState(() {
        _errorMessage = "Please enter a valid URL.";
        _isLoading = false;
      });
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
          setState(() => _errorMessage = "Unsupported content type: $contentType");
        }
      } else {
        setState(() => _errorMessage = "Failed to fetch content. Check the URL.");
      }
    } catch (e) {
      setState(() => _errorMessage = "Error fetching content: $e");
    } finally {
      setState(() => _isLoading = false);
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
        _errorMessage = jsonUrls.isEmpty ? "No JSON links found on the page." : null;
      });
    } catch (e) {
      setState(() => _errorMessage = "Error parsing HTML: $e");
    }
  }

  Future<void> _fetchSelectedWorkout(String jsonUrl) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await http.get(Uri.parse(jsonUrl));
      if (response.statusCode == 200) {
        _parseWorkoutJson(response.body);
      } else {
        setState(() => _errorMessage = "Failed to fetch selected workout plan.");
      }
    } catch (e) {
      setState(() => _errorMessage = "Error fetching workout plan: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _saveWorkout() {
    if (_workoutPlan != null) {
      Provider.of<WorkoutProvider>(context, listen: false)
          .addDownloadedPlan(_workoutPlan!);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Workout plan "${_workoutPlan!.workoutName}" saved successfully!'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
      context.go('/workoutPlanSelection');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => context.go('/workoutPlanSelection'),
        ),
        title: Text("Download Workout Plan"),
        elevation: 2,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // URL Input Section
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Enter Workout URL",
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 12),
                      TextField(
                        controller: _urlController,
                        decoration: InputDecoration(
                          labelText: "Workout Plan URL",
                          hintText: "https://example.com/workout.json",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          prefixIcon: Icon(Icons.link),
                          filled: true,
                          fillColor: theme.colorScheme.surface,
                        ),
                      ),
                      SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _isLoading ? null : _fetchContent,
                          icon: _isLoading
                              ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2)
                          )
                              : Icon(Icons.download),
                          label: Text(_isLoading ? "Downloading..." : "Download Plan"),
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              if (_errorMessage != null) ...[
                SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: Colors.red),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(color: Colors.red.shade800),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // JSON Links Section
              if (_jsonLinks.isNotEmpty) ...[
                SizedBox(height: 20),
                Text(
                  "Available Workout Plans",
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Expanded(
                  child: Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: ListView.separated(
                      padding: EdgeInsets.all(8),
                      itemCount: _jsonLinks.length,
                      separatorBuilder: (context, index) => Divider(),
                      itemBuilder: (context, index) {
                        final linkUri = Uri.parse(_jsonLinks[index]);
                        final fileName = linkUri.pathSegments.last;

                        return ListTile(
                          leading: Icon(Icons.fitness_center, color: theme.colorScheme.primary),
                          title: Text(
                            fileName,
                            style: TextStyle(fontWeight: FontWeight.w500),
                          ),
                          subtitle: Text(
                            _jsonLinks[index],
                            style: TextStyle(fontSize: 12),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: ElevatedButton(
                            onPressed: _isLoading ? null : () => _fetchSelectedWorkout(_jsonLinks[index]),
                            child: Text("Load"),
                            style: ElevatedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        );
                      },
                    ),
                  ),
                ),
              ],

              // Workout Preview Section
              if (_workoutPlan != null) ...[
                SizedBox(height: 20),
                Container(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: EdgeInsets.all(16),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: theme.colorScheme.onPrimary,
                        radius: 24,
                        child: Icon(Icons.fitness_center, size: 28),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _workoutPlan!.workoutName,
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.onPrimaryContainer,
                              ),
                            ),
                            Text(
                              "${_workoutPlan!.exercises.length} exercises",
                              style: TextStyle(
                                color: theme.colorScheme.onPrimaryContainer.withOpacity(0.8),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 12),
                Text(
                  "Exercises",
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Expanded(
                  child: Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: ListView.builder(
                      padding: EdgeInsets.all(8),
                      itemCount: _workoutPlan!.exercises.length,
                      itemBuilder: (context, index) {
                        final exercise = _workoutPlan!.exercises[index];
                        return Card(
                          elevation: 0,
                          color: theme.colorScheme.surface,
                          margin: EdgeInsets.symmetric(vertical: 4),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: theme.colorScheme.primaryContainer,
                              child: Text(
                                "${index + 1}",
                                style: TextStyle(
                                  color: theme.colorScheme.onPrimaryContainer,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            title: Text(
                              exercise.name,
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                            subtitle: Text(
                              "Target: ${exercise.targetOutput} ${exercise.type}",
                              style: TextStyle(
                                color: theme.colorScheme.onSurface.withOpacity(0.7),
                              ),
                            ),
                            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _saveWorkout,
                    icon: Icon(Icons.save),
                    label: Text("Save Workout Plan"),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: theme.colorScheme.onPrimary,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: theme.cardColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 4,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Container(
            height: 80,
            child: RecentPerformanceWidget(),
          ),
        ),
      ),
    );
  }
}