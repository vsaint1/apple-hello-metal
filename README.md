# Opengl/Metal Renderer [![C++ 20](https://img.shields.io/badge/C%2B%2B-20-blue.svg)](https://isocpp.org/std/the-standard) ![License](https://img.shields.io/github/license/vsaint1/ember_engine.svg)


An `SDL3` example with basic rendering capabilities using `Metal` on `macOS` and `iOS` and `OpenGL` on `Other Platforms`.

## Features
- Written in `C++` and `Objective-C`
- Basic rendering capabilities using `Metal`
- Basic rendering capabilities using `OpenGL`

## Resources

[Metal by Example](https://metalbyexample.com/) - A great resource to learn `Metal`

[Metal Tutorial](https://metaltutorial.com/) - Another great resource to learn `Metal`

[OpenGL Tutorial](https://learnopengl.com/) - A great resource to learn `OpenGL`

[OGLdev](https://www.youtube.com/@OGLDEV) - A YouTube channel with great `OpenGL` tutorials

## Quick Start

1. Clone the repository:
   ```bash
   git clone
   cd DIR
   xmake build
    ```

2. Generate the `xcode` project:

   2.1 For `Debug` or `Release` build on `macOS`:
   ```bash
   xmake f -p macosx -m debug
   xmake project -k xcode

   open hello_metal.xcodeproj
   ```

   2.2 For `Debug` or `Release` build on `iOS`:
   ```bash
   xmake f -p iphoneos -m debug
   xmake project -k xcode
   open hello_metal.xcodeproj
   ```

3. Build and running on `WebGL`:

> Note: You need to have `emscripten` installed and configured. Follow the instructions [here](https://emscripten.org/docs/getting_started/downloads.html).

   ```bash
   xmake f -p wasm -m debug
   xmake build

   python -m http.server -b localhost 8080
   ```
