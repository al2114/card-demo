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

  // Touch interaction and rubber band effect tracking
  bool _isTouchActive = false;
  Offset _touchStartPosition = Offset.zero;
  Offset _currentTouchPosition = Offset.zero;
  Offset _rubberBandOffset = Offset.zero;
  final double _rubberBandStrength =
      0.05; // How much cards follow the drag (0-1) - very strong resistance
  final double _rubberBandDamping = 0.1; // How quickly they return to position

  // Swipe scrolling for expanded state
  double _swipeOffset = 0.0;
  final double _swipeRubberBandStrength =
      0.6; // How much cards follow horizontal swipe
  final double _swipeSnapThreshold =
      70.0; // Distance needed to snap to next/prev card

  // Momentum scrolling variables with improved dampening
  double _lastPanUpdateTime = 0.0;
  double _velocity = 0.0;
  final double _momentumThreshold =
      1200.0; // Minimum velocity for momentum scroll (higher = harder to trigger)
  final double _momentumDamping =
      0.8; // How much to reduce initial velocity (0-1, higher = more dampening)
  final double _friction =
      0.2; // Momentum decay factor per frame (lower = faster decay)
  final double _cardSpacing =
      140.0; // Distance between cards for momentum calculation
  final int _maxMomentumCards =
      3; // Maximum cards to scroll in one momentum swipe
  final int _momentumDelayMs =
      200; // Delay between card transitions in milliseconds
  bool _isMomentumScrolling = false;

  // Momentum tilt direction for visual feedback
  double _momentumTiltDirection = 0.0; // -1 for left, 1 for right, 0 for none

  // Touch region tracking with three-tier thresholds
  final double _expandThreshold = 100.0; // < 100px = expand
  final double _collapseThreshold =
      200.0; // 100-200px = collapse, >200px = immediate cancel
  bool _touchInsideActiveRegion = true;
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
        final activeOffset =
            i == _activeCard
                ? -12.0
                : 0.0; // Active card positioned 12px higher
        final hoverOffset =
            (i == _hoveredCard && _isExpanded)
                ? -8.0
                : 0.0; // Move up 8px on hover
        _cardPositions[i] = Offset(
          center.dx + (relativePosition * spacing) + _swipeOffset,
          baseY + activeOffset + hoverOffset,
        );
        // Base rotation for inactive cards
        final baseRotation = i == _activeCard ? 0.0 : relativePosition * 0.1;

        // Add swipe tilt when dragging or momentum tilt when scrolling
        double swipeTilt = 0.0;

        if (_isTouchActive) {
          // Active touch tilt based on drag offset
          swipeTilt = (_swipeOffset / 150.0) * 0.15;
        } else if (_isMomentumScrolling) {
          // Momentum tilt in the direction of movement
          swipeTilt =
              _momentumTiltDirection * 0.08; // Subtle tilt during momentum
        }

        _cardRotations[i] = baseRotation + swipeTilt;

        // Dynamic scaling based on swipe position and proximity to becoming active
        if (i == _hoveredCard && _isExpanded) {
          // Hover effect takes priority
          _cardScales[i] = i == _activeCard ? 1.1 : 0.95; // Pop effect
        } else if (_isTouchActive && _swipeOffset.abs() > 10) {
          // Calculate dynamic scale based on swipe progress
          final swipeDirection =
              _swipeOffset < 0 ? -1 : 1; // -1 for left, 1 for right
          final nextActiveCard =
              swipeDirection < 0
                  ? (_activeCard + 1) %
                      5 // Swiping left, next card
                  : (_activeCard - 1 + 5) % 5; // Swiping right, previous card

          // Calculate transition progress (0-1) based on swipe distance
          final maxSwipeForFullTransition =
              140.0; // Distance for full scale transition
          final swipeProgress = (_swipeOffset.abs() / maxSwipeForFullTransition)
              .clamp(0.0, 1.0);

          if (i == _activeCard) {
            // Current active card shrinks as we swipe away
            final targetScale = 0.85;
            _cardScales[i] = 1.0 - ((1.0 - targetScale) * swipeProgress);
          } else if (i == nextActiveCard) {
            // Next active card grows as we swipe toward it
            final targetScale = 1.0;
            _cardScales[i] = 0.85 + ((targetScale - 0.85) * swipeProgress);
          } else {
            // Other cards remain at inactive scale
            _cardScales[i] = 0.85;
          }
        } else {
          // Default static scale
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

        // Calculate base exploded position
        final basePosition =
            center +
            Offset(
              math.cos(angles[i]) * distances[i],
              math.sin(angles[i]) * distances[i],
            );

        // Add individual rubber band effect when touch is active
        if (_isTouchActive) {
          // Calculate individual resistance based on card position relative to drag direction
          final cardDirection = Offset(
            math.cos(angles[i]),
            math.sin(angles[i]),
          );

          // Calculate drag direction (normalized)
          final dragMagnitude = _rubberBandOffset.distance;
          final dragDirection =
              dragMagnitude > 0
                  ? Offset(
                    _rubberBandOffset.dx / dragMagnitude,
                    _rubberBandOffset.dy / dragMagnitude,
                  )
                  : Offset.zero;

          // Calculate alignment (-1 = opposite direction, 1 = same direction)
          final alignment =
              (cardDirection.dx * dragDirection.dx) +
              (cardDirection.dy * dragDirection.dy);

          // Calculate resistance multiplier (higher alignment = less resistance)
          // Range: 0.15 (high resistance) to 1.0 (low resistance)
          // Cards opposite to drag direction move much less, cards in same direction move more
          final resistanceMultiplier = 0.15 + (0.85 * ((alignment + 1) / 2));

          // Apply individual rubber band offset
          final individualOffset = _rubberBandOffset * resistanceMultiplier;
          _cardPositions[i] = basePosition + individualOffset;
        } else {
          _cardPositions[i] = basePosition;
        }

        _cardRotations[i] = organicRotations[i];

        // Add subtle scale effect during rubber band interaction
        if (_isTouchActive) {
          // Use individual card's movement for scale effect
          final individualMovement =
              (_cardPositions[i] - basePosition).distance;
          final scaleEffect =
              1.0 +
              (individualMovement *
                  0.002); // Subtle scale increase based on individual movement
          _cardScales[i] = 0.93 * scaleEffect;
        } else {
          _cardScales[i] = 0.93;
        }
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
      _isTouchActive =
          false; // Ensure hover detection works after state transition
    });
    _calculateCardPositions();
  }

  void _transitionToExpanded() {
    setState(() {
      _isExpanded = true;
      _isStacked = false;
      _isExploded = false;
      _activeCard = 2; // Start with center card
      _isTouchActive =
          false; // Ensure hover detection works after state transition
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
        _isTouchActive =
            false; // Ensure hover detection works after card selection
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
        _isTouchActive =
            false; // Ensure hover detection works after card change
      });
      _calculateCardPositions();
    }
  }

  void _previousCard() {
    if (_isExpanded) {
      setState(() {
        _activeCard = (_activeCard - 1 + 5) % 5;
        _isTouchActive =
            false; // Ensure hover detection works after card change
      });
      _calculateCardPositions();
    }
  }

  void _handleTapDown(TapDownDetails details) {
    setState(() {
      _isTouchActive = true;
      _touchStartPosition = details.globalPosition;
      _currentTouchPosition = details.globalPosition;
      _rubberBandOffset = Offset.zero;
      _swipeOffset = 0.0;
      _velocity = 0.0;
      _lastPanUpdateTime = 0.0;
      _isMomentumScrolling = false;
      _momentumTiltDirection = 0.0;
      _touchInsideActiveRegion = true; // Reset touch region tracking
      _hoveredCard = -1; // Clear hover state when touch starts
    });

    if (_isStacked) {
      _handleCardHover(true, -1); // Trigger exploded state
      _calculateCardPositions(); // Ensure immediate visual update
    }
  }

  // Touch gesture handlers for rubber band effect in exploded state and swipe navigation in expanded state
  void _handlePanStart(DragStartDetails details) {
    setState(() {
      _isTouchActive = true;
      _touchStartPosition = details.globalPosition;
      _currentTouchPosition = details.globalPosition;
      _rubberBandOffset = Offset.zero;
      _swipeOffset = 0.0;
      _velocity = 0.0;
      _lastPanUpdateTime = 0.0;
      _isMomentumScrolling = false;
      _momentumTiltDirection = 0.0;
      _touchInsideActiveRegion = true; // Reset touch region tracking
      _hoveredCard = -1; // Clear hover state when pan starts
    });

    if (_isStacked) {
      _handleCardHover(true, -1); // Trigger exploded state
      _calculateCardPositions(); // Ensure immediate visual update
    }
  }

  void _handlePanUpdate(DragUpdateDetails details) {
    if (_isTouchActive && !_isMomentumScrolling) {
      setState(() {
        _currentTouchPosition = details.globalPosition;
      });

      if (_isExploded) {
        // Handle rubber band effect for exploded state
        setState(() {
          // Calculate drag offset from initial touch position
          final dragOffset = _currentTouchPosition - _touchStartPosition;
          final dragDistance = dragOffset.distance;

          // Three-tier threshold system
          if (dragDistance > _collapseThreshold) {
            // Zone 3: >200px - Immediate cancel to stacked
            if (_touchInsideActiveRegion) {
              _touchInsideActiveRegion = false;
              _handleCardHover(false, -1);
              _rubberBandOffset = Offset.zero;
            }
          } else {
            // Zone 1 (<100px) and Zone 2 (100-200px) - Stay in exploded state
            if (!_touchInsideActiveRegion) {
              _touchInsideActiveRegion = true;
              _handleCardHover(true, -1);
            }

            // Apply rubber band effect for both zones
            _rubberBandOffset = Offset(
              dragOffset.dx * _rubberBandStrength,
              dragOffset.dy * _rubberBandStrength,
            );
          }
        });
        _calculateCardPositions(); // Recalculate positions with rubber band offset
      } else if (_isExpanded) {
        // Handle swipe scrolling for expanded state
        setState(() {
          final dragOffset = _currentTouchPosition - _touchStartPosition;
          final currentTime = DateTime.now().millisecondsSinceEpoch.toDouble();

          // Calculate velocity for momentum scrolling
          if (_lastPanUpdateTime > 0) {
            final deltaTime = currentTime - _lastPanUpdateTime;
            if (deltaTime > 0) {
              final deltaX = details.delta.dx;
              _velocity = deltaX / deltaTime * 1000; // pixels per second
            }
          }
          _lastPanUpdateTime = currentTime;

          // Apply rubber band effect to horizontal swipe
          _swipeOffset = dragOffset.dx * _swipeRubberBandStrength;
        });
        _calculateCardPositions(); // Recalculate positions with swipe offset
      }
    }
  }

  void _handlePanEnd(DragEndDetails details) {
    if (_isTouchActive && !_isMomentumScrolling) {
      final dragOffset = _currentTouchPosition - _touchStartPosition;
      final dragDistance = dragOffset.distance;
      final isHorizontalSwipe = dragOffset.dx.abs() > dragOffset.dy.abs();

      setState(() {
        _isTouchActive = false;
        _rubberBandOffset = Offset.zero;
      });

      if (_isExpanded && isHorizontalSwipe) {
        // Handle momentum-based navigation in expanded state
        final absVelocity = _velocity.abs();

        if (absVelocity > _momentumThreshold) {
          // Start momentum scrolling (hover state will be cleared in _startMomentumScroll)
          _startMomentumScroll(_velocity);
        } else {
          // Traditional snap behavior for slow swipes - clear hover state
          setState(() {
            _hoveredCard = -1; // Clear hover state for non-momentum swipes
          });

          final shouldSnap = dragOffset.dx.abs() > _swipeSnapThreshold;

          if (shouldSnap) {
            if (dragOffset.dx > 0) {
              // Swiped right - go to previous card
              _previousCard();
            } else {
              // Swiped left - go to next card
              _nextCard();
            }
          }

          // Reset swipe offset with animation
          setState(() {
            _swipeOffset = 0.0;
          });
          _calculateCardPositions(); // Animate back to position
        }
      } else if (_isStacked || _isExploded) {
        // Handle three-tier threshold system on release
        if (dragDistance < _expandThreshold) {
          // Zone 1: <100px - Expand to full view
          _transitionToExpanded();
        } else if (dragDistance <= _collapseThreshold) {
          // Zone 2: 100-200px - Return to stacked
          _handleCardHover(false, -1);
        } else {
          // Zone 3: >200px - Already cancelled during drag, just ensure stacked
          _handleCardHover(false, -1);
        }
      }

      _calculateCardPositions(); // Reset positions
    }
  }

  void _handlePanCancel() {
    if (_isTouchActive) {
      setState(() {
        _isTouchActive = false;
        _rubberBandOffset = Offset.zero;
        _swipeOffset = 0.0;
        _momentumTiltDirection = 0.0; // Clear any momentum tilt
        _touchInsideActiveRegion = false; // Set to false when cancelled
        _hoveredCard = -1; // Clear hover state when pan is cancelled
      });

      if (_isStacked || _isExploded) {
        _handleCardHover(false, -1);
      }

      _calculateCardPositions();
    }
  }

  void _startMomentumScroll(double initialVelocity) {
    if (_isMomentumScrolling) return; // Prevent multiple momentum scrolls

    setState(() {
      _isMomentumScrolling = true;
      // Set tilt direction based on initial velocity direction
      _momentumTiltDirection =
          initialVelocity < 0 ? -0.5 : 0.5; // Subtle directional tilt
      _hoveredCard = -1; // Clear hover state during momentum scrolling
    });

    // Apply dampening to initial velocity to make momentum less aggressive
    final dampedVelocity = initialVelocity * (1.0 - _momentumDamping);

    // Calculate how many cards to scroll through based on dampened velocity
    final momentumDistance =
        (dampedVelocity * dampedVelocity) / (2 * (1 - _friction) * 800);
    final cardsToScroll = (momentumDistance / _cardSpacing).round().clamp(
      1,
      _maxMomentumCards,
    );
    final direction =
        initialVelocity < 0 ? -1 : 1; // -1 for left (next), 1 for right (prev)

    // Animate through multiple cards with dampened velocity
    _animateMomentumScroll(cardsToScroll, direction, dampedVelocity);
  }

  void _animateMomentumScroll(
    int cardsToScroll,
    int direction,
    double currentVelocity,
  ) {
    if (cardsToScroll <= 0 || currentVelocity.abs() < 100) {
      // Momentum finished, reset state
      setState(() {
        _isMomentumScrolling = false;
        _swipeOffset = 0.0;
        _velocity = 0.0;
        _momentumTiltDirection = 0.0; // Clear momentum tilt
        _hoveredCard = -1; // Clear hover state when momentum ends
      });
      _calculateCardPositions();
      return;
    }

    // Move to next card
    if (direction > 0) {
      _previousCard();
    } else {
      _nextCard();
    }

    // Apply friction to velocity (more aggressive decay)
    final newVelocity = currentVelocity * _friction;

    // Continue momentum with configurable delay (longer delay = slower)
    Future.delayed(Duration(milliseconds: _momentumDelayMs), () {
      if (_isMomentumScrolling) {
        _animateMomentumScroll(cardsToScroll - 1, direction, newVelocity);
      }
    });
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

              // Debug: Show touch cancel threshold when touching in exploded state
              // if (_isTouchActive && _isExploded && _touchInsideHoverRegion)
              //   _buildTouchThresholdIndicator(),

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
            // Only trigger mouse hover if not actively touching
            if (!_isTouchActive) {
              _handleCardHover(true, index);
            }
          },
          onExit: (_) {
            // Only cancel mouse hover if not actively touching
            if (!_isTouchActive) {
              _handleCardHover(false, index);
            }
          },
          child: GestureDetector(
            onTap: () => _handleCardTap(index),
            onTapDown: _handleTapDown,
            onPanStart: _handlePanStart,
            onPanUpdate: _handlePanUpdate,
            onPanEnd: _handlePanEnd,
            onPanCancel: _handlePanCancel,
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

  Widget _buildTouchThresholdIndicator() {
    return Stack(
      children: [
        // Three-tier threshold indicators
        // Zone 1: Expand threshold (100px)
        Positioned(
          left: _touchStartPosition.dx - _expandThreshold,
          top: _touchStartPosition.dy - _expandThreshold,
          child: Container(
            width: _expandThreshold * 2,
            height: _expandThreshold * 2,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.green.withOpacity(0.8),
                width: 2,
              ),
              color: Colors.green.withOpacity(0.1),
            ),
          ),
        ),
        // Zone 2: Collapse threshold (200px)
        Positioned(
          left: _touchStartPosition.dx - _collapseThreshold,
          top: _touchStartPosition.dy - _collapseThreshold,
          child: Container(
            width: _collapseThreshold * 2,
            height: _collapseThreshold * 2,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color:
                    _touchInsideActiveRegion
                        ? Colors.orange.withOpacity(0.6)
                        : Colors.red.withOpacity(0.6),
                width: 2,
              ),
              color: Colors.transparent,
            ),
          ),
        ),
        // Text indicator
        Positioned(
          top: 100,
          left: 40,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.7),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Thresholds: ${_expandThreshold.toInt()}px (expand) | ${_collapseThreshold.toInt()}px (cancel)',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.white,
                letterSpacing: 1.0,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
