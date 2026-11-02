import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/weight.dart';
import '../helper/conversions.dart';

enum _ChartMode { chart, list }

class DailyWeightSummary {
  final DateTime day;
  final List<WeightModel> measurements;
  final double medianWeight;
  final double minWeight;
  final double maxWeight;
  final double lastWeight;
  final int positiveMeasurementsCount;
  final int zeroMeasurementsCount;

  const DailyWeightSummary({
    required this.day,
    required this.measurements,
    required this.medianWeight,
    required this.minWeight,
    required this.maxWeight,
    required this.lastWeight,
    required this.positiveMeasurementsCount,
    required this.zeroMeasurementsCount,
  });
}

class BabyWeightChart extends StatefulWidget {
  final List<WeightModel>? historicWeight;
  final ValueChanged<DailyWeightSummary?>? onDaySelected;
  final ValueChanged<WeightModel?>? onWeightSelected;

  const BabyWeightChart({
    super.key,
    this.historicWeight,
    this.onDaySelected,
    this.onWeightSelected,
  });

  static const List<String> _monthNames = <String>[
    'janeiro',
    'fevereiro',
    'marco',
    'abril',
    'maio',
    'junho',
    'julho',
    'agosto',
    'setembro',
    'outubro',
    'novembro',
    'dezembro',
  ];

  static List<DateTime> availableMonths(List<WeightModel> weights) {
    final seenMonths = <String>{};
    final sortedWeights = List<WeightModel>.from(weights)..sort((a, b) => a.date.compareTo(b.date));

    return sortedWeights
        .where((weight) => seenMonths.add(monthKey(weight.date)))
        .map((weight) => DateTime(weight.date.year, weight.date.month))
        .toList();
  }

  static Map<DateTime, List<WeightModel>> groupWeightsByMonth(List<WeightModel> weights) {
    final groupedWeights = <DateTime, List<WeightModel>>{};

    for (final weight in List<WeightModel>.from(weights)..sort((a, b) => a.date.compareTo(b.date))) {
      final month = DateTime(weight.date.year, weight.date.month);
      groupedWeights.putIfAbsent(month, () => <WeightModel>[]).add(weight);
    }

    return groupedWeights;
  }

  static List<WeightModel> filterWeightsForMonth(List<WeightModel> weights, DateTime month) {
    final monthDate = DateTime(month.year, month.month);
    final groupedWeights = groupWeightsByMonth(weights);

    return List<WeightModel>.from(groupedWeights[monthDate] ?? const <WeightModel>[]);
  }

  static String monthKey(DateTime date) => '${date.year}-${date.month.toString().padLeft(2, '0')}';

  static String monthLabel(DateTime month) => '${_monthNames[month.month - 1]} de ${month.year}';

  @override
  State<BabyWeightChart> createState() => _BabyWeightChartState();
}

class _BabyWeightChartState extends State<BabyWeightChart> {
  static final DateFormat _dayFormatter = DateFormat('dd/MM');
  static const double _fallbackChartHeight = 280;
  static const double _summaryEdgePadding = 0.6;

  late List<WeightModel> _sortedWeights;
  late List<DateTime> _availableMonths;
  int _selectedMonthIndex = 0;
  _ChartMode _chartMode = _ChartMode.chart;

  DailyWeightSummary? _selectedChartDay;
  WeightModel? _selectedListItem;
  bool _sortAscending = true;

  @override
  void initState() {
    super.initState();
    _rebuildChartState();
  }

