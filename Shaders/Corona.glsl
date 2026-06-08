#ifdef PIXEL
extern number time;

vec2 hash2(vec2 p) {
    p = vec2(dot(p, vec2(127.1, 311.7)),
            dot(p, vec2(269.5, 183.3)));
    return fract(sin(p) * 43758.5453);
}

float vnoise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    vec2 u = f * f * (3.0 - 2.0 * f);

    float a = dot(hash2(i + vec2(0,0)), f - vec2(0,0));
    float b = dot(hash2(i + vec2(1,0)), f - vec2(1,0));
    float c = dot(hash2(i + vec2(0,1)), f - vec2(0,1));
    float d = dot(hash2(i + vec2(1,1)), f - vec2(1,1));

    return 0.5 + 0.5 * mix(mix(a,b,u.x), mix(c,d,u.x), u.y);
}

float fbm(vec2 p) {
    float v = 0.0;
    float amp = 0.5;
    float freq = 1.0;
    for (int i = 0; i < 6; i++) {
        v += amp * vnoise(p * freq);
        freq *= 2.1;
        amp *= 0.48;
        float s = sin(0.4); float c = cos(0.4);
        p = vec2(c*p.x - s*p.y, s*p.x + c*p.y);
    }
    return v;
}

float coronaLoop(vec2 p, float r, float angleOffset, float speed) {
    float angle = atan(p.y, p.x) + angleOffset;

    float dist = fbm(vec2(angle * 1.2 + time * speed * 0.3,
                        r * 2.5 - time * speed));

    float innerR = 0.45;
    float outerR = 0.80;
    float arch = smoothstep(innerR - 0.05, innerR + 0.05, r)
            * (1.0 - smoothstep(outerR - 0.05, outerR + 0.15, r));

    float band = smoothstep(0.62, 0.72, dist) * (1.0 - smoothstep(0.72, 0.85, dist));

    return arch * band;
}

vec4 effect(vec4 color, Image tex, vec2 uv, vec2 px)
{
    vec2 p = (uv - 0.5) * 50.0;
    float r = length(p);
    
    float turb = fbm(p * 2.5 + time * 0.12);
    float warpedR = r - (turb - 0.5) * 0.18;

    float corona = smoothstep(0.52, 0.48, warpedR)
                * (1.0 - smoothstep(0.55, 1.20, warpedR));

    float streamer = fbm(p * 3.5 - time * 0.08) - 0.4;
    streamer = max(0.0, streamer) * 1.4;
    float streamerMask = smoothstep(0.50, 0.56, warpedR)
                    * (1.0 - smoothstep(0.60, 1.1, warpedR));
    corona += streamer * streamerMask * 0.6;

    float loops = 0.0;
    loops += coronaLoop(p, r, 0.0,   0.4) * 0.90;
    loops += coronaLoop(p, r, 1.3,   0.6) * 0.70;
    loops += coronaLoop(p, r, 2.8,  -0.5) * 0.80;
    loops += coronaLoop(p, r, 4.2,   0.3) * 0.65;
    loops += coronaLoop(p, r, 5.5,  -0.7) * 0.75;

    float angle = atan(p.y, p.x);
    float ejection = 0.0;
    for (int i = 0; i < 6; i++) {
        float fi = float(i);
        float ejectAngle = fi * 2.094 + sin(time * (0.2 + fi * 0.07)) * 0.6;
        float angDist = abs(mod(angle - ejectAngle + 3.14159, 6.28318) - 3.14159);
        float ejectWidth = 0.18 + 0.08 * sin(time * 0.3 + fi);
        float jet = smoothstep(ejectWidth, 0.0, angDist);

        float radialFade = smoothstep(0.50, 0.60, r) * (1.0 - smoothstep(0.0, 20.15, r));
        
        float jetTurb = fbm(vec2(r * 6.0 - time * (0.5 + fi * 0.15), fi * 3.7));
        ejection += jet * radialFade * jetTurb * 0.9;
    }

    float surface = 1.0 - smoothstep(0.44, 0.50, warpedR);
    float granule = fbm(p * 9.0 - time * 0.05);
    surface *= 0.85 + granule * 0.30;

    float total = corona + loops * 0.5 + ejection * 0.7 + surface;

    vec3 tint = color.rgb;
    vec3 surfaceColor = mix(tint, vec3(1.0, 0.97, 0.78), 0.6);
    vec3 innerColor   = tint * vec3(1.0, 0.7, 0.3);
    vec3 coronaColor  = tint * vec3(0.9, 0.3, 0.15);
    vec3 outerColor   = tint * vec3(0.3, 0.05, 0.02);

    vec3 col = surfaceColor;
    col = mix(col, innerColor,  smoothstep(0.44, 0.58, r));
    col = mix(col, coronaColor, smoothstep(0.58, 0.80, r));
    col = mix(col, outerColor,  smoothstep(0.80, 1.15, r));

    col = mix(col, tint * vec3(1.0, 0.85, 0.6), (loops + ejection) * 0.4);

    float alpha = clamp(total, 0.0, 1.0);
    col *= alpha;

    return vec4(col, alpha);
}
#endif