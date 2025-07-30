import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:math' as math;

void main() {
  runApp(const CardDemoApp());
}

class CardDemoApp extends StatelessWidget {
  const CardDemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Card Demo - Physics Animation',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6366F1),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      home: const CardDemoScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class CardDemoScreen extends StatelessWidget {
  const CardDemoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFF8FAFC), Color(0xFFE2E8F0)],
            ),
          ),
          child: const PhysicsCardDemo(),
        ),
      ),
    );
  }
}

class PhysicsCardDemo extends StatefulWidget {
  const PhysicsCardDemo({super.key});

  @override
  State<PhysicsCardDemo> createState() => _PhysicsCardDemoState();
}

class _PhysicsCardDemoState extends State<PhysicsCardDemo> {
  // Card state management
  bool _isStacked = false;
  bool _isExpanded = false;
  bool _isExploded = false;
  bool _isHovering = false;
  int _activeCard = 0;
  int _hoveredCard = -1; // Track which card is being hovered in expanded view
  Size _screenSize = Size.zero;

  // Track if initial animation should run
  bool _shouldAnimateInitialAppearance = true;
  bool _hasCompletedInitialDelay = false;

  // Card data
  final List<Color> _cardColors = [
    const Color(0xFF8B5CF6), // Purple
    const Color(0xFF06B6D4), // Cyan
    const Color(0xFF10B981), // Emerald
    const Color(0xFFF59E0B), // Amber
    const Color(0xFFEF4444), // Red
  ];

  final List<Offset> _cardPositions = List.filled(5, Offset.zero);
  final List<double> _cardRotations = List.filled(5, 0.0);
  final List<double> _cardScales = List.filled(5, 1.0);

