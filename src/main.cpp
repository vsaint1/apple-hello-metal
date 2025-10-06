#include "mtl_renderer.h"
#include <SDL3/SDL.h>
#include <SDL3/SDL_main.h>

int main(int argc, const char *argv[]) {

  if (!SDL_Init(SDL_INIT_VIDEO)) {
    SDL_Log("Unable to initialize SDL: %s", SDL_GetError());
    return 1;
  }

  SDL_Window *window = SDL_CreateWindow(
      "Metal Renderer", 1280, 720, SDL_WINDOW_RESIZABLE | SDL_WINDOW_METAL);

  if (!window) {
    SDL_Log("Failed to create MTL window %s", SDL_GetError());
    SDL_Quit();
    return -1;
  }

  MetalRenderer *renderer = new MetalRenderer();

  if (!renderer->initialize(window)) {

    SDL_Log("Failed to initialize Metal Renderer.");
    delete renderer;
    SDL_DestroyWindow(window);
    SDL_Quit();
    return -1;
  }

  bool is_running = true;

  SDL_Event event;
  while (is_running) {
    while (SDL_PollEvent(&event)) {
      if (event.type == SDL_EVENT_QUIT) {
        is_running = false;
      }
    }

    renderer->clear(glm::vec4(0.2f, 0.4f, 0.8f, 1.0f));

    renderer->present();

  }

  delete renderer;

  SDL_Quit();

  return 0;
}
