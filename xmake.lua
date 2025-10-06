set_project("hello_metal")
set_languages("cxx17")  -- add objc++ here

add_rules("mode.debug", "mode.release")

add_rules("plugin.compile_commands.autoupdate", {outputdir = ".vscode"})
add_rules("mode.debug", "mode.release")

add_requires("libsdl3 3.2.22", {configs = {shared = true}})
add_requires("glm 1.0.1", {configs = {shared = false}})

target("hello_metal")
    add_rules("xcode.application")
    add_includedirs("src",{public = true})
    add_files("src/main.cpp","src/*.mm","res/shaders/metal/**.metal")

    add_frameworks("MetalKit")
    add_mflags("-fmodules")

    if is_plat("macosx") then
        add_frameworks("Metal", "Cocoa", "QuartzCore", "Foundation", "AppKit")
        add_files("templates/macos//**.storyboard", "templates/macos//*.xcassets","templates/macos/Info.plist")
        add_ldflags("-fobjc-arc")
    end

    add_packages("libsdl3","glm")


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

    after_load(function(target)
        for _, pkg in ipairs(target:pkgs() or {}) do
            local incdirs = pkg:get("includedirs") or {}
            for _, d in ipairs(incdirs) do
                target:add("xcode.public_headers", d)
            end
        end
    end)
