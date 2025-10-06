#import "mtl_renderer.h"
#include "SDL3/SDL_log.h"
#include "SDL3/SDL_metal.h"
#include "SDL3/SDL_video.h"
#include "glm/fwd.hpp"
#include <AvailabilityVersions.h>
#include <Foundation/Foundation.h>

#import <Metal/Metal.h>
#import <QuartzCore/CAMetalLayer.h>
#import <QuartzCore/QuartzCore.h>

// ------------------------------------------------------------------
// NOTE: This file uses __bridge_retained / __bridge_transfer so that
// we can store Obj-C objects in void* members while keeping ARC safe.
// Preferably change your header to use Objective-C types directly.
// ------------------------------------------------------------------

bool MetalRenderer::initialize(SDL_Window *window) {

  _window = window;

  glm::ivec2 size;
  SDL_GetWindowSize(window, &size.x, &size.y);
  SDL_Log("Window size: %d x %d", size.x, size.y);

  SDL_Log("MetalRenderer::initialize - SDL Version: %d.%d", SDL_MAJOR_VERSION,
          SDL_MINOR_VERSION);
  id<MTLDevice> device = MTLCreateSystemDefaultDevice();

  if (!device) {
    SDL_Log("Failed to create device, Metal not supported");
    return false;
  }

  _metal_view = SDL_Metal_CreateView(window);

  if (!_metal_view) {
    SDL_Log("Failed to create Metal view");
    return false;
  }

  void *raw_layer = SDL_Metal_GetLayer(_metal_view);
  if (!raw_layer) {
    SDL_Log("Failed to get Metal layer");
    SDL_Metal_DestroyView(_metal_view);
    return false;
  }

  // raw_layer is a pointer to a CAMetalLayer (unretained by SDL), keep a
  // retained reference
  CAMetalLayer *layer = (__bridge CAMetalLayer *)raw_layer;

  layer.device = device;
  layer.pixelFormat = MTLPixelFormatBGRA8Unorm;
  layer.framebufferOnly = YES;
  layer.drawableSize = CGSizeMake(size.x, size.y);

  _metal_layer = (__bridge_retained void *)layer;
  _device = (__bridge_retained void *)device;

  setup_default_shaders();

  id<MTLCommandQueue> commandQueue = [device newCommandQueue];
  if (!commandQueue) {
    SDL_Log("Failed to create command queue");

    destroy();

    return false;
  }

  _command_queue = (__bridge_retained void *)commandQueue;

  create_cube_mesh();

  SDL_Log("Metal Renderer initialized successfully.");

  return true;
}

void MetalRenderer::create_cube_mesh() {

  id<MTLDevice> device = (__bridge id<MTLDevice>)_device;

  // Triangle
  //   std::vector<Vertex> vertices = {
  //       {{0.0f, 0.5f, -3.0f}, {1, 0, 0}, {0.5f, 1.0f}},   // Top
  //       {{-0.5f, -0.5f, -3.0f}, {0, 1, 0}, {0.0f, 0.0f}}, // Left
  //       {{0.5f, -0.5f, -3.0f}, {0, 0, 1}, {1.0f, 0.0f}},  // Right
  //   };

  //   std::vector<uint16_t> indices = {0, 1, 2};

  std::vector<Vertex> vertices = {
      // Front face
      {{-0.5f, -0.5f, 0.5f}, {1, 0, 0}, {0, 0}},
      {{0.5f, -0.5f, 0.5f}, {0, 1, 0}, {1, 0}},
      {{0.5f, 0.5f, 0.5f}, {0, 0, 1}, {1, 1}},
      {{-0.5f, 0.5f, 0.5f}, {1, 1, 0}, {0, 1}},
      // Back face
      {{-0.5f, -0.5f, -0.5f}, {1, 0, 1}, {0, 0}},
      {{0.5f, -0.5f, -0.5f}, {0, 1, 1}, {1, 0}},
      {{0.5f, 0.5f, -0.5f}, {1, 1, 1}, {1, 1}},
      {{-0.5f, 0.5f, -0.5f}, {0, 0, 0}, {0, 1}},
  };

  std::vector<uint16_t> indices = {
      0, 1, 2, 2, 3, 0, // front
      1, 5, 6, 6, 2, 1, // right
      5, 4, 7, 7, 6, 5, // back
      4, 0, 3, 3, 7, 4, // left
      3, 2, 6, 6, 7, 3, // top
      4, 5, 1, 1, 0, 4  // bottom
  };

  _num_indices = static_cast<int>(indices.size());

  id<MTLBuffer> vbuf =
      [device newBufferWithBytes:vertices.data()
                          length:sizeof(Vertex) * vertices.size()
                         options:MTLResourceStorageModeShared];

  id<MTLBuffer> ibuf =
      [device newBufferWithBytes:indices.data()
                          length:sizeof(uint16_t) * indices.size()
                         options:MTLResourceStorageModeShared];

  _vertex_buffer = (__bridge_retained void *)vbuf;
  _index_buffer = (__bridge_retained void *)ibuf;

  SDL_Log("Mesh created with %d indices", _num_indices);
}

