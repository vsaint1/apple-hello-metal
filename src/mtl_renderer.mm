#import "mtl_renderer.h"
#include "SDL3/SDL_log.h"
#include "SDL3/SDL_metal.h"
#include "SDL3/SDL_video.h"
#include <Foundation/Foundation.h>
#import <Metal/Metal.h>
#import <QuartzCore/CAMetalLayer.h>

// ------------------------------------------------------------------
// NOTE: This file uses __bridge_retained / __bridge_transfer so that
// we can store Obj-C objects in void* members while keeping ARC safe.
// Preferably change your header to use Objective-C types directly.
// ------------------------------------------------------------------

bool MetalRenderer::initialize(SDL_Window *window) {
  _window = window;

  glm::ivec2 size;
  SDL_GetWindowSize(window, &size.x, &size.y);

  id<MTLDevice> device = MTLCreateSystemDefaultDevice();
  if (!device)
    return false;

  _metal_view = SDL_Metal_CreateView(window);
  if (!_metal_view)
    return false;

  CAMetalLayer *layer =
      (__bridge CAMetalLayer *)SDL_Metal_GetLayer(_metal_view);
  layer.device = device;
  layer.pixelFormat = MTLPixelFormatBGRA8Unorm;
  layer.framebufferOnly = YES;
  layer.drawableSize = CGSizeMake(size.x, size.y);
  _metal_layer = (__bridge_retained void *)layer;
  _device = (__bridge_retained void *)device;

  // Depth texture
  MTLTextureDescriptor *depthDesc = [[MTLTextureDescriptor alloc] init];
  depthDesc.pixelFormat = MTLPixelFormatDepth32Float;
  depthDesc.width = size.x;
  depthDesc.height = size.y;
  depthDesc.usage = MTLTextureUsageRenderTarget;
  depthDesc.storageMode = MTLStorageModeMemoryless;
  _depth_texture =
      (__bridge_retained void *)[device newTextureWithDescriptor:depthDesc];

  setup_default_shaders();

  id<MTLCommandQueue> queue = [device newCommandQueue];
  _command_queue = (__bridge_retained void *)queue;

  create_cube_mesh();

  return true;
}

void MetalRenderer::setup_default_shaders() {
  NSError *error = nil;
  id<MTLDevice> device = (__bridge id<MTLDevice>)_device;
  id<MTLLibrary> library = [device newDefaultLibrary];

  id<MTLFunction> vertFunc = [library newFunctionWithName:@"vertex_main"];
  id<MTLFunction> fragFunc = [library newFunctionWithName:@"fragment_main"];

  MTLRenderPipelineDescriptor *pDesc =
      [[MTLRenderPipelineDescriptor alloc] init];
  pDesc.vertexFunction = vertFunc;
  pDesc.fragmentFunction = fragFunc;
  pDesc.colorAttachments[0].pixelFormat = MTLPixelFormatBGRA8Unorm;
  pDesc.depthAttachmentPixelFormat = MTLPixelFormatDepth32Float;

  MTLVertexDescriptor *vd = [[MTLVertexDescriptor alloc] init];
  vd.attributes[0].format = MTLVertexFormatFloat3;
  vd.attributes[0].offset = 0;
  vd.attributes[0].bufferIndex = 0;
  vd.attributes[1].format = MTLVertexFormatFloat3;
  vd.attributes[1].offset = sizeof(float) * 3;
  vd.attributes[1].bufferIndex = 0;
  vd.attributes[2].format = MTLVertexFormatFloat2;
  vd.attributes[2].offset = sizeof(float) * 6;
  vd.attributes[2].bufferIndex = 0;
  vd.layouts[0].stride = sizeof(Vertex);
  vd.layouts[0].stepRate = 1;
  vd.layouts[0].stepFunction = MTLVertexStepFunctionPerVertex;
  pDesc.vertexDescriptor = vd;

  _pipeline = (__bridge_retained void *)[device
      newRenderPipelineStateWithDescriptor:pDesc
                                     error:&error];
  if (!_pipeline) {
    SDL_Log("Failed to create pipeline state: %s",
            error.localizedDescription.UTF8String);
  }

  MTLDepthStencilDescriptor *depthDesc =
      [[MTLDepthStencilDescriptor alloc] init];
  depthDesc.depthCompareFunction = MTLCompareFunctionLess;
  depthDesc.depthWriteEnabled = YES;
  _depth_stencil_state = (__bridge_retained void *)[device
      newDepthStencilStateWithDescriptor:depthDesc];
}

