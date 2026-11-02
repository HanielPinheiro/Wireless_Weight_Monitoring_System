import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/weight.dart';
import '../../models/baby.dart';
import '../../views/babies/babies_edit.dart';
import '../../repository/providers/baby_provider.dart';
import '../../repository/design/button_styles.dart';
import '../../repository/design/fonts.dart';
import '../../repository/helper/conversions.dart';
import '../../repository/widgets/baby_weight_chart.dart';
import '../../repository/widgets/elements.dart';

class BabiesDetails extends StatefulWidget {
  final int id;

  BabiesDetails({super.key, required this.id});

  @override
  State<BabiesDetails> createState() => _BabiesDetailsState();
}

class _BabiesDetailsState extends State<BabiesDetails> {
  bool _isLoading = true;
  BabyModel? _currentBaby;
  List<WeightModel>? _weights;
  DailyWeightSummary? _selectedDay;
  WeightModel? _selectedWeightItem;

  bool get _hasLinkedScale => _currentBaby?.scaleId != null;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _loadData();
    });
  }

  Future<void> _loadData() async {
    final babyProvider = context.read<BabyProvider>();
    final baby = await babyProvider.getBabyById(context, widget.id);
    final weights = await baby.getWeights();

    if (mounted) {
      setState(() {
        _currentBaby = baby;
        _weights = weights;
        _isLoading = false;
      });
    }
  }

  void _clearSelection() {
    setState(() {
      _selectedDay = null;
      _selectedWeightItem = null;
    });
  }

  int _calculateAgeDays(DateTime birth) {
    final now = DateTime.now();
    return now.difference(birth).inDays;
  }

  String _formatAge(DateTime birth) {
    final days = _calculateAgeDays(birth);
    if (days < 30) return '$days dias';
    final months = (days / 30).floor();
    final remainingDays = days - (months * 30);
    if (months < 12) return remainingDays == 0 ? '$months meses' : '$months meses e $remainingDays dias';
    final years = months ~/ 12;
    final remMonths = months % 12;
    return remMonths == 0 ? '$years anos' : '$years anos e $remMonths meses';
  }

  WeightModel? _getLastWeight() {
    final w = _weights;
    if (w == null || w.isEmpty) return null;
    final sorted = List<WeightModel>.from(w)..sort((a, b) => a.date.compareTo(b.date));
    return sorted.lastWhere((item) => item.weight > 0, orElse: () => sorted.last);
  }

  WeightModel? _getPreviousWeight() {
    final w = _weights;
    if (w == null || w.length < 2) return null;
    final sorted = List<WeightModel>.from(w)..sort((a, b) => a.date.compareTo(b.date));
    final positive = sorted.where((item) => item.weight > 0).toList();
    if (positive.length < 2) return null;
    return positive[positive.length - 2];
  }

  String _formatWeightDiff(double last, double prev) {
    final diff = last - prev;
    final prefix = diff > 0 ? '+' : '';
    return '$prefix${diff.toStringAsFixed(1)} g';
  }

  static final DateFormat _dayFormatter = DateFormat('dd/MM');
  static final DateFormat _hourFormatter = DateFormat('HH:mm');

  String _formatWeight(double value) {
    if (value == value.roundToDouble()) {
      return value.toStringAsFixed(0);
    }
    return value.toStringAsFixed(1);
  }

  Widget _wrapText(BuildContext context, String text) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.center,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
        child: Text(
          text,
          style: TextStyle(fontSize: 20, color: Theme.of(context).colorScheme.primary),
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  Widget _buildBabyHeader() {
    final baby = _currentBaby!;
    final isActive = baby.isActive ?? true;
    final ageText = baby.birthDate != null ? _formatAge(baby.birthDate!) : '—';
    final statusText = isActive ? 'Ativo' : 'Inativo';

    final List<Widget> children = [
      if (baby.qrCodeImage != null)
        Container(
          constraints: const BoxConstraints(maxWidth: 120),
          child: baby.qrCodeImage,
        ),
      const SizedBox(width: 10),
      Expanded(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 20),
            Text(
              'Dados do Bebê',
              textAlign: TextAlign.center,
              style: displaySmall.copyWith(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold,
                fontSize: 24,
              ),
            ),
            const SizedBox(height: 20),
            _wrapText(context, 'Nome: ${baby.name ?? '—'}'),
            _wrapText(context, 'Status: $statusText'),
            _wrapText(context, 'Registro: ${baby.hospitalRegister}'),
            _wrapText(context, 'Idade: $ageText'),
            if (baby.motherName != null) _wrapText(context, 'Mãe: ${baby.motherName!}'),
            if (baby.birthDate != null)
              _wrapText(context, 'Nascimento: ${dateFormatter_objToDb.format(baby.birthDate!)}'),
            const SizedBox(height: 20),
            ElementsOfViews.GroupChildrenInRow([
              ElementsOfViews.SimpleButton(
                context,
                'Editar',
                () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => BabiesEdit(baby: _currentBaby!)),
                  );
                  await _loadData();
                },
                false,
              ),
              ElementsOfViews.SimpleButton(
                context,
                isActive ? 'Inativar Bebê' : 'Ativar Bebê',
                () async {
                  await context.read<BabyProvider>().toggleBabyStatus(context, _currentBaby!);
                  await _loadData();
                },
                false,
                isActive ? _hasLinkedScale : false,
              ),
            ]),
            const SizedBox(height: 20),
          ],
        ),
      ),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(15),
        child: Container(
          padding: const EdgeInsets.all(9),
          decoration: MyDecorations().GetBoxDecoration(context),
          child: Row(
            mainAxisSize: MainAxisSize.max,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: children,
          ),
        ),
      ),
    );
  }

  Widget _buildBabySummary() {
    final weights = _weights ?? const <WeightModel>[];
    final lastWeight = _getLastWeight();
    final prevWeight = _getPreviousWeight();
    final positiveWeights = weights.where((w) => w.weight > 0).toList();

    final variationValue = lastWeight != null && prevWeight != null
        ? _formatWeightDiff(lastWeight.weight, prevWeight.weight)
        : '—';

    final List<Widget> children = [
      const SizedBox(height: 10),
      Text(
        'Resumo Clínico',
        textAlign: TextAlign.center,
        style: displaySmall.copyWith(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.bold,
          fontSize: 24,
        ),
      ),
      const SizedBox(height: 10),
      _wrapText(context, 'Último Peso: ${lastWeight != null ? '${_formatWeight(lastWeight.weight)} g' : '—'}'),
      if (lastWeight != null)
        _wrapText(context, 'Data Medição: ${dateFormatter_log.format(lastWeight.date)}'),
      _wrapText(context, 'Variação: $variationValue'),
      _wrapText(context, 'Total Medições: ${positiveWeights.length}'),
      if (positiveWeights.isNotEmpty)
        _wrapText(context, 'Primeira Medição: ${dateFormatter_objToDb.format(positiveWeights.first.date)}'),
      const SizedBox(height: 20),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(15),
        child: Container(
          padding: const EdgeInsets.all(9),
          decoration: MyDecorations().GetBoxDecoration(context),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: children,
          ),
        ),
      ),
    );
  }

  Widget _buildDetailChip(IconData icon, String label, String value, ColorScheme colorScheme) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: colorScheme.primary),
        const SizedBox(width: 4),
        Flexible(
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: '$label: ',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                TextSpan(
                  text: value,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildSelectionDetailsCard() {
    final colorScheme = Theme.of(context).colorScheme;
    if (_selectedDay == null && _selectedWeightItem == null) {
      return const SizedBox.shrink();
    }

    Widget innerContent;
    String headerTitle;

    if (_selectedDay != null) {
      final s = _selectedDay!;
      final totalMeasurements = s.measurements.length;
      headerTitle = 'Detalhes do Dia Selecionado';
      innerContent = Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(Icons.date_range, size: 16, color: colorScheme.primary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Dia ${_dayFormatter.format(s.day)}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                      fontSize: 18,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: _clearSelection,
                  icon: const Icon(Icons.close),
                  iconSize: 18,
                  splashRadius: 16,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  tooltip: 'Fechar',
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 20,
              runSpacing: 10,
              children: [
                _buildDetailChip(Icons.bar_chart, 'Mediana', '${_formatWeight(s.medianWeight)} g', colorScheme),
                _buildDetailChip(Icons.countertops, 'Total', '$totalMeasurements med.', colorScheme),
                _buildDetailChip(Icons.arrow_downward, 'Mín', '${_formatWeight(s.minWeight)} g', colorScheme),
                _buildDetailChip(Icons.arrow_upward, 'Máx', '${_formatWeight(s.maxWeight)} g', colorScheme),
                _buildDetailChip(
                  Icons.schedule,
                  'Última',
                  '${_hourFormatter.format(s.measurements.last.date)} - ${_formatWeight(s.lastWeight)} g',
                  colorScheme,
                ),
                if (s.zeroMeasurementsCount > 0)
                  _buildDetailChip(Icons.block, 'Tara(s)', '${s.zeroMeasurementsCount}', colorScheme),
              ],
            ),
          ],
        ),
      );
    } else {
      final w = _selectedWeightItem!;
      final isTara = w.weight == 0;
      headerTitle = 'Detalhes da Medição';
      innerContent = Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(
                  isTara ? Icons.filter_none : Icons.receipt_long,
                  size: 16,
                  color: colorScheme.primary,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    isTara ? 'Tara' : 'Peso Individual',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                      fontSize: 18,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: _clearSelection,
                  icon: const Icon(Icons.close),
                  iconSize: 18,
                  splashRadius: 16,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  tooltip: 'Fechar',
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 20,
              runSpacing: 10,
              children: [
                _buildDetailChip(Icons.monitor_weight, 'Peso', '${_formatWeight(w.weight)} g', colorScheme),
                _buildDetailChip(Icons.event, 'Data', _dayFormatter.format(w.date), colorScheme),
                _buildDetailChip(Icons.schedule, 'Hora', _hourFormatter.format(w.date), colorScheme),
                _buildDetailChip(Icons.scale, 'Balança', '#${w.scaleId}', colorScheme),
                if (isTara) _buildDetailChip(Icons.block, 'Tipo', 'Tara', colorScheme),
              ],
            ),
          ],
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ElementsOfViews.CardToText(context, headerTitle, fontSize: 22),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: InkWell(
            borderRadius: BorderRadius.circular(15),
            child: Container(
              padding: const EdgeInsets.all(9),
              decoration: MyDecorations().GetBoxDecoration(context),
              child: innerContent,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEvolutionCard() {
    final hasData = _weights != null && _weights!.isNotEmpty;

    final innerBox = Container(
      padding: const EdgeInsets.all(9),
      decoration: MyDecorations().GetBoxDecoration(context),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ElementsOfViews.CardToText(context, 'Evolução Ponderal', fontSize: 22),
          const SizedBox(height: 8),
          SizedBox(
            height: 420,
            child: hasData
                ? BabyWeightChart(
                    historicWeight: _weights!,
                    onDaySelected: (day) => setState(() => _selectedDay = day),
                    onWeightSelected: (w) => setState(() => _selectedWeightItem = w),
                  )
                : Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.insert_chart_outlined_rounded,
                            size: 48,
                            color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Sem dados suficientes',
                            textAlign: TextAlign.center,
                            style: titleLarge.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(15),
        child: innerBox,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final backgroundColor = Theme.of(context).colorScheme.surface;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: backgroundColor,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_currentBaby == null) {
      return Scaffold(
        backgroundColor: backgroundColor,
        appBar: ElementsOfViews.SimpleAppBar(context, 'Dados do Bebê'),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Card(
              color: backgroundColor,
              shape: RoundedRectangleBorder(
                side: BorderSide(color: Theme.of(context).colorScheme.primary, width: 1.0),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Padding(
                padding: EdgeInsets.all(16),
                child: Text('Nenhum bebê encontrado'),
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: ElementsOfViews.SimpleAppBar(context, 'Dados do Bebê'),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildBabyHeader(),
              const SizedBox(height: 20),
              _buildBabySummary(),
              const SizedBox(height: 20),
              _buildEvolutionCard(),
              _buildSelectionDetailsCard(),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
