import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

void main() {
  runApp(const MinesweeperApp());
}

class MinesweeperApp extends StatelessWidget {
  const MinesweeperApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Minesweeper',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: WindowsColors.face),
        scaffoldBackgroundColor: WindowsColors.face,
        useMaterial3: true,
      ),
      home: const MinesweeperScreen(),
    );
  }
}

class MinesweeperScreen extends StatefulWidget {
  const MinesweeperScreen({super.key, this.random});

  static const int columns = 10;
  static const int rows = 20;
  static const int mineCount = 30;
  static const double outerPadding = 12;

  final Random? random;

  @override
  State<MinesweeperScreen> createState() => _MinesweeperScreenState();
}

class _MinesweeperScreenState extends State<MinesweeperScreen> {
  late MinesweeperGame game;
  Timer? timer;
  int elapsedSeconds = 0;
  bool hasStartedTimer = false;

  @override
  void initState() {
    super.initState();
    game = MinesweeperGame(random: widget.random);
  }

  void resetGame() {
    stopTimer();
    setState(() {
      game = MinesweeperGame(random: widget.random);
      elapsedSeconds = 0;
      hasStartedTimer = false;
    });
  }

  void revealCell(int index) {
    if (game.canReveal(index) && !hasStartedTimer) {
      startTimer();
    }

    setState(() {
      game.reveal(index);
      if (game.status != GameStatus.playing) {
        stopTimer();
      }
    });
  }

  void toggleFlag(int index) {
    setState(() {
      game.toggleFlag(index);
    });
  }

  void startTimer() {
    hasStartedTimer = true;
    timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || game.status != GameStatus.playing) {
        stopTimer();
        return;
      }

