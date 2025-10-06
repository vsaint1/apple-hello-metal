#include <metal_stdlib>
using namespace metal;

struct VertexIn {
    vector_float3 position [[attribute(0)]];
    vector_float2 texcoord [[attribute(2)]];
    vector_float3 color [[attribute(1)]];
};


