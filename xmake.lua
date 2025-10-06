set_project("hello_metal")
set_languages("cxx17")

add_rules("mode.debug", "mode.release")

add_rules("plugin.compile_commands.autoupdate", {outputdir = ".vscode"})
add_rules("mode.debug", "mode.release")

add_requires("libsdl3 3.2.22", {configs = {shared = true}})

target("hello_metal")
    add_rules("xcode.application")
    add_files("src/main.cpp","src/*.mm", "src/**.storyboard", "src/*.xcassets")
    add_files("src/Info.plist")

    if is_plat("macosx") then
        add_frameworks("Metal", "MetalKit", "Cocoa", "QuartzCore", "Foundation", "AppKit")
    end

    add_packages("libsdl3")

