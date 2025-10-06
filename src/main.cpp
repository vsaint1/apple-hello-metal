#include "mtl_renderer.h"
#include <SDL3/SDL.h>
#include <SDL3/SDL_main.h>

int main(int argc, const char *argv[]) {

  int window_width = 1280;
  int window_height = 720;

  if (!SDL_Init(SDL_INIT_VIDEO)) {
    SDL_Log("Unable to initialize SDL: %s", SDL_GetError());
    return 1;
  }

  SDL_Window *window =
      SDL_CreateWindow("Metal Renderer", window_width, window_height,
                       SDL_WINDOW_RESIZABLE | SDL_WINDOW_METAL);

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

  glm::mat4 view_matrix = glm::mat4(1.0f);
  view_matrix = glm::translate(view_matrix, glm::vec3(0.0f, 0.0f, -10.0f));

  const glm::mat4 projection_matrix = glm::perspective(
      glm::radians(45.0f), (float)window_width / (float)window_height, 0.1f,
      100.0f);

  SDL_Event event;
  while (is_running) {
    while (SDL_PollEvent(&event)) {
      if (event.type == SDL_EVENT_QUIT) {
        is_running = false;
      }

      if (event.type == SDL_EVENT_WINDOW_RESIZED) {
        window_width = event.window.data1;
        window_height = event.window.data2;
      }
    }

    const bool *state = SDL_GetKeyboardState(NULL);

    if (state[SDL_SCANCODE_W]) {
      view_matrix = glm::translate(view_matrix, glm::vec3(0.0f, 0.0f, 0.1f));
    }

    if (state[SDL_SCANCODE_S]) {
      view_matrix = glm::translate(view_matrix, glm::vec3(0.0f, 0.0f, -0.1f));
    }

    if (state[SDL_SCANCODE_A]) {
      view_matrix = glm::translate(view_matrix, glm::vec3(0.1f, 0.0f, 0.0f));
    }

    if (state[SDL_SCANCODE_D]) {
      view_matrix = glm::translate(view_matrix, glm::vec3(-0.1f, 0.0f, 0.0f));
    }

    renderer->clear(glm::vec4(0.2f, 0.4f, 0.8f, 1.0f));
    renderer->flush(view_matrix, projection_matrix);
    renderer->present();

    SDL_Delay(16); // ~60 fps
  }

  delete renderer;

  SDL_Quit();

  return 0;
}
