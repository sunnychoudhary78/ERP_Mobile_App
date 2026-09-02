import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../theme/app_theme.dart';

class SplashLoadingScreen extends StatelessWidget {
  const SplashLoadingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 220,
              height: 220,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                        width: 164,
                        height: 164,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.accent.withValues(alpha: 0.18),
                              blurRadius: 44,
                              spreadRadius: 10,
                            ),
                            BoxShadow(
                              color: const Color(
                                0xFFE91E63,
                              ).withValues(alpha: 0.1),
                              blurRadius: 58,
                              spreadRadius: 6,
                            ),
                          ],
                        ),
                      )
                      .animate(
                        onPlay: (controller) =>
                            controller.repeat(reverse: true),
                      )
                      .scale(
                        begin: const Offset(0.88, 0.88),
                        end: const Offset(1.08, 1.08),
                        duration: 2800.ms,
                        curve: Curves.easeInOut,
                      )
                      .fade(begin: 0.5, end: 1, duration: 2800.ms),
                  Image.asset('assets/logo.png', width: 180, height: 180)
                      .animate()
                      .fadeIn(duration: 1100.ms, curve: Curves.easeOut)
                      .scale(
                        begin: const Offset(0.45, 0.45),
                        end: const Offset(1, 1),
                        duration: 1400.ms,
                        curve: Curves.easeOutBack,
                      )
                      .then(delay: 700.ms)
                      .shimmer(
                        duration: 1800.ms,
                        color: Colors.white.withValues(alpha: 0.75),
                      ),
                ],
              ),
            ).animate().slideY(
              begin: 0.1,
              end: 0,
              duration: 1200.ms,
              curve: Curves.easeOutCubic,
            ),
            const SizedBox(height: 2),
            Text(
                  'IMMORTAL',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2,
                    color: AppColors.primary,
                  ),
                )
                .animate()
                .fadeIn(delay: 1000.ms, duration: 800.ms)
                .slideY(
                  begin: 0.25,
                  end: 0,
                  delay: 1000.ms,
                  duration: 800.ms,
                  curve: Curves.easeOutCubic,
                ),
            const SizedBox(height: 3),
            Text(
                  'ERP',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.accent,
                    letterSpacing: 6,
                  ),
                )
                .animate()
                .fadeIn(delay: 1500.ms, duration: 700.ms)
                .slideY(
                  begin: 0.2,
                  end: 0,
                  delay: 1500.ms,
                  duration: 700.ms,
                  curve: Curves.easeOutCubic,
                ),
            const SizedBox(height: 28),
            const SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(strokeWidth: 2.5),
                )
                .animate()
                .fadeIn(delay: 2300.ms, duration: 600.ms)
                .scale(
                  begin: const Offset(0.7, 0.7),
                  end: const Offset(1, 1),
                  delay: 2300.ms,
                  duration: 600.ms,
                  curve: Curves.easeOutBack,
                ),
          ],
        ),
      ),
    );
  }
}
