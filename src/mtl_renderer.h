#pragma once
#include <SDL3/SDL.h>
#include <SDL3/SDL_metal.h>


class MetalRenderer {
public:
    MetalRenderer() = default;
    ~MetalRenderer();

    bool initialize(SDL_Window* window);

    void destroy();

protected:
    SDL_Window* _window = nullptr;

private:
    void* _device     = nullptr; // id<MTLDevice>
    void* _command_queue      = nullptr; // id<MTLCommandQueue>
    void* _pipeline    = nullptr; // id<MTLRenderPipelineState>
    void* _metal_layer = nullptr; // CAMetalLayer*
    void* _sampler     = nullptr;

    SDL_MetalView _metal_view = nullptr; // SDL_MetalView
};
