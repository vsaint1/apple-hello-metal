#include <metal_stdlib>
using namespace metal;

struct VertexIn {
    float3 a_pos [[attribute(0)]];
    float3 a_color    [[attribute(1)]];
    float2 a_tex_coord       [[attribute(2)]];
};

struct Uniforms {
    float4x4 model;
    float4x4 view;
    float4x4 projection;
};

struct VertexOut {
    float4 position [[position]];
    float3 color;
};

vertex VertexOut vertex_main(VertexIn in [[stage_in]],
                             constant Uniforms &u [[buffer(1)]]) {
    VertexOut out;
    float4 pos = float4(in.a_pos, 1.0);
    out.position = u.projection * u.view * u.model * pos;
    out.color = in.a_color;
    return out;
}

fragment float4 fragment_main(VertexOut in [[stage_in]]) {
    return float4(in.color, 1.0);
}