  @override
  void didUpdateWidget(covariant BabyWeightChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.historicWeight != oldWidget.historicWeight) {
      _rebuildChartState(preserveCurrentMonth: true);
    }
  }

  void _rebuildChartState({bool preserveCurrentMonth = false}) {
    final previousMonth = preserveCurrentMonth && _availableMonths.isNotEmpty ? _availableMonths[_selectedMonthIndex.clamp(0, _availableMonths.length - 1)] : null;

    _sortedWeights = _sanitizeWeights(widget.historicWeight ?? const <WeightModel>[]);
    _availableMonths = BabyWeightChart.availableMonths(_sortedWeights);

    if (_availableMonths.isEmpty) {
      _selectedMonthIndex = 0;
      _chartMode = _ChartMode.chart;
      _clearSelection();
      return;
    }

    if (previousMonth != null) {
      final preservedIndex = _availableMonths.indexWhere((month) => _isSameMonth(month, previousMonth));
      if (preservedIndex >= 0) {
        _selectedMonthIndex = preservedIndex;
        return;
      }
    }

    _selectedMonthIndex = _availableMonths.length - 1;
    _chartMode = _ChartMode.chart;
    _clearSelection();
  }

  bool _isSameMonth(DateTime left, DateTime right) => left.year == right.year && left.month == right.month;

  void _clearSelection() {
    _selectedChartDay = null;
    _selectedListItem = null;
  }

  void _selectChartDay(DailyWeightSummary day) {
    setState(() {
      _selectedChartDay = day;
      _selectedListItem = null;
    });
    widget.onDaySelected?.call(day);
    widget.onWeightSelected?.call(null);
  }

  void _selectListItem(WeightModel weight) {
    setState(() {
      _selectedListItem = weight;
      _selectedChartDay = null;
    });
    widget.onDaySelected?.call(null);
    widget.onWeightSelected?.call(weight);
  }

  void _toggleSortOrder() {
    setState(() {
      _sortAscending = !_sortAscending;
    });
  }

  void _changeMonth(int offset) {
    final nextIndex = _selectedMonthIndex + offset;
    if (nextIndex < 0 || nextIndex >= _availableMonths.length) {
      return;
    }

    setState(() {
      _selectedMonthIndex = nextIndex;
      _chartMode = _ChartMode.chart;
      _clearSelection();
    });
  }

  double _weightAxisInterval(double minY, double maxY) {
    final delta = (maxY - minY).abs();
    if (delta <= 0) {
      return 100;
    }

    final roughStep = delta / 4;
    final magnitude = math.pow(10, math.max(0, (math.log(roughStep) / math.ln10).floor())).toDouble();
    final normalizedStep = roughStep / magnitude;

    if (normalizedStep <= 1) {
      return magnitude;
    }
    if (normalizedStep <= 2) {
      return 2 * magnitude;
    }
    if (normalizedStep <= 5) {
      return 5 * magnitude;
    }
    return 10 * magnitude;
  }

  String _formatWeight(double value) {
    if (value == value.roundToDouble()) {
      return value.toStringAsFixed(0);
    }
    return value.toStringAsFixed(1);
  }

  double _sanitizeWeight(double value) => value <= 0 ? 0 : value;

  List<WeightModel> _sanitizeWeights(List<WeightModel> weights) {
    final sanitized = weights.map((weight) => weight.copyWith(weight: _sanitizeWeight(weight.weight))).toList();
    sanitized.sort((a, b) => a.date.compareTo(b.date));
    return sanitized;
  }

  int _daysInMonth(DateTime month) => DateTime(month.year, month.month + 1, 0).day;

  double _median(List<double> values) {
    final sortedValues = List<double>.from(values)..sort();
    final middle = sortedValues.length ~/ 2;
    if (sortedValues.length.isOdd) {
      return sortedValues[middle];
    }
    return (sortedValues[middle - 1] + sortedValues[middle]) / 2;
  }

  List<DailyWeightSummary> _buildDailySummaries(List<WeightModel> weights) {
    final grouped = <DateTime, List<WeightModel>>{};
    for (final weight in weights) {
      final day = DateTime(weight.date.year, weight.date.month, weight.date.day);
      grouped.putIfAbsent(day, () => <WeightModel>[]).add(weight);
    }

    final summaries = grouped.entries.map((entry) {
      final measurements = List<WeightModel>.from(entry.value)..sort((a, b) => a.date.compareTo(b.date));
      final values = measurements.map((item) => item.weight).toList();
      final positiveValues = values.where((value) => value > 0).toList();
      final valuesForMedian = positiveValues.isNotEmpty ? positiveValues : values;

      return DailyWeightSummary(
        day: entry.key,
        measurements: measurements,
        medianWeight: _median(valuesForMedian),
        minWeight: values.reduce(math.min),
        maxWeight: values.reduce(math.max),
        lastWeight: measurements.last.weight,
        positiveMeasurementsCount: positiveValues.length,
        zeroMeasurementsCount: measurements.length - positiveValues.length,
      );
    }).toList();

    summaries.sort((a, b) => a.day.compareTo(b.day));
    return summaries;
  }

  void _selectMode(_ChartMode mode, List<DailyWeightSummary> summaries) {
    setState(() {
      _chartMode = mode;
      _clearSelection();
    });
  }

  TextStyle _selectorLabelStyle(BuildContext context) {
    return TextStyle(
          color: Theme.of(context).colorScheme.primary,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        );
  }

  Widget _buildModeSelector(List<DailyWeightSummary> summaries) {
    final labelStyle = _selectorLabelStyle(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        alignment: WrapAlignment.center,
        children: [
          ChoiceChip(
            selectedColor: Theme.of(context).colorScheme.onSecondary,
            checkmarkColor: Theme.of(context).colorScheme.primary,
            label: Text('Gráfico', style: labelStyle),
            selected: _chartMode == _ChartMode.chart,
            onSelected: summaries.isEmpty ? null : (_) => _selectMode(_ChartMode.chart, summaries),
          ),
          ChoiceChip(
            selectedColor: Theme.of(context).colorScheme.onSecondary,
            checkmarkColor: Theme.of(context).colorScheme.primary,
            label: Text('Lista', style: labelStyle),
            selected: _chartMode == _ChartMode.list,
            onSelected: summaries.isEmpty ? null : (_) => _selectMode(_ChartMode.list, summaries),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryChart(
    List<DailyWeightSummary> summaries,
    ColorScheme colorScheme,
    BoxConstraints constraints,
  ) {
    final allWeights = summaries.map((summary) => summary.medianWeight).toList();
    final spots = summaries.map((summary) => FlSpot(summary.day.day.toDouble(), summary.medianWeight)).toList();
    final minYValue = allWeights.reduce(math.min);
    final maxYValue = allWeights.reduce(math.max);
    final verticalPadding = math.max((maxYValue - minYValue).abs() * 0.15, 50.0).toDouble();
    final minY = math.max(0.0, minYValue - verticalPadding).toDouble();
    final maxY = (maxYValue + verticalPadding).toDouble();
    final selectedMonth = _availableMonths[_selectedMonthIndex];
    final daysInMonth = _daysInMonth(selectedMonth);
    final maxVisibleLabels = math.max(1, (constraints.maxWidth / 56).floor());
    final labelStep = math.max(1, (daysInMonth / maxVisibleLabels).ceil());
    final chartBaseWidth = constraints.maxWidth * 1.5;

    Widget buildBottomTitle(double value, TitleMeta meta) {
      final roundedValue = value.round();
      final hasDayAlignment = (value - roundedValue).abs() <= 0.08;
      if (!hasDayAlignment || roundedValue < 1 || roundedValue > daysInMonth) {
        return const SizedBox.shrink();
      }

      final isLastLabel = roundedValue == daysInMonth;
      if ((roundedValue - 1) % labelStep != 0 && !isLastLabel) {
        return const SizedBox.shrink();
      }

      final labelDate = DateTime(selectedMonth.year, selectedMonth.month, roundedValue);
      return SideTitleWidget(
        meta: meta,
        space: 8,
        child: Transform.rotate(
          angle: -math.pi / 4,
          child: Text(
            _dayFormatter.format(labelDate),
            style: TextStyle(color: colorScheme.primary, fontSize: 10),
          ),
        ),
      );
    }

    Widget buildLeftTitle(double value, TitleMeta meta) {
      return Text(
        _formatWeight(value),
        style: TextStyle(color: colorScheme.primary, fontSize: 11),
      );
    }

    final lineChart = LineChart(
      LineChartData(
        minX: 1 - _summaryEdgePadding,
        maxX: daysInMonth + _summaryEdgePadding,
        minY: minY,
        maxY: maxY,
        lineTouchData: LineTouchData(
          enabled: true,
          handleBuiltInTouches: false,
          touchCallback: (event, response) {
            if (event is FlTapUpEvent && response?.lineBarSpots?.isNotEmpty == true) {
              final touchedIndex = response!.lineBarSpots!.first.spotIndex;
              if (touchedIndex >= 0 && touchedIndex < summaries.length) {
                _selectChartDay(summaries[touchedIndex]);
              }
            }
          },
        ),
        gridData: FlGridData(
          show: true,
          verticalInterval: 1,
          horizontalInterval: _weightAxisInterval(minY, maxY),
          getDrawingVerticalLine: (_) => FlLine(
            color: colorScheme.outlineVariant.withValues(alpha: 0.35),
            strokeWidth: 1,
          ),
          getDrawingHorizontalLine: (_) => FlLine(
            color: colorScheme.outlineVariant.withValues(alpha: 0.35),
            strokeWidth: 1,
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 42,
              interval: 1,
              getTitlesWidget: buildBottomTitle,
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 48,
              interval: _weightAxisInterval(minY, maxY),
              getTitlesWidget: buildLeftTitle,
            ),
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: colorScheme.primary),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: false,
            color: colorScheme.primary,
            barWidth: 2,
            belowBarData: BarAreaData(
              show: true,
              color: colorScheme.primary.withValues(alpha: 0.08),
            ),
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                final isSelected = _selectedChartDay != null &&
                    summaries[index].day.day == _selectedChartDay!.day.day;
                return FlDotCirclePainter(
                  radius: isSelected ? 10 : 7,
                  color: isSelected ? colorScheme.secondary : colorScheme.primary,
                  strokeWidth: 2,
                  strokeColor: colorScheme.surface,
                );
              },
            ),
          ),
        ],
      ),
    );

    final chartTotalHeight = constraints.maxHeight > 0 ? constraints.maxHeight : _fallbackChartHeight;

    return InteractiveViewer(
      minScale: 1.0,
      maxScale: 10.0,
      constrained: false,
      scaleFactor: 250,
      alignment: Alignment.centerLeft,
      child: SizedBox(
        width: chartBaseWidth,
        height: chartTotalHeight,
        child: Padding(
          padding: const EdgeInsets.only(left: 10, right: 20, top: 12, bottom: 16),
          child: lineChart,
        ),
      ),
    );
  }

  Widget _buildWeightList(List<WeightModel> monthWeights, ColorScheme colorScheme) {
    final sortedWeights = List<WeightModel>.from(monthWeights);
    sortedWeights.sort((a, b) {
      final cmp = a.date.compareTo(b.date);
      return _sortAscending ? cmp : -cmp;
    });

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                onPressed: _toggleSortOrder,
                icon: Icon(
                  _sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
                  size: 16,
                ),
                label: Text(
                  _sortAscending ? 'Mais antigo primeiro' : 'Mais recente primeiro',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            itemCount: sortedWeights.length,
            separatorBuilder: (_, __) => Divider(
              height: 1,
              color: colorScheme.outlineVariant.withValues(alpha: 0.5),
            ),
            itemBuilder: (context, index) {
              final w = sortedWeights[index];
              final isSelected = _selectedListItem?.id == w.id;
              final isTara = w.weight == 0;

              return ListTile(
                selected: isSelected,
                selectedTileColor: colorScheme.primary.withValues(alpha: 0.08),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: isSelected
                      ? BorderSide(color: colorScheme.primary.withValues(alpha: 0.5), width: 1)
                      : BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                visualDensity: VisualDensity.compact,
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? colorScheme.primary.withValues(alpha: 0.15)
                        : colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    isTara ? Icons.filter_none : Icons.monitor_weight_outlined,
                    color: isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant,
                    size: 20,
                  ),
                ),
                title: Text(
                  isTara ? 'Tara' : '${_formatWeight(w.weight)} g',
                  style: TextStyle(
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                    color: isTara ? colorScheme.onSurfaceVariant : colorScheme.onSurface,
                  ),
                ),
                subtitle: Text(
                  dateFormatter_log.format(w.date),
                  style: TextStyle(
                    fontSize: 12,
                    color: isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant,
                  ),
                ),
                trailing: Icon(
                  Icons.chevron_right,
                  color: isSelected ? colorScheme.primary : colorScheme.outline,
                ),
                onTap: () => _selectListItem(w),
              );
            },
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.historicWeight == null || widget.historicWeight!.isEmpty || _availableMonths.isEmpty) {
      return const Center(child: Text('No data available'));
    }

    final selectedMonth = _availableMonths[_selectedMonthIndex];
    final monthWeights = BabyWeightChart.filterWeightsForMonth(_sortedWeights, selectedMonth);
    final summaries = _buildDailySummaries(monthWeights);
    final colorScheme = Theme.of(context).colorScheme;
    final selectorLabelStyle = _selectorLabelStyle(context);
    final monthSelector = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          IconButton(
            onPressed: _selectedMonthIndex > 0 ? () => _changeMonth(-1) : null,
            icon: const Icon(Icons.arrow_back_ios_new),
            tooltip: 'Mes anterior',
          ),
          Expanded(
            child: Text(
              BabyWeightChart.monthLabel(selectedMonth),
              textAlign: TextAlign.center,
              style: selectorLabelStyle.copyWith(fontSize: 18),
            ),
          ),
          IconButton(
            onPressed: _selectedMonthIndex < _availableMonths.length - 1 ? () => _changeMonth(1) : null,
            icon: const Icon(Icons.arrow_forward_ios),
            tooltip: 'Proximo mes',
          ),
        ],
      ),
    );

    final chartArea = LayoutBuilder(
      builder: (context, constraints) {
        if (summaries.isEmpty) {
          return const Center(child: Text('Sem dados suficientes'));
        }

        if (_chartMode == _ChartMode.list) {
          return _buildWeightList(monthWeights, colorScheme);
        }

        return _buildSummaryChart(summaries, colorScheme, constraints);
      },
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final children = <Widget>[
          monthSelector,
          _buildModeSelector(summaries),
        ];

        if (constraints.hasBoundedHeight) {
          children.add(Expanded(child: chartArea));
          return Column(children: children);
        }

        children.add(SizedBox(height: _fallbackChartHeight, child: chartArea));
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: children,
        );
      },
    );
  }
}