  @override
  void initState() {
    super.initState();

    // First, end the pop animation after 400ms
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) {
        setState(() {
          _shouldAnimateInitialAppearance = false;
        });
      }
    });

    // Then after additional delay (total 2.5 seconds), transition to stacked
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) {
        setState(() {
          _hasCompletedInitialDelay = true;
        });
        _transitionToStacked();
      }
    });
  }

  void _calculateCardPositions() {
    if (_screenSize == Size.zero) return;

    final center = Offset(_screenSize.width / 2, _screenSize.height / 2);

    for (int i = 0; i < 5; i++) {
      if (_isExpanded) {
        // Horizontal layout with active card centered
        final spacing = 140.0;
        final relativePosition =
            i - _activeCard; // Position relative to active card

        final baseY = center.dy;
        final hoverOffset =
            (i == _hoveredCard && _isExpanded)
                ? -8.0
                : 0.0; // Move up 8px on hover
        _cardPositions[i] = Offset(
          center.dx + (relativePosition * spacing),
          baseY + hoverOffset,
        );
        _cardRotations[i] =
            i == _activeCard ? 0.0 : relativePosition.sign * 0.15;
        // Apply hover effect in expanded view
        if (i == _hoveredCard && _isExpanded) {
          _cardScales[i] = i == _activeCard ? 1.1 : 0.95; // Pop effect
        } else {
          _cardScales[i] = i == _activeCard ? 1.0 : 0.85;
        }
      } else if (_isExploded) {
        // Exploded radial burst from center
        final angles = [
          -math.pi * 0.75, // Card 0: upper left
          -math.pi * 0.25, // Card 1: upper right
          math.pi * 0.25, // Card 2: lower right
          math.pi * 0.75, // Card 3: lower left
          math.pi, // Card 4: left
        ];

        final distances = [
          78.0, // Card 0: upper left
          82.0, // Card 1: upper right
          85.0, // Card 2: lower right
          80.0, // Card 3: lower left
          76.0, // Card 4: left
        ];

        final organicRotations = [
          -0.12, // Card 0: tilted left
          0.06, // Card 1: slight right tilt
          -0.02, // Card 2: almost straight
          0.08, // Card 3: moderate right tilt
          -0.15, // Card 4: more left tilt
        ];

        _cardPositions[i] =
            center +
            Offset(
              math.cos(angles[i]) * distances[i],
              math.sin(angles[i]) * distances[i],
            );
        _cardRotations[i] = organicRotations[i];
        _cardScales[i] = 0.93;
      } else if (_isStacked) {
        // Stacked layout with peek and subtle rotation
        final baseOffset = Offset(i * 3.0, -i * 3.0);
        final peekOffset = Offset(
          (i - 2) * 8.0, // Horizontal peek based on position from center
          i * 2.0, // Slight vertical offset
        );
        _cardPositions[i] = center + baseOffset + peekOffset;

        // Subtle rotation for cards underneath (top card stays straight)
        _cardRotations[i] =
            i == 4
                ? 0.0
                : (i - 2) * 0.05; // Top card (4) straight, others rotated
        _cardScales[i] = 1.0;
      } else {
        // Scattered layout with random positions and rotations
        final angles = [0.5, 1.8, 4.2, 2.8, 5.9];
        final distances = [80.0, 120.0, 100.0, 140.0, 90.0];
        _cardPositions[i] =
            center +
            Offset(
              math.cos(angles[i]) * distances[i],
              math.sin(angles[i]) * distances[i],
            );
        _cardRotations[i] = (i % 2 == 0 ? 1 : -1) * 0.3;
        _cardScales[i] = 1.0;
      }
    }
  }

  void _transitionToStacked() {
    setState(() {
      _isStacked = true;
      _isExpanded = false;
      _isExploded = false;
    });
    _calculateCardPositions();
  }

  void _transitionToExpanded() {
    setState(() {
      _isExpanded = true;
      _isStacked = false;
      _isExploded = false;
      _activeCard = 2; // Start with center card
    });
    _calculateCardPositions();
  }

  void _transitionToExploded() {
    setState(() {
      _isExploded = true;
      _isStacked = false;
      _isExpanded = false;
    });
    _calculateCardPositions();
  }

  void _handleCardTap(int cardIndex) {
    if (_isStacked || _isExploded) {
      _transitionToExpanded();
    } else if (_isExpanded) {
      // In expanded view, clicking selects the card
      setState(() {
        _activeCard = cardIndex;
      });
      _calculateCardPositions();
    }
  }

  void _handleCardHover(bool hovering, int cardIndex) {
    if (_isExpanded) {
      // In expanded view, track individual card hover for pop effect
      setState(() {
        _hoveredCard = hovering ? cardIndex : -1;
      });
      _calculateCardPositions(); // Recalculate positions for hover movement
    } else {
      // For other views, use global hover state
      setState(() {
        _isHovering = hovering;
      });
      if (_isStacked && hovering) {
        _transitionToExploded();
      } else if (_isExploded && !hovering) {
        _transitionToStacked();
      }
    }
  }

  void _nextCard() {
    if (_isExpanded) {
      setState(() {
        _activeCard = (_activeCard + 1) % 5;
      });
      _calculateCardPositions();
    }
  }

  void _previousCard() {
    if (_isExpanded) {
      setState(() {
        _activeCard = (_activeCard - 1 + 5) % 5;
      });
      _calculateCardPositions();
    }
  }

  // Helper methods for hover effects
  double _getCardShadowOpacity(int index) {
    // Only apply hover shadow in scattered state, not stacked (to avoid cumulative darkness)
    if (!_isExpanded && !_isStacked && !_isExploded && _isHovering) {
      return 0.25; // Lighter hover shadow for scattered state
    }
    return 0.15; // Lighter default shadow
  }

  double _getCardShadowBlur(int index) {
    if (!_isExpanded && !_isStacked && !_isExploded && _isHovering) {
      return 18.0; // Hover blur for scattered state
    }
    return 12.0; // Default blur
  }

  double _getCardShadowOffset(int index) {
    if (!_isExpanded && !_isStacked && !_isExploded && _isHovering) {
      return 6.0; // Hover offset for scattered state
    }
    return 3.0; // Default offset
  }

  double _getCardShadowSpread(int index) {
    if (!_isExpanded && !_isStacked && !_isExploded && _isHovering) {
      return 1.0; // Hover spread for scattered state
    }
    return 0.0; // Default spread
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: FocusNode()..requestFocus(),
      onKeyEvent: (event) {
        if (event is KeyDownEvent && _isExpanded) {
          if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
            _previousCard();
          } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
            _nextCard();
          }
        }
      },
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Update screen size and recalculate positions
          final newSize = constraints.biggest;
          if (_screenSize != newSize) {
            _screenSize = newSize;
            _calculateCardPositions(); // Calculate positions immediately
            WidgetsBinding.instance.addPostFrameCallback((_) {
              setState(() {}); // Just trigger a rebuild
            });
          }

          return Stack(
            children: [
              // Cards with physics-based animations
              if (_screenSize !=
                  Size.zero) // Only show cards when positions are calculated
                ..._buildCardsWithZOrder(),

              // State indicator
              Positioned(
                top: 60,
                left: 40,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _isExpanded
                        ? 'EXPANDED'
                        : _isExploded
                        ? 'EXPLODED'
                        : _isStacked
                        ? 'STACKED'
                        : 'SCATTERED',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
              ),

              // Collapse button (visible in expanded state)
              if (_isExpanded) _buildCollapseButton(),

              // Navigation controls (visible in expanded state)
              if (_isExpanded) _buildNavigationControls(),

              // Instructions (visible when not expanded)
              if (!_isExpanded)
                Positioned(
                  bottom: 60,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Text(
                        'Hover over stacked cards • Tap to expand',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF374151),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  List<Widget> _buildCardsWithZOrder() {
    // Always render cards in their natural order to maintain position consistency
    return List.generate(5, (index) => _buildAnimatedCard(index));
  }

  int _getCardZIndex(int index) {
    // Return z-index priority (higher = on top)
    if (_isExpanded && index == _activeCard) {
      return 3; // Active card on top in expanded view
    } else if (index == _hoveredCard && _hoveredCard != -1) {
      return 2; // Hovered card in middle layer
    } else {
      return 1; // Inactive cards on bottom
    }
  }

  Widget _buildAnimatedCard(int index) {
    // Subtle spring animation curves
    const springCurve = Curves.easeOutBack;
    const duration = Duration(milliseconds: 600);

    final left = _cardPositions[index].dx - 60;
    final top = _cardPositions[index].dy - 60;
    final zIndex = _getCardZIndex(index);

    return AnimatedPositioned(
      duration: duration,
      curve: springCurve,
      left: left,
      top: top,
      child: Transform.translate(
        offset: Offset(0, -zIndex * 0.1), // Subtle z-offset for layering
        child: MouseRegion(
          onEnter: (_) {
            _handleCardHover(true, index);
          },
          onExit: (_) {
            _handleCardHover(false, index);
          },
          child: GestureDetector(
            onTap: () => _handleCardTap(index),
            child: AnimatedContainer(
              duration: duration,
              curve: springCurve,
              transform:
                  Matrix4.identity()
                    ..scale(_cardScales[index])
                    ..rotateZ(_cardRotations[index]),
              child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          _cardColors[index],
                          _cardColors[index].withOpacity(0.8),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(
                            _getCardShadowOpacity(index),
                          ),
                          blurRadius: _getCardShadowBlur(index),
                          offset: Offset(0, _getCardShadowOffset(index)),
                          spreadRadius: _getCardShadowSpread(index),
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        _buildCardContent(index),
                        // Light up effect on hover in expanded view
                        if (_isExpanded && index == _hoveredCard)
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Colors.white.withOpacity(0.3),
                                  Colors.white.withOpacity(0.1),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  )
                  .animate(target: _shouldAnimateInitialAppearance ? 0 : 1)
                  .scale(
                    begin: const Offset(0.0, 0.0),
                    end: const Offset(1.0, 1.0),
                    duration: 400.ms,
                    curve: Curves.easeOutBack,
                  )
                  .fadeIn(duration: 300.ms, curve: Curves.easeOut),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCollapseButton() {
    return Positioned(
      top: 60,
      right: 40,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _transitionToStacked,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.9),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.close, size: 18, color: Color(0xFF374151)),
                SizedBox(width: 4),
                Text(
                  'Collapse',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF374151),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavigationControls() {
    return Positioned(
      bottom: 60,
      left: 0,
      right: 0,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildNavButton(icon: Icons.chevron_left, onTap: _previousCard),
          const SizedBox(width: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.9),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              '${_activeCard + 1} / 5',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF374151),
              ),
            ),
          ),
          const SizedBox(width: 20),
          _buildNavButton(icon: Icons.chevron_right, onTap: _nextCard),
        ],
      ),
    );
  }

  Widget _buildNavButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.9),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(icon, color: const Color(0xFF374151), size: 24),
        ),
      ),
    );
  }

  Widget _buildCardContent(int index) {
    final icons = [
      Icons.favorite,
      Icons.star,
      Icons.lightbulb,
      Icons.palette,
      Icons.music_note,
    ];

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.9),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icons[index], color: _cardColors[index], size: 24),
          ),
          const SizedBox(height: 12),
          Text(
            'Card ${index + 1}',
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
}
