#include "ogl_renderer.h"

bool OpenglRenderer::initialize(SDL_Window* window) {

    _window = window;

    SDL_GL_SetAttribute(SDL_GL_CONTEXT_MAJOR_VERSION, 3);
    SDL_GL_SetAttribute(SDL_GL_CONTEXT_MINOR_VERSION, 3);
    SDL_GL_SetAttribute(SDL_GL_CONTEXT_PROFILE_MASK, SDL_GL_CONTEXT_PROFILE_COMPATIBILITY);

    SDL_GL_SetAttribute(SDL_GL_DOUBLEBUFFER, 1);
    SDL_GL_SetAttribute(SDL_GL_DEPTH_SIZE, 24);

    _gl_context = SDL_GL_CreateContext(_window);

    if (!_gl_context) {
        SDL_Log("Failed to create OpenGL context: %s", SDL_GetError());
        return false;
    }

    int major, minor;
    SDL_GL_GetAttribute(SDL_GL_CONTEXT_MAJOR_VERSION, &major);
    SDL_GL_GetAttribute(SDL_GL_CONTEXT_MINOR_VERSION, &minor);

    if (!gladLoadGLLoader((GLADloadproc) SDL_GL_GetProcAddress)) {
        SDL_Log("Failed to initialize GLAD");
        return false;
    }

    SDL_Log("Opengl Version %d.%d", major, minor);
    SDL_Log("Vendor: %s", glGetString(GL_VENDOR));
    SDL_Log("Renderer: %s", glGetString(GL_RENDERER));

    glm::ivec2 window_size;
    SDL_GetWindowSize(_window, &window_size.x, &window_size.y);
    
    glEnable(GL_DEPTH_TEST);
    glViewport(0, 0, window_size.x, window_size.y);

    return true;
}

OpenglRenderer::~OpenglRenderer() {
    destroy();
}

void OpenglRenderer::clear(const glm::vec4& color) {
    glClearColor(color.r, color.g, color.b, color.a);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
}

void OpenglRenderer::flush(const glm::mat4& view, const glm::mat4& projection) {
}

void OpenglRenderer::present() {

    SDL_GL_SwapWindow(_window);
}

void OpenglRenderer::destroy() {
    if (_gl_context) {
        SDL_GL_DestroyContext(_gl_context);
        _gl_context = nullptr;
    }
}


void OpenglRenderer::setup_default_shaders() {
}

void OpenglRenderer::create_cube_mesh() {
}
