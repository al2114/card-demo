import 'package:flutter/material.dart';
import 'dart:math' as math;

enum CardDemoState { scattered, stacked, exploded, expanded }

class CardData {
  final int id;
  final Color color;
  final String? imagePath;
  final double rotation;
  final Offset position;
  final double scale;

  CardData({
    required this.id,
    required this.color,
    this.imagePath,
    this.rotation = 0.0,
    this.position = Offset.zero,
    this.scale = 1.0,
  });

  CardData copyWith({
    int? id,
    Color? color,
    String? imagePath,
    double? rotation,
    Offset? position,
    double? scale,
  }) {
    return CardData(
      id: id ?? this.id,
      color: color ?? this.color,
      imagePath: imagePath ?? this.imagePath,
      rotation: rotation ?? this.rotation,
      position: position ?? this.position,
      scale: scale ?? this.scale,
    );
  }
}

class CardState extends ChangeNotifier {
  CardDemoState _currentState = CardDemoState.scattered;
  List<CardData> _cards = [];
  bool _isHovering = false;
  int _activeCardIndex = 0;
  Size _screenSize = Size.zero;

  // Physics parameters
  static const double springTension = 500.0;
  static const double springDamping = 30.0;
  static const double cardSize = 120.0;

  CardState() {
    _initializeCards();
  }

  // Getters
  CardDemoState get currentState => _currentState;
  List<CardData> get cards => List.unmodifiable(_cards);
  bool get isHovering => _isHovering;
  int get activeCardIndex => _activeCardIndex;
  Size get screenSize => _screenSize;

  void setScreenSize(Size size) {
    if (_screenSize != size) {
      _screenSize = size;
      _updateCardPositions();
      notifyListeners();
    }
  }

  void _initializeCards() {
    final colors = [
      const Color(0xFF8B5CF6), // Purple
      const Color(0xFF06B6D4), // Cyan
      const Color(0xFF10B981), // Emerald
      const Color(0xFFF59E0B), // Amber
      const Color(0xFFEF4444), // Red
    ];

    _cards = List.generate(5, (index) {
      return CardData(
        id: index,
        color: colors[index % colors.length],
        rotation: _getRandomRotation(),
        position: Offset.zero, // Will be set when screen size is available
      );
    });
  }

  double _getRandomRotation() {
    final random = math.Random();
    return (random.nextDouble() - 0.5) * 0.5; // -15° to +15° in radians
  }

  void _updateCardPositions() {
    if (_screenSize == Size.zero) return;

    switch (_currentState) {
      case CardDemoState.scattered:
        _updateScatteredPositions();
        break;
      case CardDemoState.stacked:
        _updateStackedPositions();
        break;
      case CardDemoState.exploded:
        _updateExplodedPositions();
        break;
      case CardDemoState.expanded:
        _updateExpandedPositions();
        break;
    }
  }

  void _updateScatteredPositions() {
    final random = math.Random(42); // Seeded for consistent layout
    final center = Offset(_screenSize.width / 2, _screenSize.height / 2);
    final maxOffset = math.min(_screenSize.width, _screenSize.height) * 0.3;

    for (int i = 0; i < _cards.length; i++) {
      final angle = random.nextDouble() * 2 * math.pi;
      final distance = random.nextDouble() * maxOffset;
      final offset = Offset(
        math.cos(angle) * distance,
        math.sin(angle) * distance,
      );

      _cards[i] = _cards[i].copyWith(
        position: center + offset,
        rotation: _getRandomRotation(),
        scale: 1.0,
      );
    }
  }

  void _updateStackedPositions() {
    final center = Offset(_screenSize.width / 2, _screenSize.height / 2);

    for (int i = 0; i < _cards.length; i++) {
      final offset = Offset(i * 2.0, -i * 2.0); // Slight offset for depth
      _cards[i] = _cards[i].copyWith(
        position: center + offset,
        rotation: 0.0,
        scale: 1.0,
      );
    }
  }

  void _updateExplodedPositions() {
    final center = Offset(_screenSize.width / 2, _screenSize.height / 2);
    final radius = 80.0;

    for (int i = 0; i < _cards.length; i++) {
      final angle = (i / _cards.length) * 2 * math.pi - math.pi / 2;
      final offset = Offset(math.cos(angle) * radius, math.sin(angle) * radius);

      _cards[i] = _cards[i].copyWith(
        position: center + offset,
        rotation: 0.0,
        scale: 0.9,
      );
    }
  }

  void _updateExpandedPositions() {
    final centerY = _screenSize.height / 2;
    final startX = _screenSize.width / 2 - ((_cards.length - 1) * 140 / 2);

    for (int i = 0; i < _cards.length; i++) {
      final x = startX + (i * 140);
      final isCenter = i == _activeCardIndex;
      final rotation = isCenter ? 0.0 : (i < _activeCardIndex ? -0.2 : 0.2);
      final scale = isCenter ? 1.0 : 0.8;

      _cards[i] = _cards[i].copyWith(
        position: Offset(x, centerY),
        rotation: rotation,
        scale: scale,
      );
    }
  }

  // State transitions
  void transitionToStacked() {
    if (_currentState != CardDemoState.stacked) {
      _currentState = CardDemoState.stacked;
      _updateCardPositions();
      notifyListeners();
    }
  }

  void transitionToScattered() {
    if (_currentState != CardDemoState.scattered) {
      _currentState = CardDemoState.scattered;
      _updateCardPositions();
      notifyListeners();
    }
  }

  void transitionToExpanded() {
    if (_currentState != CardDemoState.expanded) {
      _currentState = CardDemoState.expanded;
      _updateCardPositions();
      notifyListeners();
    }
  }

  void setHovering(bool hovering) {
    if (_isHovering != hovering) {
      _isHovering = hovering;
      if (_currentState == CardDemoState.stacked) {
        if (hovering) {
          _currentState = CardDemoState.exploded;
        } else {
          _currentState = CardDemoState.stacked;
        }
        _updateCardPositions();
        notifyListeners();
      }
    }
  }

  void setActiveCard(int index) {
    if (_activeCardIndex != index && index >= 0 && index < _cards.length) {
      _activeCardIndex = index;
      if (_currentState == CardDemoState.expanded) {
        _updateCardPositions();
        notifyListeners();
      }
    }
  }

  void nextCard() {
    if (_currentState == CardDemoState.expanded) {
      setActiveCard((_activeCardIndex + 1) % _cards.length);
    }
  }

  void previousCard() {
    if (_currentState == CardDemoState.expanded) {
      setActiveCard((_activeCardIndex - 1 + _cards.length) % _cards.length);
    }
  }
}