      setState(() {
        elapsedSeconds++;
      });
    });
  }

  void stopTimer() {
    timer?.cancel();
    timer = null;
  }

  @override
  void dispose() {
    stopTimer();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WindowsColors.face,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(MinesweeperScreen.outerPadding),
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Center(
                child: SizedBox(
                  width: constraints.maxWidth,
                  child: ClassicFrame(
                    child: LayoutBuilder(
                      builder: (context, innerConstraints) {
                        final boardAreaWidth =
                            innerConstraints.maxWidth -
                            BeveledBox.borderWidth * 2;
                        final cellSize =
                            boardAreaWidth / MinesweeperScreen.columns;

                        return Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            StatusPanel(
                              mineCounter: game.remainingMineCount,
                              elapsedSeconds: elapsedSeconds,
                              status: game.status,
                              onReset: resetGame,
                            ),
                            const SizedBox(height: 8),
                            MinesweeperBoard(
                              cellSize: cellSize,
                              game: game,
                              onCellTap: revealCell,
                              onCellLongPress: toggleFlag,
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class StatusPanel extends StatelessWidget {
  const StatusPanel({
    super.key,
    required this.mineCounter,
    required this.elapsedSeconds,
    required this.status,
    required this.onReset,
  });

  final int mineCounter;
  final int elapsedSeconds;
  final GameStatus status;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    return ClassicFrame(
      inset: true,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Row(
        children: [
          SevenSegmentPlaceholder(text: CounterDisplay.format(mineCounter)),
          const Spacer(),
          GestureDetector(
            key: const Key('reset-button'),
            onTap: onReset,
            child: BeveledBox(
              width: 40,
              height: 40,
              child: CustomPaint(
                painter: SmileyPainter(status: status),
                child: const SizedBox.expand(),
              ),
            ),
          ),
          const Spacer(),
          SevenSegmentPlaceholder(text: TimerDisplay.format(elapsedSeconds)),
        ],
      ),
    );
  }
}

class SevenSegmentPlaceholder extends StatelessWidget {
  const SevenSegmentPlaceholder({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 66,
      height: 36,
      alignment: Alignment.center,
      color: Colors.black,
      child: Text(
        text,
        style: const TextStyle(
          color: Color(0xffff0000),
          fontSize: 28,
          fontWeight: FontWeight.w700,
          fontFamily: 'monospace',
          height: 1,
        ),
      ),
    );
  }
}

abstract final class CounterDisplay {
  static String format(int value) {
    final displayValue = value.clamp(-99, 999);
    if (displayValue < 0) {
      return '-${(-displayValue).toString().padLeft(2, '0')}';
    }

    return displayValue.toString().padLeft(3, '0');
  }
}

abstract final class TimerDisplay {
  static String format(int seconds) {
    return seconds.clamp(0, 999).toString().padLeft(3, '0');
  }
}

class MinesweeperBoard extends StatelessWidget {
  const MinesweeperBoard({
    super.key,
    required this.cellSize,
    required this.game,
    required this.onCellTap,
    required this.onCellLongPress,
  });

  final double cellSize;
  final MinesweeperGame game;
  final ValueChanged<int> onCellTap;
  final ValueChanged<int> onCellLongPress;

  @override
  Widget build(BuildContext context) {
    return ClassicFrame(
      inset: true,
      padding: EdgeInsets.zero,
      child: SizedBox(
        width: cellSize * MinesweeperScreen.columns,
        height: cellSize * MinesweeperScreen.rows,
        child: GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          itemCount: MinesweeperScreen.columns * MinesweeperScreen.rows,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: MinesweeperScreen.columns,
          ),
          itemBuilder: (context, index) {
            return MineTile(
              cell: game.cells[index],
              revealMines: game.status == GameStatus.lost,
              canInteract: game.status == GameStatus.playing,
              onTap: () => onCellTap(index),
              onLongPress: () => onCellLongPress(index),
            );
          },
        ),
      ),
    );
  }
}

class MineTile extends StatefulWidget {
  const MineTile({
    super.key,
    required this.cell,
    required this.revealMines,
    required this.canInteract,
    required this.onTap,
    required this.onLongPress,
  });

  final MineCell cell;
  final bool revealMines;
  final bool canInteract;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  State<MineTile> createState() => _MineTileState();
}

class _MineTileState extends State<MineTile> {
  bool isPressed = false;

  @override
  void didUpdateWidget(covariant MineTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.cell.isRevealed || !widget.canInteract) {
      isPressed = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.revealMines && widget.cell.hasMine) {
      return const RevealedMineTile.mine();
    }

    if (widget.cell.isRevealed) {
      return RevealedMineTile(cell: widget.cell);
    }

    if (!widget.canInteract) {
      return CoveredMineTile(cell: widget.cell);
    }

    return GestureDetector(
      onTap: widget.onTap,
      onLongPress: widget.onLongPress,
      onTapDown: (_) => setPressed(true),
      onTapUp: (_) => setPressed(false),
      onTapCancel: () => setPressed(false),
      onLongPressEnd: (_) => setPressed(false),
      child: CoveredMineTile(cell: widget.cell, isPressed: isPressed),
    );
  }

  void setPressed(bool value) {
    if (isPressed == value || widget.cell.isRevealed || !widget.canInteract) {
      return;
    }

    setState(() {
      isPressed = value;
    });
  }
}

class CoveredMineTile extends StatelessWidget {
  const CoveredMineTile({
    super.key,
    required this.cell,
    this.isPressed = false,
  });

  final MineCell cell;
  final bool isPressed;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 70),
      curve: Curves.easeOut,
      child: BeveledBox(
        inset: isPressed,
        child: cell.isFlagged
            ? AnimatedPadding(
                duration: const Duration(milliseconds: 70),
                curve: Curves.easeOut,
                padding: EdgeInsets.only(
                  left: isPressed ? 1 : 0,
                  top: isPressed ? 1 : 0,
                ),
                child: CustomPaint(
                  painter: const FlagPainter(),
                  child: const SizedBox.expand(),
                ),
              )
            : null,
      ),
    );
  }
}

class FlagPainter extends CustomPainter {
  const FlagPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final polePaint = Paint()
      ..color = Colors.black
      ..strokeWidth = size.shortestSide * 0.07
      ..style = PaintingStyle.stroke;
    final flagPaint = Paint()
      ..color = const Color(0xffff0000)
      ..style = PaintingStyle.fill;
    final basePaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.fill;

    final poleTop = Offset(size.width * 0.48, size.height * 0.24);
    final poleBottom = Offset(size.width * 0.48, size.height * 0.72);
    final flag = Path()
      ..moveTo(poleTop.dx, poleTop.dy)
      ..lineTo(size.width * 0.75, size.height * 0.32)
      ..lineTo(poleTop.dx, size.height * 0.44)
      ..close();
    final base = Path()
      ..moveTo(size.width * 0.32, size.height * 0.78)
      ..lineTo(size.width * 0.64, size.height * 0.78)
      ..lineTo(size.width * 0.72, size.height * 0.86)
      ..lineTo(size.width * 0.24, size.height * 0.86)
      ..close();

