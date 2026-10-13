# Waypoints iOS — Native 3D Globe Specification

## 1. Mathematical Foundation

The Waypoints 3D Globe renders a spherical projection of Earth using orthographic projection geometry implemented natively in SwiftUI Canvas and Metal graphics pipelines.

### Forward Projection (Sphere to Screen)
Given:
- Point latitude \(\phi\) and longitude \(\lambda\)
- Globe center viewing orientation \((\phi_0, \lambda_0)\) where \(\phi_0\) is tilt and \(\lambda_0\) is rotation
- Radius \(R\) and viewport center \((C_x, C_y)\)

\[
\cos c = \sin\phi_0 \sin\phi + \cos\phi_0 \cos\phi \cos(\lambda - \lambda_0)
\]

If \(\cos c < 0\), the point lies on the back hemisphere and is hidden from view.
Otherwise:
\[
x = C_x + R \cos\phi \sin(\lambda - \lambda_0)
\]
\[
y = C_y - R (\cos\phi_0 \sin\phi - \sin\phi_0 \cos\phi \cos(\lambda - \lambda_0))
\]

### Inverse Projection (`unproject` for Tap-to-Pin)
When the user taps screen pixel \((X, Y)\):
1. Compute offset relative to globe center:
   \[
   \Delta x = X - C_x, \quad \Delta y = -(Y - C_y)
   \]
2. Radius distance:
   \[
   \rho = \sqrt{\Delta x^2 + \Delta y^2}
   \]
3. If \(\rho > R\), the tap is outside the Earth sphere; reject.
4. Angular distance:
   \[
   c = \arcsin\left(\frac{\rho}{R}\right)
   \]
5. Recover latitude:
   \[
   \phi = \arcsin\left(\cos c \sin\phi_0 + \frac{\Delta y \sin c \cos\phi_0}{\rho}\right)
   \]
6. Recover longitude:
   \[
   \lambda = \lambda_0 + \arctan2\left(\Delta x \sin c, \rho \cos\phi_0 \cos c - \Delta y \sin\phi_0 \sin c\right)
   \]

---

## 2. Interaction Modes

Waypoints supports 3 interaction modes on the Globe screen:
1. **Explore Mode (`.explore`)**:
   - Inertial drag rotation around polar and equatorial axes.
   - Pinch to zoom (\(0.75\times\) to \(1.6\times\)).
   - Tap any pin marker to view place preview card with instant haptic feedback.
2. **Tap-to-Pin Mode (`.pickLocation`)**:
   - Interactive crosshair cursor overlay.
   - Tapping anywhere on the Earth disk invokes `CoordinateMath.unproject`, resolving exact geographic coordinates.
   - Instantly presents `SaveGlobePinSheet` to name and save the waypoint.
3. **Trip Focus Mode (`.tripMode`)**:
   - Top filter bar presents planned trips (e.g. "Japan 2027", "Europe Summer").
   - Filters the visible pins to display only the destinations included in that trip.

---

## 3. Visual Styling & Markers

- **Standard Pin**: Terracotta circular badge (`#B27C61`) with deep forest core.
- **Favorite Pin**: Sunset amber badge (`#D97447`) with star glyph and warm halo.
- **Visited Pin**: Deep forest badge (`#244B3B`) with checkmark seal glyph.
- **Selected Pin**: Dynamic pulse scale animation (\(1.0\times \rightarrow 1.4\times\)).
- **Atmosphere**: Radial gradient backdrop with specular rim lighting overlay.
