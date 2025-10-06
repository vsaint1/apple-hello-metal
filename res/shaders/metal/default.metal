#include <metal_stdlib>
using namespace metal;

struct VertexIn {
    float3 a_position [[attribute(0)]];
    float3 a_color    [[attribute(1)]];
    float2 a_texcoord [[attribute(2)]];
};

struct Uniforms {
    float4x4 model;
    float4x4 view;
    float4x4 projection;
};

struct VertexOut {
    float4 position [[position]];
    float3 color;
    float2 texcoord;
};

vertex VertexOut vertex_main(VertexIn in [[stage_in]],
                             constant Uniforms& u [[buffer(1)]])
{
    VertexOut out;
    float4 world_pos = u.model * float4(in.a_position, 1.0);
    out.position = u.projection * u.view * world_pos;
    out.color = in.a_color;
    out.texcoord = in.a_texcoord;
    return out;
}

fragment float4 fragment_main(VertexOut in [[stage_in]])
{
    // simple shaded color
    return float4(in.color, 1.0);
}
