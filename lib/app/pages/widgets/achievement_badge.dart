import 'package:flutter/material.dart';
import '../../data/models/achievement_model.dart';

class AchievementBadge extends StatelessWidget {
  final AchievementBadgeType type;
  final AchievementRarity rarity;
  final String iconEmoji;
  final double size;

  const AchievementBadge({
    super.key,
    required this.type,
    required this.rarity,
    required this.iconEmoji,
    this.size = 120,
  });

  @override
  Widget build(BuildContext context) {
    switch (type) {
      case AchievementBadgeType.star:
        return _StarBadge(rarity: rarity, iconEmoji: iconEmoji, size: size);
      case AchievementBadgeType.shield:
        return _ShieldBadge(rarity: rarity, iconEmoji: iconEmoji, size: size);
      case AchievementBadgeType.hexagon:
        return _HexagonBadge(rarity: rarity, iconEmoji: iconEmoji, size: size);
      case AchievementBadgeType.medal:
        return _MedalBadge(rarity: rarity, iconEmoji: iconEmoji, size: size);
    }
  }
}

Color _rarityColor(AchievementRarity rarity) {
  switch (rarity) {
    case AchievementRarity.common:
      return const Color(0xFF6C63FF);
    case AchievementRarity.rare:
      return const Color(0xFF4A90E2);
    case AchievementRarity.epic:
      return const Color(0xFF9B59B6);
    case AchievementRarity.legendary:
      return const Color(0xFFFFD700);
  }
}

class _StarBadge extends StatelessWidget {
  final AchievementRarity rarity;
  final String iconEmoji;
  final double size;

