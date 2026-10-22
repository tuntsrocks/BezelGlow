// Bezel glow.
//
// A thin luminous ribbon on the rounded bezel, with a short halo.
// Color comes from a few large pools drifting along the rim — not a
// painted rainbow. Voice thickens and brightens the whole ribbon.

#include <metal_stdlib>
#include <SwiftUI/SwiftUI_Metal.h>

using namespace metal;

inline float hash21(float2 p) {
    p = fract(p * float2(127.1, 311.7));
    p += dot(p, p + 19.19);
    return fract(p.x * p.y);
}

inline float valueNoise(float2 p) {
    float2 i = floor(p);
    float2 f = fract(p);
    float2 u = f * f * (3.0 - 2.0 * f);
    return mix(
        mix(hash21(i), hash21(i + float2(1.0, 0.0)), u.x),
        mix(hash21(i + float2(0.0, 1.0)), hash21(i + float2(1.0, 1.0)), u.x),
        u.y
    );
}

inline float fbm(float2 p) {
    float v = valueNoise(p) * 0.65;
    v += valueNoise(p * 2.1 + 4.2) * 0.35;
    return v;
}

inline float roundedBoxSDF(float2 p, float2 halfSize, float radius) {
    float2 q = abs(p) - halfSize + radius;
    return length(max(q, 0.0)) + min(max(q.x, q.y), 0.0) - radius;
}

/// Sides of the rounded bezel. A corner arc belongs fully to either neighbor,
/// so a lone edge keeps its rounded caps and the inward fade stays an inset
/// of the phone corner — not a diagonal or a triangle.
/// edges: x top, y right, z bottom, w left. y grows downward.
inline float bezelSide(float2 p, float2 halfSize, float rad, float4 edges) {
    if (edges.x > 0.5 && edges.y > 0.5 && edges.z > 0.5 && edges.w > 0.5) {
        return 1.0;
    }

    float2 ap = abs(p);
    float2 sgn = sign(p);
    sgn.x = sgn.x == 0.0 ? 1.0 : sgn.x;
    sgn.y = sgn.y == 0.0 ? 1.0 : sgn.y;
    float2 inner = max(halfSize - rad, float2(0.0));

    float horizontal = sgn.x > 0.0 ? edges.y : edges.w;
    float vertical = sgn.y > 0.0 ? edges.z : edges.x;

    // A corner exists only when both neighboring sides are on.
    // With no neighbor there is no tab to join, so there is no cut.
    if (ap.x >= inner.x && ap.y >= inner.y) {
        if (horizontal > 0.5 && vertical > 0.5) return 1.0;
        return 0.0;
    }

    float fromEnd = halfSize.y - ap.y;
    float fromSide = halfSize.x - ap.x;
    bool endStrip = fromEnd <= fromSide;
    float owner = endStrip ? vertical : horizontal;
    if (owner < 0.5) return 0.0;

    // Fade out before the corner line so the tip dies on its own edge.
    float neighborFree = 0.0;
    float room = 1.0;
    if (endStrip) {
        neighborFree = p.x < 0.0 ? (1.0 - edges.w) : (1.0 - edges.y);
        room = inner.x - ap.x;
    } else {
        neighborFree = p.y < 0.0 ? (1.0 - edges.x) : (1.0 - edges.z);
        room = inner.y - ap.y;
    }
    if (neighborFree > 0.5) {
        float fade = smoothstep(0.0, max(rad * 0.9, 28.0), room);
        return owner * fade;
    }
    return owner;
}

