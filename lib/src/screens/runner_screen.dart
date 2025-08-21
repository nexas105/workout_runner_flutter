import 'package:fitness_workout/fitness_workout.dart';
import 'package:flutter/material.dart';

String fmt(Duration d) {
  final h = d.inHours;
  final m = d.inMinutes.remainder(60);
  final s = d.inSeconds.remainder(60);
  if (h > 0) {
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  } else {
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }
}

class RunnerDefaultScreen extends StatefulWidget {
  final WorkoutPlan plan;

  const RunnerDefaultScreen({super.key, required this.plan});

  @override
  State<RunnerDefaultScreen> createState() => _RunnerDefaultScreenState();
}

class _RunnerDefaultScreenState extends State<RunnerDefaultScreen> {
  bool _ready = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      // Sicherstellen, dass der Singleton vorhanden und konfiguriert ist
      await runner.configure(); // autoResume = true (default)
      setState(() {
        _ready = true;
        _error = null;
      });
    } catch (e) {
      setState(() {
        _error = 'Runner konnte nicht initialisiert werden: $e';
        _ready = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      return Scaffold(
        appBar: AppBar(title: const Text('Runner')),
        body: Center(
          child:
              _error == null
                  ? const CircularProgressIndicator()
                  : Padding(
                    padding: const EdgeInsets.all(4),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline, size: 32),
                        const SizedBox(height: 12),
                        Text(_error!, textAlign: TextAlign.center),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          onPressed: _init,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Erneut versuchen'),
                        ),
                      ],
                    ),
                  ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Runner')),
      body: Padding(
        padding: const EdgeInsets.all(4),
        child: RunnerPanel(
          controller: runner,
          plan: widget.plan,
          onFinished: (res) {
            debugPrint('Workout finished: ${res.toJson()}');
            Navigator.pop(context);
          },
        ),
      ),
    );
  }
}
