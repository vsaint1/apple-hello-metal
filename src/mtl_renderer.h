#pragma once
#include <SDL3/SDL.h>
#include <SDL3/SDL_metal.h>
#include <glm/glm.hpp>
#include <vector>

#include <glm/gtc/matrix_transform.hpp>
#include <glm/gtc/type_ptr.hpp>
#include <glm/matrix.hpp>

struct Vertex {
  glm::vec3 pos;
  glm::vec3 color;
  glm::vec2 uv;
};

struct Uniforms {
  glm::mat4 model;
  glm::mat4 view;
  glm::mat4 projection;
};

class MetalRenderer {
public:
  MetalRenderer() = default;
  ~MetalRenderer();

  bool initialize(SDL_Window *window);

  void clear(const glm::vec4 &color);

  void flush(const glm::mat4 &view, const glm::mat4 &projection);

  void present();

  void destroy();

protected:
  SDL_Window *_window = nullptr;

  void setup_default_shaders();

  void create_cube_mesh();

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
