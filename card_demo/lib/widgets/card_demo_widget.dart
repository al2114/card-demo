import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/card_state.dart';
import 'animated_card.dart';

class CardDemoWidget extends StatefulWidget {
  const CardDemoWidget({super.key});

  @override
  State<CardDemoWidget> createState() => _CardDemoWidgetState();
}

class _CardDemoWidgetState extends State<CardDemoWidget>
    with TickerProviderStateMixin {
  late AnimationController _transitionController;
  late AnimationController _physicsController;

  @override
  void initState() {
    super.initState();

    _transitionController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _physicsController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    // Start with scattered state, then transition to stacked after a delay
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 800), () {
        if (mounted) {
          context.read<CardState>().transitionToStacked();
          _transitionController.forward();
        }
      });
    });
  }

  @override
  void dispose() {
    _transitionController.dispose();
    _physicsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Update screen size in the state
        WidgetsBinding.instance.addPostFrameCallback((_) {
          context.read<CardState>().setScreenSize(constraints.biggest);
        });

        return Consumer<CardState>(
          builder: (context, cardState, child) {
            return Stack(
              children: [
                // Cards
                ...cardState.cards.map((cardData) {
                  return AnimatedCard(
                    key: ValueKey(cardData.id),
                    cardData: cardData,
                    onTap: () => _handleCardTap(cardState),
                    onHover:
                        (hovering) => _handleCardHover(cardState, hovering),
                  );
                }),

                // Collapse button (visible in expanded state)
                if (cardState.currentState == CardDemoState.expanded)
                  _buildCollapseButton(cardState),

                // Navigation controls (visible in expanded state)
                if (cardState.currentState == CardDemoState.expanded)
                  _buildNavigationControls(cardState),

                // State indicator (debug/demo purposes)
                _buildStateIndicator(cardState),
              ],
            );
          },
        );
      },
    );
  }

  void _handleCardTap(CardState cardState) {
    switch (cardState.currentState) {
      case CardDemoState.stacked:
      case CardDemoState.exploded:
        cardState.transitionToExpanded();
        _transitionController.forward();
        break;
      case CardDemoState.expanded:
        // Individual card interaction in expanded state could go here
        break;
      case CardDemoState.scattered:
        cardState.transitionToStacked();
        break;
    }
  }

  void _handleCardHover(CardState cardState, bool hovering) {
    if (cardState.currentState == CardDemoState.stacked ||
        cardState.currentState == CardDemoState.exploded) {
      cardState.setHovering(hovering);
    }
  }

  Widget _buildCollapseButton(CardState cardState) {
    return Positioned(
      top: 60,
      right: 40,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            cardState.transitionToStacked();
            _transitionController.reverse();
          },
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

  Widget _buildNavigationControls(CardState cardState) {
    return Positioned(
      bottom: 60,
      left: 0,
      right: 0,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildNavButton(
            icon: Icons.chevron_left,
            onTap: cardState.previousCard,
          ),
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
              '${cardState.activeCardIndex + 1} / ${cardState.cards.length}',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF374151),
              ),
            ),
          ),
          const SizedBox(width: 20),
          _buildNavButton(icon: Icons.chevron_right, onTap: cardState.nextCard),
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

  Widget _buildStateIndicator(CardState cardState) {
    return Positioned(
      top: 60,
      left: 40,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.7),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          cardState.currentState.name.toUpperCase(),
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.white,
            letterSpacing: 1.0,
          ),
        ),
      ),
    );
  }
}
