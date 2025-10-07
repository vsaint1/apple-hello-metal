#include "core.h"
#include <SDL3/SDL_main.h>


int main(int argc, const char* argv[]) {
    int window_width  = 1280;
    int window_height = 720;

    if (!SDL_Init(SDL_INIT_VIDEO | SDL_INIT_EVENTS)) {
        SDL_Log("Unable to initialize SDL: %s", SDL_GetError());
        return 1;
    }

    Uint64 window_flags = SDL_WINDOW_RESIZABLE;

#if defined(__APPLE__)
    window_flags |= SDL_WINDOW_METAL;
#else
    window_flags |= SDL_WINDOW_OPENGL;
#endif

    const char* platform = SDL_GetPlatform();
    std::string title    = std::string("OpenGL/Metal Renderer Interface").append(" - ").append(platform);

    SDL_Window* window = SDL_CreateWindow(title.c_str(), window_width, window_height, window_flags);

    if (!window) {
        SDL_Log("Failed to create window %s", SDL_GetError());
        SDL_Quit();
        return -1;
    }

    Renderer* renderer = new OpenglRenderer();

    if (!renderer->initialize(window)) {
        SDL_Log("Failed to initialize Renderer.");
        delete renderer;
        SDL_DestroyWindow(window);
        SDL_Quit();
        return -1;
    }

    Camera camera;

    bool is_running = true;

    glm::mat4 projection_matrix = camera.get_projection_matrix((float) window_width / (float) window_height);

    SDL_Event event;
    while (is_running) {
        while (SDL_PollEvent(&event)) {
            if (event.type == SDL_EVENT_QUIT) {
                is_running = false;
            }

            if (event.type == SDL_EVENT_WINDOW_RESIZED) {
                window_width      = event.window.data1;
                window_height     = event.window.data2;
                projection_matrix = glm::perspective(glm::radians(45.0f), (float) window_width / (float) window_height, 0.1f, 100.0f);
            }

            if (event.type == SDL_EVENT_MOUSE_MOTION) {
                camera.handle_mouse(event.motion.xrel, event.motion.yrel);
            }
        }
        const bool* state = SDL_GetKeyboardState(NULL);

        float dt = 0.016f; // create a proper delta time calculation
        if (state[SDL_SCANCODE_W]) {
            camera.move_forward(dt);
        }
        if (state[SDL_SCANCODE_S]) {
            camera.move_backward(dt);
        }
        if (state[SDL_SCANCODE_A]) {
            camera.move_left(dt);
        }
        if (state[SDL_SCANCODE_D]) {
            camera.move_right(dt);
        }

        renderer->clear(glm::vec4(0.2f, 0.4f, 0.8f, 1.0f));
        renderer->flush(camera.get_view_matrix(), projection_matrix);
        renderer->present();

        // SDL_Delay(16); // ~60 FPS
    }

    delete renderer;
    SDL_DestroyWindow(window);
    SDL_Quit();
    return 0;
}
