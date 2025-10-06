#pragma once
#include "renderer.h"

class OpenglRenderer : public Renderer {
public:
    OpenglRenderer()           = default;
    ~OpenglRenderer() override = default;

    bool initialize(SDL_Window* window) override;

    void clear(const glm::vec4& color) override;

    void flush(const glm::mat4& view, const glm::mat4& projection) override;

    void present() override;

    void destroy() override;

protected:
    void setup_default_shaders() override;

    void create_cube_mesh() override;

private:
    GLuint _shader_program = 0;
    GLuint _vao            = 0;
    GLuint _vbo            = 0;
    GLuint _ebo            = 0;
    GLsizei _index_count   = 0;

    SDL_GLContext  _gl_context = nullptr;
};
