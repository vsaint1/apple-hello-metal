#pragma once
#include <SDL3/SDL.h>
#include <SDL3/SDL_metal.h>
#include <SDL3/SDL_opengl.h>

#include <vector>

#include <glm/glm.hpp>
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

class Renderer {
public:
    Renderer()          = default;
    virtual ~Renderer() = default;

    virtual bool initialize(SDL_Window* window) = 0;

    virtual void clear(const glm::vec4& color) = 0;

    virtual void flush(const glm::mat4& view, const glm::mat4& projection) = 0;

    virtual void present() = 0;

    virtual void destroy() = 0;

protected:
    SDL_Window* _window = nullptr;

    virtual void setup_default_shaders() = 0;

    virtual void create_cube_mesh() = 0;
};
