#include "ogl_renderer.h"

#include "core.h"
#include "utils.h"
#include <cstdlib>
#include <ctime>

GLuint compile_shader(const char* source, GLenum type) {
    GLuint shader = glCreateShader(type);
    glShaderSource(shader, 1, &source, nullptr);
    glCompileShader(shader);

    GLint success;
    glGetShaderiv(shader, GL_COMPILE_STATUS, &success);
    if (!success) {
        char info_log[512];
        glGetShaderInfoLog(shader, 512, nullptr, info_log);
        SDL_Log("ERROR::SHADER::COMPILATION_FAILED: %s", info_log);
        glDeleteShader(shader);
        return 0;
    }


    return shader;
}

void GLAPIENTRY ogl_validation_layer(GLenum source, GLenum type, GLuint id, GLenum severity, GLsizei length, const GLchar* message,
                                     const void* userParam) {
    if (severity == GL_DEBUG_SEVERITY_NOTIFICATION) {
        return;
    }

    SDL_Log("ValidationLayer Type: 0x%x, Severity: 0x%x, ID: %u, Message: %s", type, severity, id, message);
}


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


    SDL_GL_SetSwapInterval(0);


    SDL_Log("Opengl Version %d.%d", major, minor);
    SDL_Log("Vendor: %s", glGetString(GL_VENDOR));
    SDL_Log("Renderer: %s", glGetString(GL_RENDERER));

    glm::ivec2 window_size;
    SDL_GetWindowSize(_window, &window_size.x, &window_size.y);


    GLint num_extensions = 0;
    std::vector<std::string> extensions;
    glGetIntegerv(GL_NUM_EXTENSIONS, &num_extensions);
    extensions.reserve(num_extensions);

    bool khr_debug_found = false;

    for (GLuint i = 0; i < num_extensions; i++) {
        const char* ext = reinterpret_cast<const char*>(glGetStringi(GL_EXTENSIONS, i));

        if (SDL_strcasecmp(ext, "GL_KHR_debug") == 0) {
            SDL_Log("KHR_debug extension supported, enabling validation layers");
            glEnable(GL_DEBUG_OUTPUT);
            glEnable(GL_DEBUG_OUTPUT_SYNCHRONOUS);
            glDebugMessageCallback(ogl_validation_layer, nullptr);
            khr_debug_found = true;
            break;
        }
    }

    if (!khr_debug_found) {
        SDL_LogWarn(SDL_LOG_CATEGORY_APPLICATION, "KHR_debug extensions not supported, validation layers disabled");
    }


    glEnable(GL_DEPTH_TEST);
    glViewport(0, 0, window_size.x, window_size.y);

    setup_default_shaders();

    create_cube_mesh();

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

    glBindVertexArray(_vao);
    glUseProgram(_default_shader_program);

    constexpr glm::mat4 model = glm::mat4(1.0f); // identity matrix

    Uniforms uniforms;
    uniforms.model      = model;
    uniforms.view       = view;
    uniforms.projection = projection;

    // NOTE: we could also pass the whole struct at once if we had std140 layout in the shader
    glUniformMatrix4fv(_uniforms.model_loc, 1, GL_FALSE, glm::value_ptr(uniforms.model));
    glUniformMatrix4fv(_uniforms.view_loc, 1, GL_FALSE, glm::value_ptr(uniforms.view));
    glUniformMatrix4fv(_uniforms.projection_loc, 1, GL_FALSE, glm::value_ptr(uniforms.projection));
    glDrawElements(GL_TRIANGLES, _index_count, GL_UNSIGNED_SHORT, 0);
}

void OpenglRenderer::present() {

    SDL_GL_SwapWindow(_window);
}

void OpenglRenderer::destroy() {
    if (_gl_context) {
        SDL_GL_DestroyContext(_gl_context);
        _gl_context = nullptr;
    }

    if (_default_shader_program) {
        glDeleteProgram(_default_shader_program);

        _default_shader_program = 0;
    }

    if (_vao) {
        glDeleteVertexArrays(1, &_vao);
        _vao = 0;
    }

    if (_ebo) {
        glDeleteBuffers(1, &_ebo);
        _ebo = 0;
    }

    if (_vbo) {
        glDeleteBuffers(1, &_vbo);
        _vbo = 0;
    }
}