    canvas.drawPath(flag, flagPaint);
    canvas.drawLine(poleTop, poleBottom, polePaint);
    canvas.drawPath(base, basePaint);
  }

  @override
  bool shouldRepaint(covariant FlagPainter oldDelegate) {
    return false;
  }
}

class RevealedMineTile extends StatelessWidget {
  const RevealedMineTile({super.key, required this.cell}) : showMine = false;

  const RevealedMineTile.mine({super.key}) : cell = null, showMine = true;

  final MineCell? cell;
  final bool showMine;

  @override
  Widget build(BuildContext context) {
    final count = cell?.adjacentMineCount ?? 0;

    return Container(
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: WindowsColors.face,
        border: Border.all(color: WindowsColors.shadow),
      ),
      child: showMine
          ? CustomPaint(
              painter: const MinePainter(),
              child: const SizedBox.expand(),
            )
          : count > 0
          ? Text(
              '$count',
              style: TextStyle(
                color: MineNumberColors.colorFor(count),
                fontSize: 18,
                fontWeight: FontWeight.w800,
                height: 1,
              ),
            )
          : null,
    );
  }
}

class MinePainter extends CustomPainter {
  const MinePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.shortestSide * 0.22;
    final spikePaint = Paint()
      ..color = Colors.black
      ..strokeWidth = size.shortestSide * 0.055
      ..strokeCap = StrokeCap.square;
    final minePaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.fill;
    final shinePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    for (var index = 0; index < 8; index++) {
      final angle = pi / 4 * index;
      final start = Offset(
        center.dx + cos(angle) * radius * 0.75,
        center.dy + sin(angle) * radius * 0.75,
      );
      final end = Offset(
        center.dx + cos(angle) * radius * 1.55,
        center.dy + sin(angle) * radius * 1.55,
      );
      canvas.drawLine(start, end, spikePaint);
    }

    canvas.drawCircle(center, radius, minePaint);
    canvas.drawCircle(
      Offset(center.dx - radius * 0.35, center.dy - radius * 0.35),
      radius * 0.18,
      shinePaint,
    );
  }

  @override
  bool shouldRepaint(covariant MinePainter oldDelegate) {
    return false;
  }
}

class ClassicFrame extends StatelessWidget {
  const ClassicFrame({
    super.key,
    required this.child,
    this.inset = false,
    this.padding = const EdgeInsets.all(8),
  });

  final Widget child;
  final bool inset;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return BeveledBox(inset: inset, padding: padding, child: child);
  }
}

class BeveledBox extends StatelessWidget {
  const BeveledBox({
    super.key,
    this.child,
    this.width,
    this.height,
    this.inset = false,
    this.padding = EdgeInsets.zero,
  });

  final Widget? child;
  final double? width;
  final double? height;
  final bool inset;
  final EdgeInsetsGeometry padding;

  static const double borderWidth = 2;

  @override
  Widget build(BuildContext context) {
    final light = inset ? WindowsColors.shadow : WindowsColors.highlight;
    final dark = inset ? WindowsColors.highlight : WindowsColors.shadow;
    final secondaryLight = inset
        ? WindowsColors.darkShadow
        : WindowsColors.lightEdge;
    final secondaryDark = inset
        ? WindowsColors.lightEdge
        : WindowsColors.darkShadow;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 70),
      curve: Curves.easeOut,
      width: width,
      height: height,
      padding: padding,
      decoration: BoxDecoration(
        color: WindowsColors.face,
        border: Border(
          top: BorderSide(color: light, width: borderWidth),
          left: BorderSide(color: light, width: borderWidth),
          right: BorderSide(color: dark, width: borderWidth),
          bottom: BorderSide(color: dark, width: borderWidth),
        ),
      ),
      child: CustomPaint(
        foregroundPainter: BevelEdgePainter(
          topLeft: secondaryLight,
          bottomRight: secondaryDark,
        ),
        child: child,
      ),
    );
  }
}

class BevelEdgePainter extends CustomPainter {
  const BevelEdgePainter({required this.topLeft, required this.bottomRight});

  final Color topLeft;
  final Color bottomRight;

  @override
  void paint(Canvas canvas, Size size) {
    final topLeftPaint = Paint()
      ..color = topLeft
      ..strokeWidth = 1;
    final bottomRightPaint = Paint()
      ..color = bottomRight
      ..strokeWidth = 1;

    canvas.drawLine(
      const Offset(1, 1),
      Offset(size.width - 2, 1),
      topLeftPaint,
    );
    canvas.drawLine(
      const Offset(1, 1),
      Offset(1, size.height - 2),
      topLeftPaint,
    );
    canvas.drawLine(
      Offset(1, size.height - 1),
      Offset(size.width - 1, size.height - 1),
      bottomRightPaint,
    );
    canvas.drawLine(
      Offset(size.width - 1, 1),
      Offset(size.width - 1, size.height - 1),
      bottomRightPaint,
    );
  }

