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

class MinesweeperScreen extends StatelessWidget {
  const MinesweeperScreen({super.key});

  static const int columns = 10;
  static const int rows = 20;
  static const double outerPadding = 12;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WindowsColors.face,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(outerPadding),
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
                        final cellSize = boardAreaWidth / columns;

                        return Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const StatusPanel(),
                            const SizedBox(height: 8),
                            MinesweeperBoard(cellSize: cellSize),
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
  const StatusPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return ClassicFrame(
      inset: true,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Row(
        children: [
          const SevenSegmentPlaceholder(text: '010'),
          const Spacer(),
          BeveledBox(
            width: 40,
            height: 40,
            child: CustomPaint(
              painter: SmileyPainter(),
              child: const SizedBox.expand(),
            ),
          ),
          const Spacer(),
          const SevenSegmentPlaceholder(text: '000'),
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

class MinesweeperBoard extends StatelessWidget {
  const MinesweeperBoard({super.key, required this.cellSize});

  final double cellSize;

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
            return const MineTile();
          },
        ),
      ),
    );
  }
}

class MineTile extends StatelessWidget {
  const MineTile({super.key});

  @override
  Widget build(BuildContext context) {
    return const BeveledBox();
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

    return Container(
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
      child: child,
    );
  }
}

class SmileyPainter extends CustomPainter {
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

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}

abstract final class WindowsColors {
  static const face = Color(0xffc0c0c0);
  static const highlight = Color(0xffffffff);
  static const shadow = Color(0xff808080);
}
