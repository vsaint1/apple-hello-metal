#pragma once
#include  "core.h"


inline std::string load_assets_file(const char* filepath) {
    std::string code;
    SDL_IOStream* file = SDL_IOFromFile(filepath, "rb");

    if (file) {
        Sint64 size = SDL_GetIOSize(file);
        code.resize(size);
        SDL_ReadIO(file, code.data(), size);
        SDL_CloseIO(file);
    } else {
        SDL_Log("Failed to load shader file %s: %s", filepath, SDL_GetError());
    }
    
    return code;

}