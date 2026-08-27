import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:minesweeper/main.dart';

void main() {
  testWidgets('shows classic Minesweeper layout', (WidgetTester tester) async {
    await tester.pumpWidget(const MinesweeperApp());

    expect(find.byType(StatusPanel), findsOneWidget);
    expect(find.text('030'), findsOneWidget);
    expect(find.text('010'), findsNothing);
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

  testWidgets('reset button starts a new randomized game', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(home: MinesweeperScreen(random: Random(1))),
    );

    final firstGame = tester
        .widget<MinesweeperBoard>(find.byType(MinesweeperBoard))
        .game;
    final firstMineIndexes = mineIndexesFor(firstGame);

    await tester.tap(find.byKey(const Key('reset-button')));
    await tester.pump();

    final secondGame = tester
        .widget<MinesweeperBoard>(find.byType(MinesweeperBoard))
        .game;
    final secondMineIndexes = mineIndexesFor(secondGame);

    expect(secondGame, isNot(same(firstGame)));
    expect(secondMineIndexes, isNot(firstMineIndexes));
    expect(find.byType(MineTile), findsNWidgets(200));
  });

  test('new game places 30 hidden mines', () {
    final game = MinesweeperGame(random: Random(1));

    expect(game.cells.where((cell) => cell.hasMine), hasLength(30));
    expect(game.cells.where((cell) => cell.isRevealed), isEmpty);
    expect(game.status, GameStatus.playing);
  });

  testWidgets('30 mines means the counter shows 30', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MinesweeperApp());

    expect(
      find.text(CounterDisplay.format(MinesweeperScreen.mineCount)),
      findsOneWidget,
    );
  });

  testWidgets('long pressing a tile toggles a flag and updates the counter', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(home: MinesweeperScreen(random: Random(1))),
    );

    await tester.longPress(find.byType(MineTile).first);
    await tester.pump();

    expect(find.text('029'), findsOneWidget);
    expect(
      tester
          .widget<CoveredMineTile>(find.byType(CoveredMineTile).first)
          .cell
          .isFlagged,
      isTrue,
    );
    expect(
      find.byWidgetPredicate(
        (widget) => widget is CustomPaint && widget.painter is FlagPainter,
      ),
      findsOneWidget,
    );

    await tester.longPress(find.byType(MineTile).first);
    await tester.pump();

    expect(find.text('030'), findsOneWidget);
    expect(
      tester
          .widget<CoveredMineTile>(find.byType(CoveredMineTile).first)
          .cell
          .isFlagged,
      isFalse,
    );
  });

  testWidgets('reset clears placed flags', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(home: MinesweeperScreen(random: Random(1))),
    );

    await tester.longPress(find.byType(MineTile).first);
    await tester.pump();
    expect(find.text('029'), findsOneWidget);

    await tester.tap(find.byKey(const Key('reset-button')));
    await tester.pump();

    final resetGame = tester
        .widget<MinesweeperBoard>(find.byType(MinesweeperBoard))
        .game;

    expect(find.text('030'), findsOneWidget);
    expect(resetGame.flaggedCount, 0);
  });

  testWidgets('covered tiles appear recessed while pressed', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox.square(
          dimension: 40,
          child: MineTile(
            cell: MineCell(hasMine: false),
            revealMines: false,
            canInteract: true,
            onTap: () {},
            onLongPress: () {},
          ),
        ),
      ),
    );

    expect(
      tester.widget<CoveredMineTile>(find.byType(CoveredMineTile)).isPressed,
      isFalse,
    );

    final gesture = await tester.startGesture(
      tester.getCenter(find.byType(MineTile)),
    );
    await tester.pump(const Duration(milliseconds: 100));

    expect(
      tester.widget<CoveredMineTile>(find.byType(CoveredMineTile)).isPressed,
      isTrue,
    );

    await gesture.cancel();
    await tester.pump();

    expect(
      tester.widget<CoveredMineTile>(find.byType(CoveredMineTile)).isPressed,
      isFalse,
    );
  });

  test('non-mine cells track adjacent mine counts', () {
    final game = MinesweeperGame.withMines(
      columns: 3,
      rows: 3,
      mineIndexes: {0},
    );

    expect(game.cells[1].adjacentMineCount, 1);
    expect(game.cells[3].adjacentMineCount, 1);
    expect(game.cells[4].adjacentMineCount, 1);
    expect(game.cells[8].adjacentMineCount, 0);
  });

  test('revealing a zero expands to empty cells and bordering numbers', () {
    final game = MinesweeperGame.withMines(
      columns: 3,
      rows: 3,
      mineIndexes: {0},
    );

    game.reveal(8);

    expect(game.cells[8].isRevealed, isTrue);
    expect(game.cells[1].isRevealed, isTrue);
    expect(game.cells[0].isRevealed, isFalse);
    expect(game.status, GameStatus.won);
  });

  test('revealing a mine loses and reveals all mines', () {
    final game = MinesweeperGame.withMines(
      columns: 3,
      rows: 3,
      mineIndexes: {0, 8},
    );

    game.reveal(0);

    expect(game.status, GameStatus.lost);
    expect(game.cells[0].isRevealed, isTrue);
    expect(game.cells[8].isRevealed, isTrue);
    expect(game.cells[1].isRevealed, isFalse);
  });

  test('flagged cells cannot be revealed by a normal tap', () {
    final game = MinesweeperGame.withMines(
      columns: 2,
      rows: 2,
      mineIndexes: {0},
    );

    game.toggleFlag(1);
    game.reveal(1);

    expect(game.flaggedCount, 1);
    expect(game.remainingMineCount, 0);
    expect(game.cells[1].isFlagged, isTrue);
    expect(game.cells[1].isRevealed, isFalse);

    game.toggleFlag(1);
    game.reveal(1);

    expect(game.flaggedCount, 0);
    expect(game.cells[1].isRevealed, isTrue);
  });

  test('revealing all non-mine cells wins the game', () {
    final game = MinesweeperGame.withMines(
      columns: 2,
      rows: 2,
      mineIndexes: {0},
    );

    game.reveal(1);
    game.reveal(2);
    game.reveal(3);

    expect(game.status, GameStatus.won);

    game.reveal(0);

    expect(game.status, GameStatus.won);
    expect(game.cells[0].isRevealed, isFalse);
  });

  test('revealing all but one non-mine cell does not win the game', () {
    final game = MinesweeperGame.withMines(
      columns: 2,
      rows: 2,
      mineIndexes: {0},
    );

    game.reveal(1);
    game.reveal(2);

    expect(game.status, GameStatus.playing);
    expect(game.cells[3].isRevealed, isFalse);
  });

  testWidgets('won games show the win state in the smiley area', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: StatusPanel(
          mineCounter: MinesweeperScreen.mineCount,
          status: GameStatus.won,
          onReset: () {},
        ),
      ),
    );

    final resetButtonPaint = tester.widget<CustomPaint>(
      find.descendant(
        of: find.byKey(const Key('reset-button')),
        matching: find.byType(CustomPaint),
      ),
    );

    expect(resetButtonPaint.painter, isA<SmileyPainter>());
    expect((resetButtonPaint.painter! as SmileyPainter).status, GameStatus.won);
  });
}

Set<int> mineIndexesFor(MinesweeperGame game) {
  return {
    for (var index = 0; index < game.cells.length; index++)
      if (game.cells[index].hasMine) index,
  };
}
