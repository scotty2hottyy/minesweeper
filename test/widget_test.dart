import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:minesweeper/main.dart';

void main() {
  testWidgets('shows classic Minesweeper layout', (WidgetTester tester) async {
    await tester.pumpWidget(const MinesweeperApp());

    expect(find.byType(StatusPanel), findsOneWidget);
    expect(find.text('010'), findsOneWidget);
    expect(find.text('000'), findsOneWidget);
    expect(find.byType(MineTile), findsNWidgets(200));

    final boardSize = tester.getSize(find.byType(GridView));
    expect(
      boardSize.height,
      closeTo(
        boardSize.width / MinesweeperScreen.columns * MinesweeperScreen.rows,
        0.001,
      ),
    );
  });
}
