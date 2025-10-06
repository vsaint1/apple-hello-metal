#pragma once
#include "renderer.h"

class MetalRenderer : public Renderer {
public:
  MetalRenderer() = default;
  ~MetalRenderer();

  bool initialize(SDL_Window *window) override;

  void clear(const glm::vec4 &color) override;

  void flush(const glm::mat4 &view, const glm::mat4 &projection) override;

  void present() override;

  void destroy() override;

protected:
  SDL_Window *_window = nullptr;

  void setup_default_shaders() override;

  void create_cube_mesh() override;

private:
  void *_device = nullptr;        // id<MTLDevice>
  void *_command_queue = nullptr; // id<MTLCommandQueue>
  void *_pipeline = nullptr;      // id<MTLRenderPipelineState>
  void *_metal_layer = nullptr;   // CAMetalLayer*
  void *_sampler = nullptr;

  void *_depth_stencil_state = nullptr; // id<MTLDepthStencilState>
  void *_depth_texture = nullptr;       // id<MTLTexture>

  // VERTEX DATA
  void *_vertex_buffer = nullptr; // id<MTLBuffer>
  void *_index_buffer = nullptr;  // id<MTLBuffer>
  int _num_indices = 0;

  void *_current_drawable = nullptr;       // id<CAMetalDrawable>
  void *_current_command_buffer = nullptr; // id<MTLCommandBuffer>
  void *_current_pass = nullptr;

  SDL_MetalView _metal_view = nullptr; // SDL_MetalView
};
