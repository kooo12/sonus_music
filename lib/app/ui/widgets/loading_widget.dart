import 'package:flutter/material.dart';
import 'package:music_player/app/ui/theme/app_colors.dart';

class LoadingWidget extends StatefulWidget {
  final double size;
  final Color? color;
  final int dotCount;
  final Duration duration;

  const LoadingWidget({
    super.key,
    this.size = 25.0,
    this.color,
    this.dotCount = 3,
    this.duration = const Duration(milliseconds: 900),
  });

  @override
  State<LoadingWidget> createState() => _LoadingWidgetState();
}

class _LoadingWidgetState extends State<LoadingWidget>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _animations;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      widget.dotCount,
      (index) => AnimationController(
        duration: widget.duration,
        vsync: this,
      ),
    );

    _animations = _controllers.map((controller) {
      return Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(
          parent: controller,
          curve: Curves.easeOutCubic,
        ),
      );
    }).toList();

    for (var i = 0; i < widget.dotCount; i++) {
      Future.delayed(Duration(milliseconds: i * 150), () {
        if (mounted) {
          _controllers[i].repeat(reverse: true);
        }
      });
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        height: widget.size,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            widget.dotCount,
            (index) => _buildAnimatedDot(index),
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedDot(int index) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: widget.size / 10),
      child: AnimatedBuilder(
        animation: _animations[index],
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, -_animations[index].value * (widget.size / 2.5)),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: widget.size / 4,
                  height: widget.size / 4,
                  decoration: BoxDecoration(
                    color: (widget.color ?? TpsColors.white).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(widget.size / 8),
                  ),
                ),
                Container(
                  width: (widget.size / 4) * _animations[index].value,
                  height: (widget.size / 4) * _animations[index].value,
                  decoration: BoxDecoration(
                    color: widget.color ?? TpsColors.white,
                    borderRadius: BorderRadius.circular(
                        (widget.size / 8) * _animations[index].value),
                    boxShadow: [
                      BoxShadow(
                        color:
                            (widget.color ?? TpsColors.white).withOpacity(0.4),
                        blurRadius: widget.size / 6,
                        spreadRadius: widget.size / 25,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
