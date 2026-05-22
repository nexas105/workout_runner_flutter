import 'package:flutter/widgets.dart';

import '../../theme/workout_runner_theme.dart';
import '../internals/runner_card.dart';
import '../internals/section_label.dart';

/// Bar chart of weekly training volume.
///
/// Pure stateless renderer — caller computes the buckets (e.g. via
/// `WorkoutStats.weeklySummary` over a sliding window) and passes a list of
/// `({weekStart, volume})` records ordered oldest -> newest.
///
/// Visual design:
///   * Horizontal grid: 4 evenly spaced lines using `theme.border`.
///   * Vertical bars: `theme.accent`, rounded top corners, minimum 2px height
///     for non-zero values so even tiny weeks register visually.
///   * X-axis labels: short `MMM d` of `weekStart`, every other bar to avoid
///     crowding (always shows first + last).
///   * Empty state: a soft hint text inside the same card frame.
///
/// No external chart dependency — plain `CustomPainter`.
class VolumeTrendChart extends StatelessWidget {
  final List<({DateTime weekStart, double volume})> data;
  final double? maxOverride;
  final double height;

  const VolumeTrendChart({
    super.key,
    required this.data,
    this.maxOverride,
    this.height = 120,
  });

  @override
  Widget build(BuildContext context) {
    final t = WorkoutRunnerTheme.of(context);
    return RunnerCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          const SectionLabel('Volume trend'),
          SizedBox(height: t.space3),
          if (data.isEmpty)
            SizedBox(
              height: height,
              child: Center(
                child: Text('Not enough data yet.', style: t.bodyMuted),
              ),
            )
          else
            SizedBox(
              height: height,
              child: CustomPaint(
                painter: _BarChartPainter(
                  data: data,
                  maxOverride: maxOverride,
                  accent: t.accent,
                  border: t.border,
                  labelStyle: t.caption.copyWith(fontSize: 10),
                  labelColor: t.textMuted,
                ),
                child: const SizedBox.expand(),
              ),
            ),
        ],
      ),
    );
  }
}

class _BarChartPainter extends CustomPainter {
  final List<({DateTime weekStart, double volume})> data;
  final double? maxOverride;
  final Color accent;
  final Color border;
  final TextStyle labelStyle;
  final Color labelColor;

  static const _months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  _BarChartPainter({
    required this.data,
    required this.maxOverride,
    required this.accent,
    required this.border,
    required this.labelStyle,
    required this.labelColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    const double labelStripHeight = 16;
    final chartHeight = (size.height - labelStripHeight).clamp(
      0.0,
      double.infinity,
    );
    if (chartHeight <= 0) return;

    final maxValue = _resolveMax();
    final gridPaint =
        Paint()
          ..color = border
          ..strokeWidth = 1;

    // 4 horizontal grid lines (0%, 33%, 66%, 100%).
    for (var i = 0; i < 4; i++) {
      final y = chartHeight * (i / 3.0);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final n = data.length;
    final slot = size.width / n;
    final barWidth = (slot * 0.6).clamp(2.0, slot);
    final barPaint = Paint()..color = accent;

    for (var i = 0; i < n; i++) {
      final v = data[i].volume;
      final ratio = maxValue <= 0 ? 0.0 : (v / maxValue).clamp(0.0, 1.0);
      var barHeight = chartHeight * ratio;
      if (v > 0 && barHeight < 2) barHeight = 2;
      final x = slot * i + (slot - barWidth) / 2;
      final top = chartHeight - barHeight;
      final rect = RRect.fromRectAndCorners(
        Rect.fromLTWH(x, top, barWidth, barHeight),
        topLeft: const Radius.circular(3),
        topRight: const Radius.circular(3),
      );
      canvas.drawRRect(rect, barPaint);
    }

    // X-axis labels — every other bar to avoid crowding, always show last.
    final labelY = chartHeight + 2;
    for (var i = 0; i < n; i++) {
      final isFirst = i == 0;
      final isLast = i == n - 1;
      if (!isFirst && !isLast && i.isOdd) continue;
      final text = _shortDate(data[i].weekStart);
      final tp = TextPainter(
        text: TextSpan(
          text: text,
          style: labelStyle.copyWith(color: labelColor),
        ),
        textDirection: TextDirection.ltr,
        maxLines: 1,
      )..layout(maxWidth: slot * 2);
      final labelX = (slot * i + slot / 2 - tp.width / 2).clamp(
        0.0,
        (size.width - tp.width).clamp(0.0, double.infinity),
      );
      tp.paint(canvas, Offset(labelX, labelY));
    }
  }

  double _resolveMax() {
    if (maxOverride != null && maxOverride! > 0) return maxOverride!;
    var max = 0.0;
    for (final r in data) {
      if (r.volume > max) max = r.volume;
    }
    return max;
  }

  static String _shortDate(DateTime d) {
    final m = _months[(d.month - 1).clamp(0, 11)];
    return '$m ${d.day}';
  }

  @override
  bool shouldRepaint(_BarChartPainter old) =>
      old.data != data ||
      old.maxOverride != maxOverride ||
      old.accent != accent ||
      old.border != border ||
      old.labelColor != labelColor;
}
