import 'package:flutter/material.dart';

class LightBarChart extends StatelessWidget {
  final List<String> labels;
  final List<double> values;
  final String unit;
  final Color color;
  final double height;

  const LightBarChart({
    super.key,
    required this.labels,
    required this.values,
    required this.unit,
    this.color = const Color(0xFFEE0000), // Viettel Red
    this.height = 150,
  });

  @override
  Widget build(BuildContext context) {
    if (values.isEmpty) return SizedBox(height: height, child: const Center(child: Text('No data')));

    final maxValue = values.reduce((a, b) => a > b ? a : b);
    final maxScale = maxValue == 0 ? 1.0 : maxValue * 1.2;

    return SizedBox(
      height: height,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(values.length, (index) {
          final val = values[index];
          final heightFactor = val / maxScale;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text('${val.toStringAsFixed(0)}$unit', style: const TextStyle(fontSize: 10, color: Colors.black54)),
                  const SizedBox(height: 4),
                  Flexible(
                    child: FractionallySizedBox(
                      heightFactor: heightFactor,
                      child: Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    labels[index],
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}
