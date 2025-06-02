import 'package:flutter/material.dart';
import 'dart:async';
import 'main.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _fadeAnimationController;
  late Animation<double> _fadeAnimation;
  
  // Additional controller for pulsing effect
  late AnimationController _pulseAnimationController;
  late Animation<double> _pulseAnimation;

  // Progress indicator value
  double _progressValue = 0.0;
  late Timer _progressTimer;

  @override
  void initState() {
    super.initState();
    
    // Initialize fade animation controller
    _fadeAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    // Create fade-in animation
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _fadeAnimationController,
        curve: Curves.easeInOutCirc,
      ),
    );
    
    // Initialize pulse animation controller
    _pulseAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    // Create pulsing animation
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(
        parent: _pulseAnimationController,
        curve: Curves.elasticIn,
      ),
    );
    
    // Setup repeating pulse
    _pulseAnimationController.repeat(reverse: true);
    
    // Start the fade animation
    _fadeAnimationController.forward();
    
    // Setup progress timer
    _progressTimer = Timer.periodic(const Duration(milliseconds: 5000), (timer) {
      setState(() {
        if (_progressValue < 1.0) {
          _progressValue += 0.04; // Increment to reach 1.0 in about 2.5 seconds
        } else {
          _progressTimer.cancel();
        }
      });
    });
    
    // Navigate to main layout after animation completes
    Timer(const Duration(milliseconds: 5000), () {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const MainLayout()),
      );
    });
  }

  @override
  void dispose() {
    _fadeAnimationController.dispose();
    _pulseAnimationController.dispose();
    _progressTimer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Animated logo
              ScaleTransition(
                scale: _pulseAnimation,
                child: Center(
                  child: Container(
                    width: MediaQuery.of(context).size.width * 0.4,
                    height: MediaQuery.of(context).size.width * 0.2,
                    // decoration: BoxDecoration(
                    //   color: colorScheme.primary,
                    //   borderRadius: BorderRadius.circular(20),
                      // boxShadow: [
                      //   BoxShadow(
                      //     color: colorScheme.primary.withOpacity(0.3),
                      //     blurRadius: 15,
                      //     offset: const Offset(0, 8),
                      //   ),
                      // ],
                    // ),
                    child: Center(
                      child: Image.asset(
                        'assets/logo.png', // Replace with your logo asset
                        width: MediaQuery.of(context).size.width * 0.4,
                        height: MediaQuery.of(context).size.width * 0.2,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 40),
              // App name with improved typography
              Text(
                '',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'powered by Team 17',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 40),
              // Progress indicator
              // SizedBox(
              //   width: 200,
              //   child: LinearProgressIndicator(
              //     value: _progressValue,
              //     backgroundColor: colorScheme.surfaceVariant,
              //     color: colorScheme.secondary,
              //     borderRadius: BorderRadius.circular(4),
              //     minHeight: 6,
              //   ),
              // ),
              // const SizedBox(height: 16),
              // Text(
              //   'Loading...',
              //   style: TextStyle(
              //     color: colorScheme.onBackground.withOpacity(0.6),
              //   ),
              // ),
            ],
          ),
        ),
      ),
    );
  }
}