  const _StarBadge({
    required this.rarity,
    required this.iconEmoji,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    final color = _rarityColor(rarity);
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Star shape using layered rotated squares
          Transform.rotate(
            angle: 0.4,
            child: Container(
              width: size * 0.9,
              height: size * 0.9,
              decoration: BoxDecoration(
                color: color.withOpacity(0.25),
                borderRadius: BorderRadius.circular(size * 0.12),
                border: Border.all(color: color, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.5),
                    blurRadius: 20,
                    spreadRadius: 4,
                  ),
                ],
              ),
            ),
          ),
          Transform.rotate(
            angle: -0.4,
            child: Container(
              width: size * 0.75,
              height: size * 0.75,
              decoration: BoxDecoration(
                color: color.withOpacity(0.35),
                borderRadius: BorderRadius.circular(size * 0.12),
                border: Border.all(color: color, width: 2),
              ),
            ),
          ),
          // Center circle
          Container(
            width: size * 0.65,
            height: size * 0.65,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [color.withOpacity(0.9), color.withOpacity(0.5)],
              ),
              border:
                  Border.all(color: Colors.white.withOpacity(0.8), width: 2),
            ),
            child: Center(
              child: Text(
                iconEmoji,
                style: TextStyle(
                  fontSize: size * 0.34,
                  color: Colors.white,
                  shadows: const [Shadow(color: Colors.black45, blurRadius: 4)],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ShieldBadge extends StatelessWidget {
  final AchievementRarity rarity;
  final String iconEmoji;
  final double size;
  const _ShieldBadge({
    required this.rarity,
    required this.iconEmoji,
    required this.size,
  });
  @override
  Widget build(BuildContext context) {
    final color = _rarityColor(rarity);
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: size * 0.8,
            height: size * 0.95,
            decoration: BoxDecoration(
              color: color.withOpacity(0.25),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(size * 0.2),
                topRight: Radius.circular(size * 0.2),
                bottomLeft: Radius.circular(size * 0.1),
                bottomRight: Radius.circular(size * 0.1),
              ),
              border: Border.all(color: color, width: 2),
              boxShadow: [
                BoxShadow(
                    color: color.withOpacity(0.5),
                    blurRadius: 20,
                    spreadRadius: 4),
              ],
            ),
          ),
          Container(
            width: size * 0.6,
            height: size * 0.75,
            decoration: BoxDecoration(
              color: color.withOpacity(0.35),
              borderRadius: BorderRadius.circular(size * 0.12),
              border: Border.all(color: color, width: 1.8),
            ),
            child: Center(
              child: Text(
                iconEmoji,
                style: TextStyle(
                  fontSize: size * 0.32,
                  color: Colors.white,
                  shadows: const [Shadow(color: Colors.black45, blurRadius: 4)],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HexagonBadge extends StatelessWidget {
  final AchievementRarity rarity;
  final String iconEmoji;
  final double size;
  const _HexagonBadge({
    required this.rarity,
    required this.iconEmoji,
    required this.size,
  });
  @override
  Widget build(BuildContext context) {
    final color = _rarityColor(rarity);
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          _Hexagon(
              size: size * 0.9,
              color: color.withOpacity(0.25),
              border: Border.all(color: color, width: 2)),
          _Hexagon(
              size: size * 0.7,
              color: color.withOpacity(0.35),
              border: Border.all(color: color, width: 1.8)),
          Container(
            width: size * 0.55,
            height: size * 0.55,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                  colors: [color.withOpacity(0.9), color.withOpacity(0.5)]),
              border:
                  Border.all(color: Colors.white.withOpacity(0.8), width: 2),
            ),
            child: Center(
              child: Text(
                iconEmoji,
                style: TextStyle(
                  fontSize: size * 0.3,
                  color: Colors.white,
                  shadows: const [Shadow(color: Colors.black45, blurRadius: 4)],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Hexagon extends StatelessWidget {
  final double size;
  final Color color;
  final BoxBorder? border;
  const _Hexagon({required this.size, required this.color, this.border});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _HexagonPainter(color: color, border: border),
    );
  }
}

class _HexagonPainter extends CustomPainter {
  final Color color;
  final BoxBorder? border;
  _HexagonPainter({required this.color, this.border});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = Path();
    final w = size.width;
    final h = size.height;
    path.moveTo(w * 0.5, 0);
    path.lineTo(w, h * 0.25);
    path.lineTo(w, h * 0.75);
    path.lineTo(w * 0.5, h);
    path.lineTo(0, h * 0.75);
    path.lineTo(0, h * 0.25);
    path.close();
    canvas.drawPath(path, paint);

    if (border is Border) {
      final b = (border as Border).top;
      final stroke = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = b.width
        ..color = b.color;
      canvas.drawPath(path, stroke);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _MedalBadge extends StatelessWidget {
  final AchievementRarity rarity;
  final String iconEmoji;
  final double size;
  const _MedalBadge({
    required this.rarity,
    required this.iconEmoji,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    final color = _rarityColor(rarity);
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          // Ribbons
          Positioned(
            top: 0,
            child: Row(
              children: [
                Container(
                    width: size * 0.18,
                    height: size * 0.35,
                    color: color.withOpacity(0.9)),
                const SizedBox(width: 6),
                Container(
                    width: size * 0.18,
                    height: size * 0.35,
                    color: color.withOpacity(0.6)),
              ],
            ),
          ),
          // Medal circle
          Positioned(
            top: size * 0.22,
            child: Container(
              width: size * 0.72,
              height: size * 0.72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                    colors: [color.withOpacity(0.95), color.withOpacity(0.55)]),
                border:
                    Border.all(color: Colors.white.withOpacity(0.8), width: 2),
                boxShadow: [
                  BoxShadow(
                      color: color.withOpacity(0.5),
                      blurRadius: 20,
                      spreadRadius: 4),
                ],
              ),
              child: Center(
                child: Text(
                  iconEmoji,
                  style: TextStyle(
                    fontSize: size * 0.32,
                    color: Colors.white,
                    shadows: const [
                      Shadow(color: Colors.black45, blurRadius: 4)
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
