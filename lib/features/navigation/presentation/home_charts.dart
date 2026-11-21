import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../posts/domain/entities/post.dart';

class HomeCharts extends StatelessWidget {
  const HomeCharts({super.key, required this.posts});

  final List<Post> posts;

  @override
  Widget build(BuildContext context) {
    if (posts.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Text('Create or load posts to see analytics here.'),
        ),
      );
    }

    final byAuthor = <int, int>{};
    final postsByAuthor = <int, List<Post>>{};
    for (final post in posts) {
      byAuthor.update(post.userId, (count) => count + 1, ifAbsent: () => 1);
      postsByAuthor.putIfAbsent(post.userId, () => []).add(post);
    }
    final entries = byAuthor.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    final maxCount = entries.fold<int>(
      1,
      (maximum, entry) => math.max(maximum, entry.value),
    );
    final lineMaximum = entries.fold<int>(0, (sum, entry) => sum + entry.value);
    final averageWordCountMax = _averageWordCountMax(postsByAuthor);

    return Column(
      children: [
        _ChartCard(
          title: 'Posts by author',
          subtitle: 'Number of posts for each author',
          child: SizedBox(
            height: 230,
            child: BarChart(
              BarChartData(
                maxY: maxCount.toDouble() + 1,
                alignment: BarChartAlignment.spaceAround,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: maxCount > 5
                      ? (maxCount / 4).ceilToDouble()
                      : 1,
                ),
                borderData: FlBorderData(show: false),
                titlesData: _titlesData(
                  entries.length,
                  (index) => 'A${entries[index].key}',
                ),
                barGroups: [
                  for (var index = 0; index < entries.length; index++)
                    BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: entries[index].value.toDouble(),
                          width: entries.length > 12 ? 10 : 18,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(5),
                          ),
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        _ChartCard(
          title: 'Cumulative posts by author',
          subtitle: 'Running total across author IDs',
          child: SizedBox(
            height: 230,
            child: LineChart(
              LineChartData(
                minY: 0,
                maxY: lineMaximum.toDouble() + 1,
                minX: 0,
                maxX: math.max(1, entries.length - 1).toDouble(),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: lineMaximum > 5
                      ? (lineMaximum / 4).ceilToDouble()
                      : 1,
                ),
                borderData: FlBorderData(show: false),
                titlesData: _titlesData(
                  entries.length,
                  (index) => 'A${entries[index].key}',
                ),
                lineBarsData: [
                  LineChartBarData(
                    isCurved: true,
                    color: Theme.of(context).colorScheme.tertiary,
                    barWidth: 3,
                    dotData: FlDotData(show: entries.length < 20),
                    belowBarData: BarAreaData(
                      show: true,
                      color: Theme.of(context).colorScheme.tertiary
                          .withValues(alpha: 0.12),
                    ),
                    spots: _cumulativeSpots(entries),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        _ChartCard(
          title: 'Average content length by author',
          subtitle: 'Average words per post, based on title and body text',
          child: Column(
            children: [
              SizedBox(
                height: 250,
                child: BarChart(
                  BarChartData(
                    maxY: averageWordCountMax,
                    alignment: BarChartAlignment.spaceAround,
                    groupsSpace: 14,
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      horizontalInterval: averageWordCountMax > 5
                          ? (averageWordCountMax / 4).ceilToDouble()
                          : 1,
                    ),
                    borderData: FlBorderData(show: false),
                    titlesData: _titlesData(
                      entries.length,
                      (index) => 'A${entries[index].key}',
                    ),
                    barGroups: [
                      for (var index = 0; index < entries.length; index++)
                        _contentLengthGroup(
                          index: index,
                          authorPosts: postsByAuthor[entries[index].key]!,
                          context: context,
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 20,
                runSpacing: 8,
                children: [
                  _LegendItem(
                    color: Theme.of(context).colorScheme.primary,
                    label: 'Title words',
                  ),
                  _LegendItem(
                    color: Theme.of(context).colorScheme.tertiary,
                    label: 'Body words',
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  static double _averageWordCountMax(Map<int, List<Post>> postsByAuthor) {
    var maximum = 0.0;
    for (final authorPosts in postsByAuthor.values) {
      final titleAverage =
          authorPosts
              .map((post) => _wordCount(post.title))
              .reduce((a, b) => a + b) /
          authorPosts.length;
      final bodyAverage =
          authorPosts
              .map((post) => _wordCount(post.body))
              .reduce((a, b) => a + b) /
          authorPosts.length;
      maximum = math.max(maximum, math.max(titleAverage, bodyAverage));
    }
    return maximum + 1;
  }

  static BarChartGroupData _contentLengthGroup({
    required int index,
    required List<Post> authorPosts,
    required BuildContext context,
  }) {
    final titleAverage =
        authorPosts
            .map((post) => _wordCount(post.title))
            .reduce((a, b) => a + b) /
        authorPosts.length;
    final bodyAverage =
        authorPosts
            .map((post) => _wordCount(post.body))
            .reduce((a, b) => a + b) /
        authorPosts.length;
    final colors = Theme.of(context).colorScheme;

    return BarChartGroupData(
      x: index,
      barsSpace: 4,
      barRods: [
        BarChartRodData(
          toY: titleAverage,
          width: 9,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
          color: colors.primary,
        ),
        BarChartRodData(
          toY: bodyAverage,
          width: 9,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
          color: colors.tertiary,
        ),
      ],
    );
  }

  static int _wordCount(String value) => value
      .trim()
      .split(RegExp(r'\s+'))
      .where((word) => word.isNotEmpty)
      .length;

  static List<FlSpot> _cumulativeSpots(List<MapEntry<int, int>> entries) {
    var total = 0;
    return [
      for (var index = 0; index < entries.length; index++)
        FlSpot(index.toDouble(), (total += entries[index].value).toDouble()),
    ];
  }

  static FlTitlesData _titlesData(int count, String Function(int) label) {
    return FlTitlesData(
      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      leftTitles: const AxisTitles(
        sideTitles: SideTitles(showTitles: true, reservedSize: 32),
      ),
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 28,
          interval: count > 8 ? (count / 6).ceilToDouble() : 1,
          getTitlesWidget: (value, meta) {
            final index = value.toInt();
            if (index < 0 || index >= count || value != index.toDouble()) {
              return const SizedBox.shrink();
            }
            return SideTitleWidget(
              meta: meta,
              child: Text(label(index), style: const TextStyle(fontSize: 10)),
            );
          },
        ),
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

class _ChartCard extends StatelessWidget {
  const _ChartCard({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}
