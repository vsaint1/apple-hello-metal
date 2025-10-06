#version 330

in vec3 COLOR;

void main() {
    gl_FragColor = vec4(COLOR, 1.0);
}