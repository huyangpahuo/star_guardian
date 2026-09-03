extern number time;

vec4 position(mat4 transform_projection, vec4 vertex_position)
{
    return transform_projection * vertex_position;
}

vec4 effect(vec4 color, Image texture, vec2 tc, vec2 sc)
{
    vec2 uv = tc;
    vec4 c = Texel(texture, uv);
    float scan = 0.98 + 0.02 * sin((sc.y + time * 35.0) * 0.06);
    float mask = 0.97 + 0.03 * sin(sc.x * 0.03);
    float curve = 1.0 - 0.04 * pow((uv.x - 0.5) * 2.0, 2.0) - 0.04 * pow((uv.y - 0.5) * 2.0, 2.0);
    float vignette = 1.0 - smoothstep(0.35, 0.95, length((sc / love_ScreenSize.xy) - 0.5) * 1.3);
    c.rgb *= scan * mask * curve * vignette;
    c.rgb = mix(c.rgb, vec3(dot(c.rgb, vec3(0.299, 0.587, 0.114))), 0.02);
    return c * color;
}