  @override
  bool shouldRepaint(covariant BevelEdgePainter oldDelegate) {
    return topLeft != oldDelegate.topLeft ||
        bottomRight != oldDelegate.bottomRight;
  }
}

class SmileyPainter extends CustomPainter {
  const SmileyPainter({required this.status});

  final GameStatus status;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.shortestSide * 0.32;

    final facePaint = Paint()
      ..color = const Color(0xffffff00)
      ..style = PaintingStyle.fill;
    final outlinePaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final featurePaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, radius, facePaint);
    canvas.drawCircle(center, radius, outlinePaint);
    if (status == GameStatus.won) {
      _drawSunglasses(canvas, center, radius, featurePaint);
    } else {
      canvas.drawCircle(
        Offset(center.dx - radius * 0.38, center.dy - radius * 0.25),
        radius * 0.11,
        featurePaint,
      );
      canvas.drawCircle(
        Offset(center.dx + radius * 0.38, center.dy - radius * 0.25),
        radius * 0.11,
        featurePaint,
      );
    }

    final smile = Path()
      ..moveTo(center.dx - radius * 0.45, center.dy + radius * 0.18)
      ..quadraticBezierTo(
        center.dx,
        center.dy + radius * 0.58,
        center.dx + radius * 0.45,
        center.dy + radius * 0.18,
      );
    canvas.drawPath(smile, outlinePaint);
  }

  void _drawSunglasses(
    Canvas canvas,
    Offset center,
    double radius,
    Paint featurePaint,
  ) {
    final lensSize = Size(radius * 0.48, radius * 0.26);
    final leftLens = Rect.fromCenter(
      center: Offset(center.dx - radius * 0.3, center.dy - radius * 0.25),
      width: lensSize.width,
      height: lensSize.height,
    );
    final rightLens = Rect.fromCenter(
      center: Offset(center.dx + radius * 0.3, center.dy - radius * 0.25),
      width: lensSize.width,
      height: lensSize.height,
    );

    canvas.drawRect(leftLens, featurePaint);
    canvas.drawRect(rightLens, featurePaint);
    canvas.drawLine(
      Offset(leftLens.right, leftLens.center.dy),
      Offset(rightLens.left, rightLens.center.dy),
      featurePaint..strokeWidth = 1.5,
    );
  }

  @override
  bool shouldRepaint(covariant SmileyPainter oldDelegate) {
    return status != oldDelegate.status;
  }
}

enum GameStatus { playing, won, lost }

class MinesweeperGame {
  MinesweeperGame({
    this.columns = MinesweeperScreen.columns,
    this.rows = MinesweeperScreen.rows,
    this.mineCount = MinesweeperScreen.mineCount,
    Random? random,
  }) {
    _validateDimensions();
    _startWithRandomMines(random ?? Random());
  }

  MinesweeperGame.withMines({
    this.columns = MinesweeperScreen.columns,
    this.rows = MinesweeperScreen.rows,
    required Set<int> mineIndexes,
  }) : mineCount = mineIndexes.length {
    _validateDimensions();
    _startWithMines(mineIndexes);
  }

  final int columns;
  final int rows;
  final int mineCount;

  late List<MineCell> cells;
  GameStatus status = GameStatus.playing;

  int _revealedSafeCells = 0;
  int _flaggedCells = 0;

  int get totalCells => columns * rows;
  int get flaggedCount => _flaggedCells;
  int get remainingMineCount => mineCount - flaggedCount;

  bool canReveal(int index) {
    RangeError.checkValidIndex(index, cells);

    return status == GameStatus.playing &&
        !cells[index].isRevealed &&
        !cells[index].isFlagged;
  }

  bool reveal(int index) {
    if (!canReveal(index)) {
      return false;
    }

    final cell = cells[index];
    if (cell.hasMine) {
      cell.isRevealed = true;
      _revealAllMines();
      status = GameStatus.lost;
      return true;
    }

    _revealSafeArea(index);
    if (_hasRevealedEverySafeCell) {
      status = GameStatus.won;
    }

    return true;
  }

