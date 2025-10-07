#version 330

in vec3 COLOR;
in vec2 UV;

out vec4 FRAG_COLOR;


void main() {
    FRAG_COLOR = vec4(COLOR, 1.0);
}