/// End curve.
/// height 0: ends on its own side. height 1: the tip reaches the neighbor.
/// No hard cut: the meeting with the glass is tangent.
inline float capProfile(float t, float startFree, float endFree, float convex, float height, float centralize) {
    if (startFree < 0.5 && endFree < 0.5) return 1.0;

    float x = saturate(t);
    // 0 touches and spills onto the neighbor. 1 stays centered and does not touch it.
    float span = mix(1.22, 0.32, saturate(centralize));
    float nx = (x - 0.5) / max(span * 0.5, 0.08);
    float hill = exp(-nx * nx * 1.35);
    float arch = sin(x * 3.14159265);

    if (startFree > 0.5 && endFree > 0.5) {
        if (convex > 0.5) {
            // Peak in the middle, tips on their own side. Height opens the curve toward the corner.
            return hill;
        }
        // Valley: high tips, low middle. Height 1 sets the tip against the neighbor.
        float valley = mix(0.12, 1.0, 1.0 - arch);
        float onOwnSide = hill * 0.28;
        return mix(onOwnSide, valley, saturate(height));
    }

    float fromFree = startFree > 0.5 ? x : (1.0 - x);
    float reach = mix(0.18, 0.55, saturate(height));
    float u = sin(saturate(fromFree / reach) * 1.5707963);
    if (convex > 0.5) return u;
    return mix(u, 1.0, saturate(height) * 0.9);
}

/// 1 in the middle of a loose edge when convex; 1 at the tips when concave.
/// Ends joined to a neighbor stay at 1. All sides on ignores this.
inline float endScale(float2 p, float2 halfSize, float rad, float4 edges, float convex, float height) {
    if (edges.x * edges.y * edges.z * edges.w > 0.5) return 1.0;

    float2 ap = abs(p);
    float2 inner = max(halfSize - rad, float2(0.0));
    bool corner = ap.x >= inner.x && ap.y >= inner.y;
    float horizOn = p.x >= 0.0 ? edges.y : edges.w;
    float vertOn = p.y >= 0.0 ? edges.z : edges.x;
    if (corner && horizOn > 0.5 && vertOn > 0.5) return 1.0;

    bool bottom = p.y >= 0.0 && edges.z > 0.5 && (ap.y >= inner.y || corner);
    bool top = p.y < 0.0 && edges.x > 0.5 && (ap.y >= inner.y || corner);
    if (bottom || top) {
        float t = saturate((p.x + halfSize.x) / max(halfSize.x * 2.0, 1.0));
        return capProfile(t, 1.0 - edges.w, 1.0 - edges.y, convex, height, 0.0);
    }
    bool right = p.x >= 0.0 && edges.y > 0.5 && (ap.x >= inner.x || corner);
    bool left = p.x < 0.0 && edges.w > 0.5 && (ap.x >= inner.x || corner);
    if (right || left) {
        float t = saturate((p.y + halfSize.y) / max(halfSize.y * 2.0, 1.0));
        return capProfile(t, 1.0 - edges.x, 1.0 - edges.z, convex, height, 0.0);
    }
    return 1.0;
}

/// Loose side: distance to that edge, across its full width.
/// Does not use the rectangle diagonal, or the fade becomes a triangle.
inline float coverAt(float d, float solid, float fade, float fadeColor, float peak) {
    if (d < -1.0) return 0.0;
    d = max(d, 0.0);
    float hold = max(solid, 0.0) * 0.62;
    float end = max(solid + fade, hold + 1.0);
    float continuous = 1.0 - smoothstep(hold, end, d);
    float intoFade = smoothstep(hold, min(solid + max(fade, 0.0) * 0.45, end), d);
    float strength = mix(1.0, max(fadeColor * peak, 0.0), intoFade);
    float glass = exp(-pow(d / 4.2, 2.0));
    return saturate(continuous * strength + glass * 0.25);
}