  void toggleFlag(int index) {
    RangeError.checkValidIndex(index, cells);

    if (status != GameStatus.playing || cells[index].isRevealed) {
      return;
    }

    final cell = cells[index];
    cell.isFlagged = !cell.isFlagged;
    _flaggedCells += cell.isFlagged ? 1 : -1;
  }

  bool get _hasRevealedEverySafeCell {
    return _revealedSafeCells == totalCells - mineCount;
  }

  void _startWithRandomMines(Random random) {
    final indexes = List<int>.generate(totalCells, (index) => index)
      ..shuffle(random);
    _startWithMines(indexes.take(mineCount).toSet());
  }

  void _startWithMines(Set<int> mineIndexes) {
    if (mineIndexes.length != mineCount) {
      throw ArgumentError.value(
        mineIndexes,
        'mineIndexes',
        'must contain exactly $mineCount unique mines',
      );
    }

    for (final index in mineIndexes) {
      RangeError.checkValueInInterval(index, 0, totalCells - 1, 'mineIndexes');
    }

    cells = List<MineCell>.generate(
      totalCells,
      (index) => MineCell(hasMine: mineIndexes.contains(index)),
    );
    status = GameStatus.playing;
    _revealedSafeCells = 0;
    _flaggedCells = 0;

    for (var index = 0; index < totalCells; index++) {
      if (!cells[index].hasMine) {
        cells[index].adjacentMineCount = neighborIndexes(index)
            .where((neighbor) => cells[neighbor].hasMine)
            .length;
      }
    }
  }

  void _validateDimensions() {
    if (columns <= 0 || rows <= 0) {
      throw ArgumentError('Board dimensions must be positive.');
    }

    final cellCount = columns * rows;
    if (mineCount < 0 || mineCount >= cellCount) {
      throw ArgumentError.value(
        mineCount,
        'mineCount',
        'must be between 0 and ${cellCount - 1}',
      );
    }
  }

  Iterable<int> neighborIndexes(int index) sync* {
    RangeError.checkValidIndex(index, cells);

    final row = index ~/ columns;
    final column = index % columns;

    for (var rowOffset = -1; rowOffset <= 1; rowOffset++) {
      for (var columnOffset = -1; columnOffset <= 1; columnOffset++) {
        if (rowOffset == 0 && columnOffset == 0) {
          continue;
        }

        final neighborRow = row + rowOffset;
        final neighborColumn = column + columnOffset;
        final isInBounds =
            neighborRow >= 0 &&
            neighborRow < rows &&
            neighborColumn >= 0 &&
            neighborColumn < columns;

        if (isInBounds) {
          yield neighborRow * columns + neighborColumn;
        }
      }
    }
  }

  void _revealSafeArea(int startIndex) {
    final queue = <int>[startIndex];
    var queueIndex = 0;

    while (queueIndex < queue.length) {
      final index = queue[queueIndex];
      queueIndex++;

      final cell = cells[index];
      if (cell.isRevealed || cell.isFlagged || cell.hasMine) {
        continue;
      }

      cell.isRevealed = true;
      _revealedSafeCells++;

      if (cell.adjacentMineCount != 0) {
        continue;
      }

      for (final neighbor in neighborIndexes(index)) {
        final neighborCell = cells[neighbor];
        if (!neighborCell.isRevealed &&
            !neighborCell.isFlagged &&
            !neighborCell.hasMine) {
          queue.add(neighbor);
        }
      }
    }
  }

  void _revealAllMines() {
    for (final cell in cells) {
      if (cell.hasMine) {
        cell.isRevealed = true;
      }
    }
  }
}

class MineCell {
  MineCell({required this.hasMine});

  final bool hasMine;
  int adjacentMineCount = 0;
  bool isRevealed = false;
  bool isFlagged = false;
}

abstract final class MineNumberColors {
  static Color colorFor(int count) {
    return switch (count) {
      1 => const Color(0xff0000ff),
      2 => const Color(0xff008000),
      3 => const Color(0xffff0000),
      4 => const Color(0xff000080),
      5 => const Color(0xff800000),
      6 => const Color(0xff008080),
      7 => Colors.black,
      _ => const Color(0xff808080),
    };
  }
}

abstract final class WindowsColors {
  static const face = Color(0xffc0c0c0);
  static const highlight = Color(0xffffffff);
  static const lightEdge = Color(0xffdfdfdf);
  static const shadow = Color(0xff808080);
  static const darkShadow = Color(0xff404040);
}
