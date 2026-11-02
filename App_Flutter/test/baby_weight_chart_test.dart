import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:precious_weight/models/weight.dart';
import 'package:precious_weight/repository/widgets/baby_weight_chart.dart';

List<WeightModel> _sampleWeights() {
  return <WeightModel>[
    WeightModel(
      id: 1,
      date: DateTime(2026, 5, 29, 8),
      scaleId: 10,
      babyId: 7,
      weight: 3100,
    ),
    WeightModel(
      id: 2,
      date: DateTime(2026, 5, 30, 8),
      scaleId: 10,
      babyId: 7,
      weight: 3150,
    ),
    WeightModel(
      id: 3,
      date: DateTime(2026, 5, 31, 8),
      scaleId: 10,
      babyId: 7,
      weight: 3180,
    ),
    WeightModel(
      id: 4,
      date: DateTime(2026, 6, 1, 8),
      scaleId: 10,
      babyId: 7,
      weight: 3200,
    ),
    WeightModel(
      id: 5,
      date: DateTime(2026, 6, 2, 8),
      scaleId: 10,
      babyId: 7,
      weight: 3220,
    ),
    WeightModel(
      id: 6,
      date: DateTime(2026, 6, 2, 20),
      scaleId: 10,
      babyId: 7,
      weight: 3235,
    ),
  ];
}

void main() {
  group('BabyWeightChart month filtering', () {
    test('keeps records inside their calendar month groups', () {
      final groupedWeights = BabyWeightChart.groupWeightsByMonth(_sampleWeights());

      expect(groupedWeights.length, 2);
      expect(
        groupedWeights[DateTime(2026, 5)]?.map((weight) => weight.id),
        orderedEquals(<int>[1, 2, 3]),
      );
      expect(
        groupedWeights[DateTime(2026, 6)]?.map((weight) => weight.id),
        orderedEquals(<int>[4, 5, 6]),
      );
    });

    testWidgets('navigates between months and keeps same-day measurements visible', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 900,
              height: 420,
              child: BabyWeightChart(historicWeight: _sampleWeights()),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('junho de 2026'), findsOneWidget);
      expect(find.text('01/06'), findsOneWidget);
      expect(find.text('02/06'), findsOneWidget);

      var chart = tester.widget<LineChart>(find.byType(LineChart));
      expect(chart.data.lineBarsData.single.spots.length, 3);
      final juneSpots = chart.data.lineBarsData.single.spots;
      expect(juneSpots[0].x, 0);
      expect(juneSpots[1].x, lessThan(1));
      expect(juneSpots[2].x, greaterThan(1));

      await tester.tap(find.byIcon(Icons.arrow_back_ios_new));
      await tester.pumpAndSettle();

      expect(find.text('maio de 2026'), findsOneWidget);
      expect(find.text('29/05'), findsOneWidget);
      expect(find.text('31/05'), findsOneWidget);

      chart = tester.widget<LineChart>(find.byType(LineChart));
      expect(chart.data.lineBarsData.single.spots.length, 3);

      await tester.tap(find.byIcon(Icons.arrow_forward_ios));
      await tester.pumpAndSettle();

      expect(find.text('junho de 2026'), findsOneWidget);
      chart = tester.widget<LineChart>(find.byType(LineChart));
      expect(chart.data.lineBarsData.single.spots.length, 3);
    });

    testWidgets('renders inside an unbounded vertical parent without flex exceptions', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 24),
                  BabyWeightChart(historicWeight: _sampleWeights()),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(LineChart), findsOneWidget);
      expect(find.text('junho de 2026'), findsOneWidget);
    });
  });
}