/// Each enabled side draws its own band. The union keeps a corner
/// from swallowing the other edge and leaving only a stub.
inline float edgeUnion(
    float2 p, float2 halfSize, float rad, float4 edges,
    float convex, float height, float centralize,
    float baseSolid, float baseFade, float fadeColor, float peak
) {
    float ring = 0.0;
    float fromBottom = halfSize.y - p.y;
    float fromTop = halfSize.y + p.y;
    float fromRight = halfSize.x - p.x;
    float fromLeft = halfSize.x + p.x;

    if (edges.z > 0.5 && fromBottom >= -1.0) {
        float t = saturate((p.x + halfSize.x) / max(halfSize.x * 2.0, 1.0));
        float m = capProfile(t, 1.0 - edges.w, 1.0 - edges.y, convex, height, centralize);
        ring = max(ring, coverAt(fromBottom, baseSolid * m, baseFade * m, fadeColor, peak));
    }
    if (edges.x > 0.5 && fromTop >= -1.0) {
        float t = saturate((p.x + halfSize.x) / max(halfSize.x * 2.0, 1.0));
        float m = capProfile(t, 1.0 - edges.w, 1.0 - edges.y, convex, height, centralize);
        ring = max(ring, coverAt(fromTop, baseSolid * m, baseFade * m, fadeColor, peak));
    }
    if (edges.y > 0.5 && fromRight >= -1.0) {
        float t = saturate((p.y + halfSize.y) / max(halfSize.y * 2.0, 1.0));
        float m = capProfile(t, 1.0 - edges.x, 1.0 - edges.z, convex, height, centralize);
        ring = max(ring, coverAt(fromRight, baseSolid * m, baseFade * m, fadeColor, peak));
    }
    if (edges.w > 0.5 && fromLeft >= -1.0) {
        float t = saturate((p.y + halfSize.y) / max(halfSize.y * 2.0, 1.0));
        float m = capProfile(t, 1.0 - edges.x, 1.0 - edges.z, convex, height, centralize);
        ring = max(ring, coverAt(fromLeft, baseSolid * m, baseFade * m, fadeColor, peak));
    }

    float2 ap = abs(p);
    float2 inner = max(halfSize - rad, float2(0.0));
    if (ap.x >= inner.x && ap.y >= inner.y) {
        float horizOn = p.x >= 0.0 ? edges.y : edges.w;
        float vertOn = p.y >= 0.0 ? edges.z : edges.x;
        if (horizOn > 0.5 && vertOn > 0.5) {
            float inward = max(-(roundedBoxSDF(p, halfSize, rad) + 0.4), 0.0);
            ring = max(ring, coverAt(inward, baseSolid, baseFade, fadeColor, peak));
        }
    }
    return ring;
}

