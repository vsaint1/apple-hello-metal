#version 330

layout(location = 0) in vec3 a_pos;
layout(location = 1) in vec3 a_color;
layout(location = 2) in vec2 a_tex_coord;

struct Uniforms {
    mat4 model;
    mat4 view;
    mat4 projection;
};

uniform Uniforms u;

out vec2 UV;
out vec3 COLOR;

void main(){

    vec4 pos = vec4(a_pos,1.0);

    gl_Position = u.projection * u.view * u.model * pos;
    UV = a_tex_coord;
    COLOR = a_color;

}