#import "mtl_renderer.h"


#import <Metal/Metal.h>
#import <QuartzCore/CAMetalLayer.h>


//void* _device     = nullptr; // id<MTLDevice>
//  void* _command_queue      = nullptr; // id<MTLCommandQueue>
//  void* _pipeline    = nullptr; // id<MTLRenderPipelineState>
//  void* _metal_layer = nullptr; // CAMetalLayer*
//  void* _sampler     = nullptr;
//
//  SDL_MetalView _metal_view = nullptr; // SDL_MetalView


bool MetalRenderer::initialize(SDL_Window* window){



    _window = window;
    SDL_Log("MetalRenderer::initialize - SDL Version: %d.%d", SDL_MAJOR_VERSION, SDL_MINOR_VERSION);
    id<MTLDevice> device = MTLCreateSystemDefaultDevice();




    if(!device){
        SDL_Log("Failed to create device, Metal not supported");
        return false;
    }

    SDL_Log("Device created");
    _device = (__bridge void*)device;

    return true;
}


void MetalRenderer::destroy(){
    SDL_Log("MetalRenderer::destroy");

    if(_device){
        id<MTLDevice> dev = (__bridge id<MTLDevice>)_device;
        (void)dev;
        _device = nullptr;
    }
}


MetalRenderer::~MetalRenderer(){
    destroy();
}
