# canvas
Canvas is a Flutter package that provides an editor toolkit like Canva.

## Features
- [x] Dragging and resizing widgets
- [x] Rotating widgets
- [x] Flipping widgets
- [x] Grouping widgets

## Note
Canvas is still in development, some features is still missing:
- [ ] Snapping objects
- [ ] Layouting (like AutoLayout in Figma)
- [ ] Undo/Redo

# Item Constraint Types
- FixedConstraints
  - Param:
    - Offset
    - Rotation
    - Scale
    - Size
- AnchoredConstraints
  - Param:
    - Offset
    - Rotation
    - Scale
    - Size
    - Horizontal Constraint (left, right, center, scale, leftAndRight, aligned(double alignment))
    - Vertical Constraint (top, bottom, center, scale, leftAndRight, aligned(double alignment))
- FlexibleConstraints
  - Param:
    - Width Constraint (fill, fixed(min, max), hug)
      - Fill requires the parent layout to be FlexLayout
      - Hug requires the item layout to be FlexLayout
    - Height Constraint (fill, fixed(min, max), hug)
      - Fill requires the parent layout to be FlexLayout
      - Hug requires the item layout to be FlexLayout
# Layout Types
- FixedLayout
- FlexLayout
  - Param:
    - Alignment
    - Direction (horizontal, vertical)
    - Gap
    - Padding
- WrapLayout
  - Param:
    - Alignment
    - Direction (horizontal, vertical)
    - Main Axis Gap
    - Cross Axis Gap
    - Padding