inline float2 loneEdge(float2 p, float2 halfSize, float4 edges, float convex, float height, float centralize) {
    float bestM = 0.0;
    float bestD = 0.0;
    float fromBottom = halfSize.y - p.y;
    float fromTop = halfSize.y + p.y;
    float fromRight = halfSize.x - p.x;
    float fromLeft = halfSize.x + p.x;

    if (edges.z > 0.5 && fromBottom >= -1.0) {
        float t = saturate((p.x + halfSize.x) / max(halfSize.x * 2.0, 1.0));
        float m = capProfile(t, 1.0 - edges.w, 1.0 - edges.y, convex, height, centralize);
        if (m > bestM) { bestM = m; bestD = max(fromBottom, 0.0); }
    }
    if (edges.x > 0.5 && fromTop >= -1.0) {
        float t = saturate((p.x + halfSize.x) / max(halfSize.x * 2.0, 1.0));
        float m = capProfile(t, 1.0 - edges.w, 1.0 - edges.y, convex, height, centralize);
        if (m > bestM) { bestM = m; bestD = max(fromTop, 0.0); }
    }
    if (edges.y > 0.5 && fromRight >= -1.0) {
        float t = saturate((p.y + halfSize.y) / max(halfSize.y * 2.0, 1.0));
        float m = capProfile(t, 1.0 - edges.x, 1.0 - edges.z, convex, height, centralize);
        if (m > bestM) { bestM = m; bestD = max(fromRight, 0.0); }
    }
    if (edges.w > 0.5 && fromLeft >= -1.0) {
        float t = saturate((p.y + halfSize.y) / max(halfSize.y * 2.0, 1.0));
        float m = capProfile(t, 1.0 - edges.x, 1.0 - edges.z, convex, height, centralize);
        if (m > bestM) { bestM = m; bestD = max(fromLeft, 0.0); }
    }
    // 0 spills onto the neighbor with no hard cut. 1 stays centered and does not touch it.
    float spill = 1.0 - saturate(centralize);
    if (spill > 0.01) {
        float reachUp = 18.0 + spill * 72.0;
        float reachIn = 10.0 + spill * 36.0;
        if (edges.z > 0.5 && edges.w < 0.5 && p.x < 0.0 && fromBottom < reachUp && fromLeft < reachIn) {
            float m = smoothstep(reachUp, reachUp * 0.2, fromBottom) * smoothstep(reachIn, reachIn * 0.25, fromLeft) * spill;
            if (m > bestM) { bestM = m; bestD = fromLeft; }
        }
        if (edges.z > 0.5 && edges.y < 0.5 && p.x > 0.0 && fromBottom < reachUp && fromRight < reachIn) {
            float m = smoothstep(reachUp, reachUp * 0.2, fromBottom) * smoothstep(reachIn, reachIn * 0.25, fromRight) * spill;
            if (m > bestM) { bestM = m; bestD = fromRight; }
        }
        if (edges.x > 0.5 && edges.w < 0.5 && p.x < 0.0 && fromTop < reachUp && fromLeft < reachIn) {
            float m = smoothstep(reachUp, reachUp * 0.2, fromTop) * smoothstep(reachIn, reachIn * 0.25, fromLeft) * spill;
            if (m > bestM) { bestM = m; bestD = fromLeft; }
        }
        if (edges.x > 0.5 && edges.y < 0.5 && p.x > 0.0 && fromTop < reachUp && fromRight < reachIn) {
            float m = smoothstep(reachUp, reachUp * 0.2, fromTop) * smoothstep(reachIn, reachIn * 0.25, fromRight) * spill;
            if (m > bestM) { bestM = m; bestD = fromRight; }
        }
        if (edges.w > 0.5 && edges.z < 0.5 && p.y > 0.0 && fromLeft < reachUp && fromBottom < reachIn) {
            float m = smoothstep(reachUp, reachUp * 0.2, fromLeft) * smoothstep(reachIn, reachIn * 0.25, fromBottom) * spill;
            if (m > bestM) { bestM = m; bestD = fromBottom; }
        }
        if (edges.w > 0.5 && edges.x < 0.5 && p.y < 0.0 && fromLeft < reachUp && fromTop < reachIn) {
            float m = smoothstep(reachUp, reachUp * 0.2, fromLeft) * smoothstep(reachIn, reachIn * 0.25, fromTop) * spill;
            if (m > bestM) { bestM = m; bestD = fromTop; }
        }
        if (edges.y > 0.5 && edges.z < 0.5 && p.y > 0.0 && fromRight < reachUp && fromBottom < reachIn) {
            float m = smoothstep(reachUp, reachUp * 0.2, fromRight) * smoothstep(reachIn, reachIn * 0.25, fromBottom) * spill;
            if (m > bestM) { bestM = m; bestD = fromBottom; }
        }
        if (edges.y > 0.5 && edges.x < 0.5 && p.y < 0.0 && fromRight < reachUp && fromTop < reachIn) {
            float m = smoothstep(reachUp, reachUp * 0.2, fromRight) * smoothstep(reachIn, reachIn * 0.25, fromTop) * spill;
            if (m > bestM) { bestM = m; bestD = fromTop; }
        }
    }
    return float2(bestM, bestD);
}

/// One stop paints everything. Several stops travel the border and close the loop.
/// The glass (ribbon, fade, and highlight) does not depend on the color count.
inline half3 sampleStops(float t, device const half4 *stops, int count) {
    if (stops == nullptr || count < 1) return half3(1.0h);
    half3 first = stops[0].rgb / max(stops[0].a, 0.001h);
    if (count == 1) return first;

    float x = fract(t) * float(count);
    int i = min(int(x), count - 1);
    int j = i + 1;
    if (j >= count) j = 0;
    half4 a = stops[i];
    half4 b = stops[j];
    half3 ca = a.rgb / max(a.a, 0.001h);
    half3 cb = b.rgb / max(b.a, 0.001h);
    return mix(ca, cb, half(fract(x)));
}