void MetalRenderer::setup_default_shaders() {
  NSError *error = nil;

  id<MTLDevice> device = (__bridge id<MTLDevice>)_device;
  if (!device) {
    SDL_Log("setup_default_shaders: device is null");
    return;
  }

  id<MTLLibrary> defaultLibrary = [device newDefaultLibrary];
  if (!defaultLibrary) {
    SDL_Log("Failed to find the default library.");
    return;
  }

  id<MTLFunction> vertexFunction =
      [defaultLibrary newFunctionWithName:@"vertex_main"];
  id<MTLFunction> fragmentFunction =
      [defaultLibrary newFunctionWithName:@"fragment_main"];

  if (!vertexFunction || !fragmentFunction) {
    SDL_Log("Failed to find the vertex or fragment function.");
    return;
  }

  MTLRenderPipelineDescriptor *pDesc =
      [[MTLRenderPipelineDescriptor alloc] init];
  pDesc.label = @"Default Pipeline";
  pDesc.vertexFunction = vertexFunction;
  pDesc.fragmentFunction = fragmentFunction;
  pDesc.colorAttachments[0].pixelFormat = MTLPixelFormatBGRA8Unorm;

  MTLVertexDescriptor *vertexDescriptor = [[MTLVertexDescriptor alloc] init];

  // Position attribute
  vertexDescriptor.attributes[0].format = MTLVertexFormatFloat3;
  vertexDescriptor.attributes[0].offset = 0;
  vertexDescriptor.attributes[0].bufferIndex = 0;

  // Color attribute
  vertexDescriptor.attributes[1].format = MTLVertexFormatFloat3;
  vertexDescriptor.attributes[1].offset = sizeof(float) * 3; // [x,y,z...r,g,b]
  vertexDescriptor.attributes[1].bufferIndex = 0;

  // Texcoord attribute
  vertexDescriptor.attributes[2].format = MTLVertexFormatFloat2;
  vertexDescriptor.attributes[2].offset =
      sizeof(float) * 6; // [x,y,z,r,g,b...u,v]
  vertexDescriptor.attributes[2].bufferIndex = 0;

  // Layout
  vertexDescriptor.layouts[0].stride = sizeof(float) * 8; // [x,y,z,r,g,b,u,v]
  vertexDescriptor.layouts[0].stepRate = 1;
  vertexDescriptor.layouts[0].stepFunction = MTLVertexStepFunctionPerVertex;

  pDesc.vertexDescriptor = vertexDescriptor;

  MTLDepthStencilDescriptor *depthStencilDesc =
      [[MTLDepthStencilDescriptor alloc] init];
  depthStencilDesc.depthCompareFunction = MTLCompareFunctionLess;
  depthStencilDesc.depthWriteEnabled = YES;

  id<MTLDepthStencilState> depthStencilState =
      [device newDepthStencilStateWithDescriptor:depthStencilDesc];

  id<MTLRenderPipelineState> pipelineState =
      [device newRenderPipelineStateWithDescriptor:pDesc error:&error];

  if (!pipelineState) {
    SDL_Log("Failed to create pipeline state: %s",
            error.localizedDescription.UTF8String);
    return;
  }

  _pipeline = (__bridge_retained void *)pipelineState;
}

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

  if (_metal_view) {
    SDL_Metal_DestroyView(_metal_view);
    _metal_view = nullptr;
  }
}

void MetalRenderer::clear(const glm::vec4 &color) {
  @autoreleasepool {
    id<CAMetalDrawable> drawable =
        [(__bridge CAMetalLayer *)_metal_layer nextDrawable];
    if (!drawable)
      return;

    id<MTLCommandQueue> queue = (__bridge id<MTLCommandQueue>)_command_queue;
    id<MTLCommandBuffer> cmd = [queue commandBuffer];

    MTLRenderPassDescriptor *pass =
        [MTLRenderPassDescriptor renderPassDescriptor];
    pass.colorAttachments[0].texture = drawable.texture;
    pass.colorAttachments[0].loadAction = MTLLoadActionClear;
    pass.colorAttachments[0].storeAction = MTLStoreActionStore;
    pass.colorAttachments[0].clearColor =
        MTLClearColorMake(color.r, color.g, color.b, color.a);

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

    const glm::mat4 model_matrix = glm::mat4(1.0f);

    Uniforms u;
    u.model = model_matrix;
    u.view = view;
    u.projection = projection;

    id<MTLDevice> device = (__bridge id<MTLDevice>)_device;
    id<MTLBuffer> uniformBuf =
        [device newBufferWithBytes:&u
                            length:sizeof(u)
                           options:MTLResourceStorageModeShared];
    [enc setVertexBuffer:uniformBuf offset:0 atIndex:1];

    [enc setVertexBuffer:(__bridge id<MTLBuffer>)_vertex_buffer
                  offset:0
                 atIndex:0];
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
    if (!_current_drawable || !_current_command_buffer)
      return;

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
