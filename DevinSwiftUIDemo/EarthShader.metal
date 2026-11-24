#include <metal_stdlib>
using namespace metal;

namespace {

// MARK: - Hash & 3D Value Noise

float hash31(float3 p) {
    p = fract(p * 0.1031);
    p += dot(p, p.yzx + 33.33);
    return fract((p.x + p.y) * p.z);
}

float hash21(float2 p) {
    float3 p3 = fract(float3(p.xyx) * 0.1031);
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.x + p3.y) * p3.z);
}

float noise3D(float3 p) {
    float3 i = floor(p);
    float3 f = fract(p);
    float3 u = f * f * (3.0 - 2.0 * f);

    float n000 = hash31(i + float3(0.0, 0.0, 0.0));
    float n100 = hash31(i + float3(1.0, 0.0, 0.0));
    float n010 = hash31(i + float3(0.0, 1.0, 0.0));
    float n110 = hash31(i + float3(1.0, 1.0, 0.0));
    float n001 = hash31(i + float3(0.0, 0.0, 1.0));
    float n101 = hash31(i + float3(1.0, 0.0, 1.0));
    float n011 = hash31(i + float3(0.0, 1.0, 1.0));
    float n111 = hash31(i + float3(1.0, 1.0, 1.0));

    float nx00 = mix(n000, n100, u.x);
    float nx10 = mix(n010, n110, u.x);
    float nx01 = mix(n001, n101, u.x);
    float nx11 = mix(n011, n111, u.x);

    float nxy0 = mix(nx00, nx10, u.y);
    float nxy1 = mix(nx01, nx11, u.y);

    return mix(nxy0, nxy1, u.z);
}

float fbm(float3 p, int octaves) {
    float value = 0.0;
    float amplitude = 0.5;
    float frequency = 1.0;

    for (int i = 0; i < octaves; ++i) {
        value += amplitude * noise3D(p * frequency);
        // Slight rotation per octave reduces grid alignment artifacts.
        p = float3(
            0.80 * p.x + 0.60 * p.z,
            p.y,
            -0.60 * p.x + 0.80 * p.z
        );
        frequency *= 2.05;
        amplitude *= 0.5;
    }
    return value;
}

// MARK: - 3D Rotations

float3 rotateX(float3 v, float angle) {
    float s = sin(angle);
    float c = cos(angle);
    return float3(v.x, c * v.y - s * v.z, s * v.y + c * v.z);
}

float3 rotateY(float3 v, float angle) {
    float s = sin(angle);
    float c = cos(angle);
    return float3(c * v.x + s * v.z, v.y, -s * v.x + c * v.z);
}

float3 rotateZ(float3 v, float angle) {
    float s = sin(angle);
    float c = cos(angle);
    return float3(c * v.x - s * v.y, s * v.x + c * v.y, v.z);
}

// MARK: - Space Background & Starfield

float3 starLayer(float2 uv, float scale, float density, float time) {
    float2 grid = uv * scale;
    float2 cell = floor(grid);
    float2 local = fract(grid) - 0.5;

    float rnd = hash21(cell);
    if (rnd < density) {
        return float3(0.0);
    }

    float2 jitter = float2(hash21(cell + 19.1), hash21(cell + 47.7)) - 0.5;
    float2 delta = local - jitter * 0.65;
    float dist = length(delta);

    float starSize = mix(0.025, 0.085, fract(rnd * 73.1));
    float core = smoothstep(starSize, 0.0, dist);
    float twinkle = 0.78 + 0.22 * sin(time * (1.2 + fract(rnd * 31.7) * 2.5) + rnd * 62.83);

    float temp = fract(rnd * 19.3);
    float3 starColor = mix(float3(0.75, 0.86, 1.0), float3(1.0, 0.93, 0.82), temp);
    return starColor * (core * core) * twinkle;
}

float3 spaceBackground(float2 position, float2 size, float time) {
    float2 uv = (position - 0.5 * size) / min(size.x, size.y);

    // Deep cosmic gradient with a subtle blue-violet nebula band
    float3 base = mix(float3(0.010, 0.014, 0.032), float3(0.004, 0.006, 0.015), clamp(length(uv), 0.0, 1.0));
    float nebula = fbm(float3(uv * 2.2, 0.4), 3);
    base += float3(0.020, 0.035, 0.075) * smoothstep(0.42, 0.82, nebula) * 0.55;

    float3 stars = float3(0.0);
    stars += starLayer(uv, 24.0, 0.965, time) * 1.15;
    stars += starLayer(uv + float2(3.7, 1.9), 48.0, 0.972, time) * 0.75;
    stars += starLayer(uv + float2(7.3, 5.1), 90.0, 0.980, time) * 0.45;

    return base + stars;
}

// MARK: - Procedural Earth Surface

struct SurfaceSample {
    float3 albedo;
    float roughness;
    float isLand;
    float cityMask;
};

