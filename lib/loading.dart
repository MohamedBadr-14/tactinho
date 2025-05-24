import 'package:flutter/material.dart';

class LoadingAnimation extends StatefulWidget {
  final double width;
  final double height;
  final bool loop;
  final Duration frameDuration;
  final String imagePrefix;
  final String imageExtension;
  final int frameCount;
  final bool in_tactics;

  const LoadingAnimation({
    super.key,
    required this.width,
    required this.height,
    this.loop = true,
    this.frameDuration = const Duration(milliseconds: 100), // ~30fps
    required this.imagePrefix,
    this.imageExtension = '.png',
    required this.frameCount,
    required this.in_tactics,
  });

  @override
  State<LoadingAnimation> createState() => _LoadingAnimationState();
}

class _LoadingAnimationState extends State<LoadingAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<Image> _images;
  int _currentFrame = 0;

  @override
  void initState() {
    super.initState();

    // Preload all images
    _preloadImages();

    // Setup animation controller
    _controller = AnimationController(
      vsync: this,
      duration: widget.frameDuration,
    );

    _controller.addListener(_updateFrame);
    _controller.addStatusListener(_onAnimationStatusChanged);

    // Start the animation
    _controller.forward();
  }

  void _preloadImages() {
    _images = List.generate(
      widget.frameCount,
      (index) => Image.asset(
        '${widget.imagePrefix}${(index + 1).toString()}${widget.imageExtension}',
        width: widget.width,
        height: widget.height,
        gaplessPlayback: true,
      ),
    );
  }

  void _updateFrame() {
    if (_controller.value == 1.0) {
      setState(() {
        _currentFrame = (_currentFrame + 1) % widget.frameCount;
      });

      _controller.reset();
      _controller.forward();
    }
  }

  void _onAnimationStatusChanged(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      if (_currentFrame == widget.frameCount - 1 && !widget.loop) {
        // Animation completed and no loop requested
        _controller.stop();
      } else {
        _controller.reset();
        _controller.forward();
      }
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_updateFrame);
    _controller.removeStatusListener(_onAnimationStatusChanged);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
        width: widget.width,
        height: widget.height,
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          _images[_currentFrame],
          // widget.in_tactics ? const SizedBox(height: 20) : const SizedBox(),  
          widget.in_tactics ? const  Text(
            'Loading...',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ) : const SizedBox(),
        ]));
  }
}

// Example implementation:
class LoadingScreen extends StatelessWidget {
  const LoadingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.black, // Or any color that matches your design
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            LoadingAnimation(
              width: 300,
              height: 300,
              frameCount: 35,
              imagePrefix: 'assets/out2/load_',
              imageExtension: '.png',
              in_tactics: false,
              loop: true,
            ),
            SizedBox(height: 20),
            Text(
              'Loading...',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
