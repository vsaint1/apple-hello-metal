#pragma once
#include "glm/fwd.hpp"
#include <SDL3/SDL.h>
#include <SDL3/SDL_metal.h>
#include <glm//glm.hpp>


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

    bool initialize(SDL_Window* window);

    void clear(const glm::vec4& color);

    void flush(const glm::mat4& view, const glm::mat4& projection);

    void present();

    void destroy();

protected:
    SDL_Window* _window = nullptr;

    void setup_default_shaders();

private:
    void* _device     = nullptr; // id<MTLDevice>
    void* _command_queue      = nullptr; // id<MTLCommandQueue>
    void* _pipeline    = nullptr; // id<MTLRenderPipelineState>
    void* _metal_layer = nullptr; // CAMetalLayer*
    void* _sampler     = nullptr;

    SDL_MetalView _metal_view = nullptr; // SDL_MetalView
};