SurfaceSample sampleEarthSurface(float3 p) {
    // Domain-warped FBM for organic continental shapes
    float3 warp = float3(
        fbm(p * 1.8 + float3(3.1, 1.7, 2.3), 3),
        fbm(p * 1.8 + float3(7.4, 5.2, 1.1), 3),
        fbm(p * 1.8 + float3(2.8, 9.1, 6.5), 3)
    ) - 0.5;

    float3 warped = p + warp * 0.48;
    float continent = fbm(warped * 2.15, 5);
    float detail = fbm(warped * 8.5, 3);
    float elevation = continent + (detail - 0.5) * 0.14;

    float seaLevel = 0.565;
    float landMask = smoothstep(seaLevel - 0.010, seaLevel + 0.014, elevation);

    // Ocean colors: deep cobalt-navy to vibrant coastal turquoise
    float oceanDepth = clamp((seaLevel - elevation) / 0.30, 0.0, 1.0);
    float3 deepOcean = float3(0.012, 0.055, 0.195);
    float3 midOcean = float3(0.024, 0.145, 0.390);
    float3 shallowOcean = float3(0.055, 0.340, 0.540);
    float3 oceanColor = mix(shallowOcean, midOcean, smoothstep(0.0, 0.18, oceanDepth));
    oceanColor = mix(oceanColor, deepOcean, smoothstep(0.14, 0.78, oceanDepth));

    // Land biomes by latitude & elevation
    float lat = abs(p.y);
    float heightAboveSea = clamp((elevation - seaLevel) / 0.25, 0.0, 1.0);
    float moisture = fbm(p * 3.8 + float3(12.3, 4.5, 8.9), 4);

    float3 coastSand = float3(0.58, 0.54, 0.39);
    float3 lushForest = float3(0.06, 0.24, 0.09);
    float3 savanna = float3(0.24, 0.34, 0.13);
    float3 desert = float3(0.64, 0.51, 0.32);
    float3 mountainRock = float3(0.32, 0.30, 0.28);
    float3 snowCap = float3(0.90, 0.94, 0.98);

    // Subtropical desert belt around |lat| ~ 0.25 - 0.48
    float desertBelt = exp(-pow((lat - 0.34) / 0.18, 2.0)) * smoothstep(0.35, 0.70, 1.0 - moisture);
    float3 lowland = mix(lushForest, savanna, smoothstep(0.35, 0.65, moisture));
    lowland = mix(lowland, desert, desertBelt * 0.80);
    lowland = mix(coastSand, lowland, smoothstep(0.0, 0.07, heightAboveSea));

    float3 landColor = mix(lowland, mountainRock, smoothstep(0.42, 0.74, heightAboveSea));
    landColor = mix(landColor, snowCap, smoothstep(0.72, 0.90, heightAboveSea));

    float3 surface = mix(oceanColor, landColor, landMask);

    // Polar ice caps with noisy glacial edges
    float polarNoise = (detail - 0.5) * 0.12;
    float polarCap = smoothstep(0.79, 0.88, lat + polarNoise);
    surface = mix(surface, float3(0.88, 0.93, 0.98), polarCap);

    // Night-side city light clusters on habitable low-to-mid latitude land
    float cityCluster = noise3D(p * 18.0 + 4.2);
    float cityPinpoint = noise3D(p * 68.0) * noise3D(p * 115.0 + 9.3);
    float habitableLat = 1.0 - smoothstep(0.58, 0.76, lat);
    float coastalBonus = smoothstep(0.0, 0.08, heightAboveSea) * (1.0 - smoothstep(0.18, 0.42, heightAboveSea));
    float cityMask = smoothstep(0.48, 0.72, cityCluster) * smoothstep(0.42, 0.68, cityPinpoint) * landMask * (1.0 - polarCap) * habitableLat * (0.45 + 0.55 * coastalBonus);

    SurfaceSample out;
    out.albedo = surface;
    out.roughness = mix(0.22, 0.88, max(landMask, polarCap));
    out.isLand = max(landMask, polarCap);
    out.cityMask = cityMask;
    return out;
}

float sampleClouds(float3 p, float cloudRotation) {
    float3 cp = rotateY(p, cloudRotation);
    float3 swirl = float3(
        fbm(cp * 2.5 + float3(5.2, 1.3, 8.7), 3),
        fbm(cp * 2.5 + float3(1.9, 6.4, 3.1), 3),
        fbm(cp * 2.5 + float3(8.1, 2.7, 4.9), 3)
    ) - 0.5;

    // Slight latitudinal banding for trade-wind streaks
    float3 windP = float3(cp.x * 2.6, cp.y * 3.8, cp.z * 2.6) + swirl * 0.85;
    float n = fbm(windP, 5);
    return smoothstep(0.49, 0.74, n);
}

} // namespace

