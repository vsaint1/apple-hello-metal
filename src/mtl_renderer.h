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
};
