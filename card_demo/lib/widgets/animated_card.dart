import 'package:flutter/material.dart';
import '../models/card_state.dart';

class AnimatedCard extends StatefulWidget {
  final CardData cardData;
  final VoidCallback onTap;
  final Function(bool) onHover;

  const AnimatedCard({
    super.key,
    required this.cardData,
    required this.onTap,
    required this.onHover,
  });

  @override
  State<AnimatedCard> createState() => _AnimatedCardState();
}

class _AnimatedCardState extends State<AnimatedCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _positionAnimation;
  late Animation<double> _rotationAnimation;
  late Animation<double> _scaleAnimation;

  Offset _currentPosition = Offset.zero;
  double _currentRotation = 0.0;
  double _currentScale = 1.0;
  bool _isHovering = false;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _initializeAnimations();
    _updateAnimationTargets();
  }

  void _initializeAnimations() {
    // Use spring-like curve for physics feel
    final springCurve = Curves.elasticOut;

    _positionAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: springCurve));

    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));

    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.bounceOut));

    _controller.addListener(() {
      if (mounted) {
        setState(() {
          // Interpolate between current and target positions
          _currentPosition =
              Offset.lerp(
                _currentPosition,
                widget.cardData.position,
                _positionAnimation.value,
              ) ??
              widget.cardData.position;

          _currentRotation = _lerpDouble(
            _currentRotation,
            widget.cardData.rotation,
            _rotationAnimation.value,
          );

          _currentScale = _lerpDouble(
            _currentScale,
            widget.cardData.scale,
            _scaleAnimation.value,
          );
        });
      }
    });
  }

  double _lerpDouble(double a, double b, double t) {
    return a + (b - a) * t;
  }

  void _updateAnimationTargets() {
    _controller.reset();
    _controller.forward();
  }

  @override
  void didUpdateWidget(AnimatedCard oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Update animations when card data changes
    if (oldWidget.cardData.position != widget.cardData.position ||
        oldWidget.cardData.rotation != widget.cardData.rotation ||
        oldWidget.cardData.scale != widget.cardData.scale) {
      _updateAnimationTargets();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: _currentPosition.dx - CardState.cardSize / 2,
      top: _currentPosition.dy - CardState.cardSize / 2,
      child: MouseRegion(
        onEnter: (_) {
          setState(() => _isHovering = true);
          widget.onHover(true);
        },
        onExit: (_) {
          setState(() => _isHovering = false);
          widget.onHover(false);
        },
        child: GestureDetector(
          onTap: widget.onTap,
          child: Transform.scale(
            scale: _currentScale,
            child: Transform.rotate(
              angle: _currentRotation,
              child: _buildCard(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCard() {
    return Container(
      width: CardState.cardSize,
      height: CardState.cardSize,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            widget.cardData.color,
            widget.cardData.color.withOpacity(0.8),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(_isHovering ? 0.3 : 0.2),
            blurRadius: _isHovering ? 20 : 15,
            offset: Offset(0, _isHovering ? 8 : 4),
            spreadRadius: _isHovering ? 2 : 0,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            // Background pattern/texture
            _buildCardPattern(),

            // Card content
            _buildCardContent(),

            // Shimmer effect on hover
            if (_isHovering) _buildShimmerEffect(),
          ],
        ),
      ),
    );
  }

  Widget _buildCardPattern() {
    return Container(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: const Alignment(-0.3, -0.5),
          radius: 1.2,
          colors: [Colors.white.withOpacity(0.2), Colors.transparent],
        ),
      ),
    );
  }

  Widget _buildCardContent() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Card icon/image placeholder
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.9),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(_getCardIcon(), color: widget.cardData.color, size: 24),
          ),
          const SizedBox(height: 12),

          // Card title
          Text(
            'Card ${widget.cardData.id + 1}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerEffect() {
    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: const Alignment(-1.0, -1.0),
            end: const Alignment(1.0, 1.0),
            colors: [
              Colors.transparent,
              Colors.white.withOpacity(0.2),
              Colors.transparent,
            ],
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
      ),
    );
  }

  IconData _getCardIcon() {
    final icons = [
      Icons.favorite,
      Icons.star,
      Icons.lightbulb,
      Icons.palette,
      Icons.music_note,
    ];
    return icons[widget.cardData.id % icons.length];
  }
}
