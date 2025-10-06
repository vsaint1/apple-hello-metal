#pragma once

#include "camera.h"
#if defined(__APPLE__)
    #include "mtl_renderer.h"
#endif

// NOTE: for example, if device doesnt support metal, we can fallback to opengl
#include "ogl_renderer.h"

#include "renderer.h"
#include <string>