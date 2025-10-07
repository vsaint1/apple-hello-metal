#pragma once

#include "camera.h"
#if defined(__APPLE__)
    #include "mtl_renderer.h"
#endif

// NOTE: for example, if device doesnt support metal, we can fallback to opengl
#include "ogl_renderer.h"

#include "renderer.h"
#include <string>

#include <filesystem>

#if __APPLE__
const std::filesystem::path BASE_PATH = SDL_GetBasePath();
#define ASSETS_PATH (BASE_PATH / "res/").string()
#else
const std::filesystem::path BASE_PATH = SDL_GetBasePath();
#define ASSETS_PATH std::string("res/shaders/opengl/")
#endif