void MetalRenderer::create_cube_mesh() {
  id<MTLDevice> device = (__bridge id<MTLDevice>)_device;
  std::srand((unsigned int)time(nullptr));

  constexpr int count = 100'000'0;
  std::vector<Vertex> vertices;
  std::vector<uint16_t> indices;

  // gpt chad
  auto push_cube = [&](glm::vec3 pos, glm::vec3 color) {
    glm::vec3 offsets[8] = {{-0.5f, -0.5f, 0.5f},  {0.5f, -0.5f, 0.5f},
                            {0.5f, 0.5f, 0.5f},    {-0.5f, 0.5f, 0.5f},
                            {-0.5f, -0.5f, -0.5f}, {0.5f, -0.5f, -0.5f},
                            {0.5f, 0.5f, -0.5f},   {-0.5f, 0.5f, -0.5f}};

    glm::vec2 uv[4] = {{0, 0}, {1, 0}, {1, 1}, {0, 1}};

    uint16_t base = static_cast<uint16_t>(vertices.size());

    for (int i = 0; i < 8; i++)
      vertices.push_back({pos + offsets[i], color, uv[i % 4]});

    uint16_t cubeIdx[36] = {0, 1, 2, 2, 3, 0, 1, 5, 6, 6, 2, 1,
                            5, 4, 7, 7, 6, 5, 4, 0, 3, 3, 7, 4,
                            3, 2, 6, 6, 7, 3, 4, 5, 1, 1, 0, 4};

    for (int i = 0; i < 36; i++)
      indices.push_back(base + cubeIdx[i]);
  };

  for (int i = 0; i < count; i++) {
    glm::vec3 pos = {((float)rand() / RAND_MAX) * 50.0f - 25.0f,
                     ((float)rand() / RAND_MAX) * 50.0f - 25.0f,
                     ((float)rand() / RAND_MAX) * -50.0f};
    glm::vec3 color = {(float)rand() / RAND_MAX, (float)rand() / RAND_MAX,
                       (float)rand() / RAND_MAX};
    push_cube(pos, color);
  }

  _num_indices = (int)indices.size();
  _vertex_buffer = (__bridge_retained void *)[device
      newBufferWithBytes:vertices.data()
                  length:sizeof(Vertex) * vertices.size()
                 options:MTLResourceStorageModeShared];
  _index_buffer = (__bridge_retained void *)[device
      newBufferWithBytes:indices.data()
                  length:sizeof(uint16_t) * indices.size()
                 options:MTLResourceStorageModeShared];

  SDL_Log("Created a CommandBuffer with %d random cube meshes (%d indices)",
          count, _num_indices);
}

void MetalRenderer::clear(const glm::vec4 &color) {
  @autoreleasepool {
    id<CAMetalDrawable> drawable =
        [(__bridge CAMetalLayer *)_metal_layer nextDrawable];
    id<MTLCommandQueue> queue = (__bridge id<MTLCommandQueue>)_command_queue;
    id<MTLCommandBuffer> cmd = [queue commandBuffer];

    MTLRenderPassDescriptor *pass =
        [MTLRenderPassDescriptor renderPassDescriptor];
    pass.colorAttachments[0].texture = drawable.texture;
    pass.colorAttachments[0].loadAction = MTLLoadActionClear;
    pass.colorAttachments[0].storeAction = MTLStoreActionStore;
    pass.colorAttachments[0].clearColor =
        MTLClearColorMake(color.r, color.g, color.b, color.a);

    pass.depthAttachment.texture = (__bridge id<MTLTexture>)_depth_texture;
    pass.depthAttachment.loadAction = MTLLoadActionClear;
    pass.depthAttachment.storeAction = MTLStoreActionDontCare;
    pass.depthAttachment.clearDepth = 1.0;

    _current_drawable = (__bridge_retained void *)drawable;
    _current_command_buffer = (__bridge_retained void *)cmd;
    _current_pass = (__bridge_retained void *)pass;
  }
}