void OpenglRenderer::setup_default_shaders() {

    const std::string vertex_shader_source = load_assets_file((ASSETS_PATH + "default.vert").c_str());

    const std::string fragment_shader_source = load_assets_file((ASSETS_PATH + "default.frag").c_str());

    GLuint vertex_shader   = compile_shader(vertex_shader_source.c_str(), GL_VERTEX_SHADER);
    GLuint fragment_shader = compile_shader(fragment_shader_source.c_str(), GL_FRAGMENT_SHADER);

    if (!vertex_shader || !fragment_shader) {
        SDL_Log("Failed to compile default shaders");
        return;
    }

    _default_shader_program = glCreateProgram();

    glAttachShader(_default_shader_program, vertex_shader);
    glAttachShader(_default_shader_program, fragment_shader);
    glLinkProgram(_default_shader_program);


    GLint success;
    glGetProgramiv(_default_shader_program, GL_LINK_STATUS, &success);
    if (!success) {
        char info_log[512];
        glGetProgramInfoLog(_default_shader_program, 512, nullptr, info_log);
        SDL_Log("ERROR::SHADER::PROGRAM::LINKING_FAILED: %s", info_log);
        glDeleteProgram(_default_shader_program);
        _default_shader_program = 0;
    }


    glUseProgram(_default_shader_program);

    _uniforms.model_loc      = glGetUniformLocation(_default_shader_program, "u.model");
    _uniforms.view_loc       = glGetUniformLocation(_default_shader_program, "u.view");
    _uniforms.projection_loc = glGetUniformLocation(_default_shader_program, "u.projection");

    if (_uniforms.model_loc == -1 || _uniforms.view_loc == -1 || _uniforms.projection_loc == -1) {
        SDL_LogWarn(SDL_LOG_CATEGORY_APPLICATION, "Model %d, View %d or Projection %d uniform not found in shader", _uniforms.model_loc,
                    _uniforms.view_loc, _uniforms.projection_loc);
    }

    if (!_default_shader_program) {
        SDL_Log("Failed to create default shader program");
        exit(-1);
        return;
    }

    glDeleteShader(vertex_shader);
    glDeleteShader(fragment_shader);

    SDL_Log("Default shaders compiled and linked successfully.");
}

// same code as in mtl_renderer.cpp
void OpenglRenderer::create_cube_mesh() {

    std::srand((unsigned int) time(nullptr));

    //    constexpr int count = 100'000'00;
   constexpr int count = 10000;

    std::vector<Vertex> vertices;
    std::vector<uint16_t> indices;

    // gpt chad
    auto push_cube = [&](glm::vec3 pos, glm::vec3 color) {
        glm::vec3 offsets[8] = {{-0.5f, -0.5f, 0.5f},  {0.5f, -0.5f, 0.5f},  {0.5f, 0.5f, 0.5f},  {-0.5f, 0.5f, 0.5f},
                                {-0.5f, -0.5f, -0.5f}, {0.5f, -0.5f, -0.5f}, {0.5f, 0.5f, -0.5f}, {-0.5f, 0.5f, -0.5f}};

        glm::vec2 uv[4] = {{0, 0}, {1, 0}, {1, 1}, {0, 1}};

        uint16_t base = static_cast<uint16_t>(vertices.size());

        for (int i = 0; i < 8; i++) {
            vertices.push_back({pos + offsets[i], color, uv[i % 4]});
        }

        uint16_t cubeIdx[36] = {0, 1, 2, 2, 3, 0, 1, 5, 6, 6, 2, 1, 5, 4, 7, 7, 6, 5, 4, 0, 3, 3, 7, 4, 3, 2, 6, 6, 7, 3, 4, 5, 1, 1, 0, 4};

        for (int i = 0; i < 36; i++) {
            indices.push_back(base + cubeIdx[i]);
        }
    };

    for (int i = 0; i < count; i++) {
        glm::vec3 pos   = {((float) rand() / RAND_MAX) * 50.0f - 25.0f, ((float) rand() / RAND_MAX) * 50.0f - 25.0f,
                           ((float) rand() / RAND_MAX) * -50.0f};
        glm::vec3 color = {(float) rand() / RAND_MAX, (float) rand() / RAND_MAX, (float) rand() / RAND_MAX};
        push_cube(pos, color);
    }

    _index_count = static_cast<GLsizei>(indices.size());

    glGenVertexArrays(1, &_vao);
    glGenBuffers(1, &_vbo);
    glGenBuffers(1, &_ebo);

    glBindVertexArray(_vao);
    glBindBuffer(GL_ARRAY_BUFFER, _vbo);
    glBufferData(GL_ARRAY_BUFFER, vertices.size() * sizeof(Vertex), vertices.data(), GL_STATIC_DRAW);

    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, _ebo);
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, indices.size() * sizeof(uint16_t), indices.data(), GL_STATIC_DRAW);


    glBindVertexArray(_vao);
    glEnableVertexAttribArray(0);
    glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, sizeof(Vertex), (void*) offsetof(Vertex, pos));


    glEnableVertexAttribArray(1);
    glVertexAttribPointer(1, 3, GL_FLOAT, GL_FALSE, sizeof(Vertex), (void*) offsetof(Vertex, color));

    glEnableVertexAttribArray(2);
    glVertexAttribPointer(2, 2, GL_FLOAT, GL_FALSE, sizeof(Vertex), (void*) offsetof(Vertex, uv));

    glBindVertexArray(0);

    SDL_Log("Created cube mesh with %zu vertices and %zu indices", vertices.size(), indices.size());
}
