set_project("vri_renderer")
set_description("A cross platform renderer interface using OpenGL and Metal (example)")
set_languages("cxx17")

add_rules("mode.debug", "mode.release")

add_rules("plugin.compile_commands.autoupdate", {outputdir = ".vscode"})
add_rules("mode.debug", "mode.release")

add_requires("libsdl3 3.2.22", {configs = {shared = true}})
add_requires("glm 1.0.1", {configs = {shared = false}})
add_requires("glad v0.1.36",{configs = {shared = false}})

target("vri_renderer")
    add_includedirs("src",{public = true})
    add_files("src/main.cpp","src/*.cpp")

    add_defines("SDL_MAIN_HANDLED")

    if is_plat("windows") then 
        set_kind("binary")
    end 

    if is_plat("macosx") or is_plat("iphoneos") then
        add_files("src/*.mm","res/shaders/metal/**.metal")
        add_ldflags("-fobjc-arc")
        add_frameworks("MetalKit")
        add_mflags("-fmodules")

    end

    if is_plat("macosx") then
        add_frameworks("Metal", "Cocoa", "QuartzCore", "Foundation", "AppKit")
        add_files("templates/macos/*.storyboard", "templates/macos/*.xcassets","templates/macos/Info.plist")
    end

    add_packages("libsdl3","glm","glad")


    on_load(function (target)
        for _, pkg in pairs(target:pkgs() or {}) do
            local name = pkg:name()
            local installdir = pkg:installdir() or ""
            if installdir ~= "" then
                print("Adding rpathdir: ", path.join(installdir, "lib"))
                target:add("rpathdirs", path.join(installdir, "lib"))
            else
                print("No installdir for package: ", name)
            end
        end
    end)