[[ stitchable ]] half4 earthShader(
    float2 position,
    half4 currentColor,
    float2 size,
    float rotation,
    float tilt,
    float time
) {
    if (size.x <= 0.0 || size.y <= 0.0) {
        return currentColor;
    }

    float minDim = min(size.x, size.y);
    float radius = minDim * 0.39;
    float2 center = size * 0.5;
    float2 p = (position - center) / radius;
    float distSq = dot(p, p);
    float dist = sqrt(distSq);

    // Directional sunlight from upper-front-left
    float3 lightDir = normalize(float3(-0.68, 0.32, 0.66));
    float3 viewDir = float3(0.0, 0.0, 1.0);

    // Background space with twinkling stars
    float3 bg = spaceBackground(position, size, time);

    // Outer atmospheric scattering halo (visible around the limb in space)
    float3 haloNormal = normalize(float3(p.x, -p.y, 0.15));
    float haloSun = smoothstep(-0.35, 0.75, dot(haloNormal, lightDir));
    float haloFalloff = exp(-max(dist - 0.99, 0.0) * 8.5);
    float3 outerAtmosphere = float3(0.24, 0.58, 1.0) * haloFalloff * (0.18 + 0.82 * haloSun) * 0.75;
    bg += outerAtmosphere;

    // Anti-aliased edge mask for the sphere silhouette
    float aaWidth = max(1.5 / radius, 0.0025);
    float sphereMask = 1.0 - smoothstep(1.0 - aaWidth, 1.0 + aaWidth, dist);
    if (sphereMask <= 0.0001) {
        return half4(half3(clamp(bg, 0.0, 1.0)), 1.0h);
    }

    // Sphere surface point & normal in view space (flip Y for SwiftUI top-left origin)
    float z = sqrt(max(0.0, 1.0 - min(distSq, 1.0)));
    float3 normal = normalize(float3(p.x, -p.y, z));

    // Transform normal into Earth's local rotating frame:
    // 1. Axial obliquity (~23.4 deg) around Z
    // 2. Interactive vertical tilt around X
    // 3. Spin around Earth's polar Y axis
    float3 localP = rotateZ(normal, 0.408);
    localP = rotateX(localP, tilt);
    float3 earthP = rotateY(localP, -rotation);

    SurfaceSample surface = sampleEarthSurface(earthP);

    // Cloud layer rotates slightly faster than the planet surface
    float cloudDrift = -rotation * 1.18 - 0.35;
    float cloudDensity = sampleClouds(localP, cloudDrift);

    // Subtle cloud shadow projected onto the surface along the light direction
    float3 shadowSampleP = normalize(localP + lightDir * 0.025);
    float cloudShadow = sampleClouds(shadowSampleP, cloudDrift);

    // Lighting terms
    float ndotl = dot(normal, lightDir);
    float diffuse = smoothstep(-0.08, 0.95, ndotl);
    float shadowFactor = 1.0 - cloudShadow * 0.35 * diffuse;

    // Warm sunset/sunrise glow along the day-night terminator
    float terminator = exp(-pow(ndotl / 0.13, 2.0));
    float3 terminatorTint = float3(0.85, 0.34, 0.12) * terminator * 0.10;

    // Specular sun glint on oceans
    float3 halfVec = normalize(lightDir + viewDir);
    float specAngle = max(dot(normal, halfVec), 0.0);
    float oceanSpec = pow(specAngle, 48.0) * (1.0 - surface.isLand) * (1.0 - cloudDensity * 0.85) * smoothstep(0.0, 0.25, ndotl);
    float3 specularColor = float3(0.95, 0.97, 1.0) * oceanSpec * 0.55;

    // Night-side ambient + golden city lights
    float nightMask = smoothstep(0.08, -0.22, ndotl);
    float3 nightAmbient = surface.albedo * float3(0.020, 0.032, 0.068);
    float3 cityLights = float3(1.0, 0.80, 0.42) * surface.cityMask * nightMask * (1.0 - cloudDensity * 0.75) * 1.9;

    float3 litSurface = surface.albedo * (diffuse * shadowFactor * 1.25 + 0.025) + nightAmbient + terminatorTint + specularColor + cityLights;

    // Cloud shading
    float3 cloudDay = float3(0.96, 0.98, 1.0) * (0.08 + 0.94 * diffuse);
    float3 cloudSunset = float3(0.92, 0.46, 0.22) * terminator * 0.16;
    float3 cloudNight = float3(0.025, 0.042, 0.090) * nightMask;
    float3 cloudColor = cloudDay + cloudSunset + cloudNight;

    float3 planetColor = mix(litSurface, cloudColor, cloudDensity * 0.82);

    // Atmospheric Fresnel rim scattering
    float fresnel = pow(1.0 - max(normal.z, 0.0), 3.4);
    float rimSun = smoothstep(-0.35, 0.65, ndotl);
    float3 rimColor = mix(float3(0.14, 0.42, 0.95), float3(0.42, 0.78, 1.0), rimSun);
    planetColor += rimColor * fresnel * (0.16 + 0.92 * rimSun);

    // Gentle ACES-like highlight rolloff preserving deep blues & greens
    planetColor = planetColor / (planetColor + 0.45) * 1.38;

    float3 finalColor = mix(bg, planetColor, sphereMask);
    return half4(half3(clamp(finalColor, 0.0, 1.0)), 1.0h);
}
