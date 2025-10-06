#import "mtl_renderer.h"


#import <Metal/Metal.h>
#import <QuartzCore/CAMetalLayer.h>



bool MetalRenderer::initialize(SDL_Window* window){

    _window = window;
    SDL_Log("MetalRenderer::initialize - SDL Version: %d.%d", SDL_MAJOR_VERSION, SDL_MINOR_VERSION);

    return true;
}


void MetalRenderer::destroy(){
    SDL_Log("MetalRenderer::destroy");
}


MetalRenderer::~MetalRenderer(){
    destroy();
}