inline half3 anchorColor(int i, half3 a, half3 b, half3 c, half3 d) {
    int k = i - (i / 4) * 4;
    if (k == 0) return a;
    if (k == 1) return b;
    if (k == 2) return c;
    return d;
}

inline float2 rimAnchor(int i, float time, float speed, float voice, float2 size) {
    float fi = float(i);
    float spin = time * speed * (0.22 + voice * 0.18) + fi * 1.2566;
    float2 radius = float2(size.x, size.y) * 0.47;
    float2 wobble = float2(sin(time * 0.17 + fi), cos(time * 0.13 + fi * 1.4)) * (6.0 + voice * 8.0);
    return size * 0.5 + float2(cos(spin), sin(spin)) * radius + wobble;
}

[[ stitchable ]] half4 bezelEdgeGlow(
    float2 position,
    half4 color,
    float2 size,
    float time,
    float cornerRadius,
    float bandWidth,
    float glowReach,
    float voice,
    float4 edges,
    float4 tuning,
    float4 look,
    float4 c0,
    float4 c1,
    float4 c2,
    float4 c3,
    device const half4 *stops,
    int stopCount
) {
    if (size.x < 2.0 || size.y < 2.0) return half4(0.0h);
    if (edges.x + edges.y + edges.z + edges.w < 0.5) return half4(0.0h);

    float waveOn = tuning.z;
    float convex = tuning.w;
    float waveSpeed = max(tuning.x, 0.05);
    float voiceColor = look.x;
    float fadeColor = look.y;
    float peak = look.z;
    float v = saturate(voice);

    float2 center = size * 0.5;
    float2 p = position - center;
    float radius = min(cornerRadius, min(center.x, center.y) - 1.0);
    radius = max(radius, 8.0);
    bool allSides = edges.x > 0.5 && edges.y > 0.5 && edges.z > 0.5 && edges.w > 0.5;

    float perim = fract((atan2(p.y, p.x) + 3.14159265) * 0.15915494);
    float waveCount = max(tuning.y, 1.0);
    float waveAmp = look.w;
    float undulation = 0.0;
    if (waveOn > 0.5) {
        undulation = sin((perim * waveCount - time * 0.12 * waveSpeed) * 6.2831853) * waveAmp;
    }

    float baseSolid = max(bandWidth + undulation, 0.0);
    float baseFade = max(glowReach + undulation, 0.0) * v;
    float ring = 0.0;
    if (!allSides) {
        ring = edgeUnion(p, center, radius, edges, convex, c3.w, c1.w, baseSolid, baseFade, fadeColor, peak);
    } else {
        float dist = roundedBoxSDF(p, center, radius);
        float d = max(-(dist + 0.4), 0.0);
        float inside = smoothstep(-0.3, 1.2, -(dist));
        float hold = baseSolid * 0.62;
        float end = max(baseSolid + baseFade, hold + 1.0);
        float continuous = (1.0 - smoothstep(hold, end, d)) * inside;
        float intoFade = smoothstep(hold, min(baseSolid + baseFade * 0.45, end), d);
        float strength = mix(1.0, max(fadeColor * peak, 0.0), intoFade);
        float glass = exp(-pow(d / 4.2, 2.0)) * inside;
        ring = saturate(continuous * strength + glass * 0.25);
    }
    if (ring < 0.003) return half4(0.0h);

    float shift = waveOn > 0.5 ? time * 0.07 * waveSpeed : 0.0;

    half3 base = sampleStops(perim + shift, stops, stopCount);
    half luma = dot(base, half3(0.299h, 0.587h, 0.114h));
    half3 lit = clamp(base + (base - half3(luma)) * half(voiceColor * v), 0.0h, 1.0h);

    float alpha = saturate(ring);
    return half4(lit * half(alpha), half(alpha));
}