void MetalRenderer::flush(const glm::mat4 &view, const glm::mat4 &projection) {
  @autoreleasepool {
    if (!_current_drawable || !_current_command_buffer || !_current_pass)
      return;

    id<MTLRenderCommandEncoder> enc = [(
        __bridge id<MTLCommandBuffer>)_current_command_buffer
        renderCommandEncoderWithDescriptor:(__bridge MTLRenderPassDescriptor *)
                                               _current_pass];

    [enc setRenderPipelineState:(__bridge id<MTLRenderPipelineState>)_pipeline];
    [enc setDepthStencilState:(__bridge id<MTLDepthStencilState>)
                                  _depth_stencil_state];

    Uniforms u;
    u.model = glm::mat4(1.0f);
    u.view = view;
    u.projection = projection;

    id<MTLDevice> device = (__bridge id<MTLDevice>)_device;
    id<MTLBuffer> uniformBuf =
        [device newBufferWithBytes:&u
                            length:sizeof(u)
                           options:MTLResourceStorageModeShared];

    [enc setVertexBuffer:(__bridge id<MTLBuffer>)_vertex_buffer
                  offset:0
                 atIndex:0];
    [enc setVertexBuffer:uniformBuf offset:0 atIndex:1];
    [enc drawIndexedPrimitives:MTLPrimitiveTypeTriangle
                    indexCount:_num_indices
                     indexType:MTLIndexTypeUInt16
                   indexBuffer:(__bridge id<MTLBuffer>)_index_buffer
             indexBufferOffset:0];

    [enc endEncoding];
  }
}

void MetalRenderer::present() {
  @autoreleasepool {
    [(__bridge id<MTLCommandBuffer>)_current_command_buffer
        presentDrawable:(__bridge id<CAMetalDrawable>)_current_drawable];
    [(__bridge id<MTLCommandBuffer>)_current_command_buffer commit];

    CFBridgingRelease(_current_drawable);
    CFBridgingRelease(_current_command_buffer);
    if (_current_pass)
      CFBridgingRelease(_current_pass);

    _current_drawable = nullptr;
    _current_command_buffer = nullptr;
    _current_pass = nullptr;
  }
}

MetalRenderer::~MetalRenderer() { destroy(); }

void MetalRenderer::destroy() {
  SDL_Log("MetalRenderer::destroy");

  if (_pipeline) {
    (void)_pipeline; // releases pipeline
    _pipeline = nullptr;
  }
  if (_command_queue) {
    (void)_command_queue; // releases command queue
    _command_queue = nullptr;
  }
  if (_device) {
    (void)_device; // releases device
    _device = nullptr;
  }
  if (_metal_layer) {
    (void)_metal_layer; // releases layer
    _metal_layer = nullptr;
  }

  if (_vertex_buffer) {
    (void)_vertex_buffer; // releases vertex buffer
    _vertex_buffer = nullptr;
  }

  if (_index_buffer) {
    (void)_index_buffer; // releases index buffer
    _index_buffer = nullptr;
  }

  if (_depth_texture) {
    (void)_depth_texture; // releases depth texture
    _depth_texture = nullptr;
  }

  if (_depth_stencil_state) {
    (void)_depth_stencil_state; // releases depth stencil state
    _depth_stencil_state = nullptr;
  }

  if (_metal_view) {
    SDL_Metal_DestroyView(_metal_view);
    _metal_view = nullptr;
  }
}
