# Card Demo UI Prototype Specification

## Project Overview

A Flutter-based UI prototype showcasing an interactive card system with smooth animations and multiple view states. The prototype demonstrates advanced motion design principles through seamless transitions between different card layouts.

## Core Components

### Card Elements

- **Count**: 5 cards total
- **Shape**: Rounded squares
- **Visual Properties**:
  - Image assets as card content
  - Drop shadow for depth
  - Smooth corner radius
  - Consistent sizing across all cards

### Animation & Motion

- **Libraries**: Physics-based animation libraries for organic motion (e.g., `flutter_animate`, `spring`, `flutter_physics`)
- **Principles**:
  - Physics-driven animations with spring dynamics
  - Cards have virtual weight and momentum
  - Natural bounce and settling behavior
  - Organic, life-like motion that responds to user interaction

## User Interface States

### 1. Scattered State (Initial)

**Description**: The default state when the app loads

- Cards are randomly positioned across the screen
- Each card has a slight random rotation (-15° to +15°)
- Cards are spread out in a visually pleasing, organic arrangement
- Subtle entrance animation when first loaded

### 2. Stacked State (Collapsed)

**Description**: Cards magnetize together into a neat stack

- **Trigger**: Automatic transition from scattered state after initial load
- **Animation**: Cards smoothly animate to center position
- **Visual**:
  - Cards stack on top of each other with slight offset
  - Top card fully visible, others partially visible underneath
  - Slight shadow to indicate depth
  - Cards align and lose their rotation

### 3. Exploded State (Hover)

**Description**: Stack expands to show all cards clearly

- **Trigger**: Mouse hover over stacked cards
- **Animation**: Cards fan out while maintaining stack center
- **Visual**:
  - All 5 cards become fully visible
  - Arranged in a fan or circular pattern around the center
  - Cards maintain slight overlap but are distinguishable
  - Smooth return to stacked state when hover ends

### 4. Expanded State (Horizontal Layout)

**Description**: Cards arrange horizontally for detailed browsing

- **Trigger**: Click on the stacked cards
- **Layout**:
  - Cards arranged in a horizontal row
  - Center card is the "active" card (straight, fully visible)
  - Side cards are slightly rotated and scaled down
  - Smooth pagination/scrolling between cards

#### Interaction Details:

- **Navigation**: Horizontal scroll or pagination controls
- **Center Focus**: When scrolling, the card moving to center straightens from its rotated state
- **Rotation Effect**: Side cards have subtle rotation (±10-15°) that animates to 0° when centered
- **Smooth Transitions**: Easing between card positions

### 5. Collapse Control

**Description**: Return mechanism from expanded to stacked state

- **Element**: Collapse button (visible in expanded state)
- **Position**: Accessible but non-intrusive
- **Animation**: Reverse of the expansion animation
- **Trigger**: Button click returns cards to stacked state

## Technical Requirements

### Flutter Implementation

- **Minimum SDK**: Flutter 3.0+
- **Target Platforms**: iOS, Android, Web (responsive design)
- **Performance**: 60fps animations across all transitions

### Recommended Libraries

- `flutter_animate` (for physics-based animation sequences)
- `spring` (for spring dynamics and natural motion)
- `flutter_physics` (for advanced physics simulations)
- `provider` or `bloc` (state management)
- `transform_widget` (for rotation and scaling effects)

### Assets

- **Images**: 5 high-quality images for card content
- **Resolution**: Support for multiple screen densities (1x, 2x, 3x)
- **Format**: PNG or WebP for optimal performance

## Animation Specifications

### Physics Parameters

#### Spring Dynamics

- **Spring Tension**: 400-600 (controls stiffness/responsiveness)
- **Friction/Damping**: 25-40 (controls bounce and settling)
- **Mass**: Variable per card (heavier cards = more momentum)

#### Card Weight & Momentum

- **Scattered → Stacked**: Heavy cards with magnetic attraction, natural settling
- **Stacked → Exploded**: Light, responsive spring with gentle bounce
- **Exploded → Stacked**: Quick magnetic snap-back with slight overshoot
- **Stacked → Expanded**: Medium weight with momentum-based spreading
- **Expanded → Stacked**: Cards "fall" back with gravity-like motion
- **Horizontal Navigation**: Smooth momentum transfer between cards

### Motion Characteristics

- **Natural Settling**: All animations settle organically without abrupt stops
- **Momentum Conservation**: Cards maintain velocity during transitions
- **Weight Variation**: Different cards can have different virtual masses for variety
- **Responsive Physics**: Animation responds to interaction force/speed

## User Experience Goals

### Primary Objectives

1. **Delight**: Create moments of joy through organic, physics-based interactions that feel natural and alive
2. **Clarity**: Each state should be immediately understandable
3. **Performance**: Maintain 60fps across all devices and interactions
4. **Accessibility**: Support for reduced motion preferences

### Secondary Objectives

1. **Responsiveness**: Adapt gracefully to different screen sizes
2. **Touch-Friendly**: Appropriate hit targets for mobile devices
3. **Intuitive**: Interactions should feel natural and discoverable

## Development Phases

### Phase 1: Foundation

- Set up basic card widgets
- Implement static layouts for all states
- Create basic asset integration

### Phase 2: Physics-Based Animations

- Set up spring dynamics and physics simulation framework
- Implement scattered to stacked magnetic attraction
- Create stacked to exploded hover with spring physics
- Basic click handling for expansion with momentum

### Phase 3: Advanced Interactions

- Horizontal scrolling with rotation effects
- Pagination and smooth transitions
- Collapse functionality

### Phase 4: Polish & Optimization

- Performance optimization
- Responsive design
- Accessibility features
- Fine-tuning animations

## Success Metrics

- Smooth 60fps performance across all states
- Intuitive user interactions (no confusion about next steps)
- Visually appealing transitions that enhance the experience
- Responsive design that works across different screen sizes
