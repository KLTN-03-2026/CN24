import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ride_now_khoaluan/controllers/auth_controller.dart';
import 'package:ride_now_khoaluan/routes/app_routes.dart';

void main() {
  runApp(
    MaterialApp(debugShowCheckedModeBanner: false, home: SmartRideScreen()),
  );
}

class SmartRideScreen extends StatefulWidget {
  @override
  _SmartRideScreenState createState() => _SmartRideScreenState();
}

class _SmartRideScreenState extends State<SmartRideScreen>
    with TickerProviderStateMixin {
  late AnimationController _progressController;
  late AnimationController _waveController;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();

    _progressController = AnimationController(
      duration: Duration(seconds: 2),
      vsync: this,
    );

    _waveController = AnimationController(
      duration: Duration(seconds: 3),
      vsync: this,
    )..repeat();

    _progressAnimation = Tween<double>(begin: 0.0, end: 1).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.easeInOut),
    );

    // Start animations
    _progressController.forward();
    _progressController.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        // Kiểm tra nếu user đã đăng nhập thì vào main, chưa thì vào onboarding
        final authController = Get.find<AuthController>();
        if (authController.isAuthenticated) {
          Get.offAllNamed(AppRoutes.main);
        } else {
          Get.offAllNamed(AppRoutes.onboarding);
        }
      }
    });
  }

  @override
  void dispose() {
    _progressController.dispose();
    _waveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F5F5),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo Container
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Color(0xFFE3F2FD),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withOpacity(0.1),
                      blurRadius: 20,
                      offset: Offset(0, 10),
                    ),
                  ],
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Animated circles around the logo
                    AnimatedBuilder(
                      animation: _waveController,
                      builder: (context, child) {
                        return CustomPaint(
                          size: Size(120, 120),
                          painter: WaveCirclePainter(_waveController.value),
                        );
                      },
                    ),
                    // Main network icon
                    Icon(
                      Icons.hub_outlined,
                      size: 40,
                      color: Color(0xFF2196F3),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 40),

              // Title
              Text(
                'Smart Ride',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF333333),
                ),
              ),

              SizedBox(height: 8),

              // Subtitle
              Text(
                'AI POWERED TRANSPORTATION',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF2196F3),
                  letterSpacing: 2,
                ),
              ),

              SizedBox(height: 60),

              // Progress section
              Text(
                'INITIALIZING NEURAL PATHS',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF666666),
                  letterSpacing: 1,
                ),
              ),

              SizedBox(height: 16),

              // Progress bar with percentage
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: AnimatedBuilder(
                      animation: _progressAnimation,
                      builder: (context, child) {
                        return Container(
                          height: 8,
                          decoration: BoxDecoration(
                            color: Color(0xFFE0E0E0),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: FractionallySizedBox(
                            alignment: Alignment.centerLeft,
                            widthFactor: _progressAnimation.value,
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Color(0xFF1976D2),
                                    Color(0xFF2196F3),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  SizedBox(width: 16),
                  AnimatedBuilder(
                    animation: _progressAnimation,
                    builder: (context, child) {
                      return Text(
                        '${(_progressAnimation.value * 100).round()}%',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2196F3),
                        ),
                      );
                    },
                  ),
                ],
              ),

              SizedBox(height: 80),

              // Bottom wave visualization
              AnimatedBuilder(
                animation: _waveController,
                builder: (context, child) {
                  return CustomPaint(
                    size: Size(MediaQuery.of(context).size.width - 40, 60),
                    painter: WaveVisualizationPainter(_waveController.value),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Custom painter for wave circles around logo
class WaveCirclePainter extends CustomPainter {
  final double animation;

  WaveCirclePainter(this.animation);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final center = Offset(size.width / 2, size.height / 2);

    // Draw animated circles
    for (int i = 0; i < 3; i++) {
      final radius = 30 + (i * 15) + (animation * 20);
      final opacity = (1 - animation) * (1 - i * 0.3);

      paint.color = Color(0xFF2196F3).withOpacity(opacity.clamp(0.0, 0.5));
      canvas.drawCircle(center, radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// Custom painter for bottom wave visualization
class WaveVisualizationPainter extends CustomPainter {
  final double animation;

  WaveVisualizationPainter(this.animation);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Color(0xFF2196F3).withOpacity(0.3)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    final barWidth = size.width / 15;

    for (int i = 0; i < 15; i++) {
      final x = i * barWidth + barWidth / 2;
      final baseHeight = 10;
      final animatedHeight =
          baseHeight +
          (30 * (0.5 + 0.5 * math.sin((animation * 4 * math.pi) + (i * 0.5))));

      final y1 = size.height - animatedHeight;
      final y2 = size.height;

      canvas.drawLine(Offset(x, y1), Offset(x, y2), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
