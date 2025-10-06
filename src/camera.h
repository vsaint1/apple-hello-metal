#pragma once

#include <glm/glm.hpp>
#include <glm/gtc/constants.hpp>
#include <glm/gtc/matrix_transform.hpp>

struct Camera {
  glm::vec3 position = {0.0f, 0.0f, 3.0f};
  float yaw = -glm::half_pi<float>();
  float pitch = 0.0f;
  float sensitivity = 0.002f;
  float speed = 10.0f;

  glm::vec3 front() const {
    glm::vec3 f;
    f.x = cos(pitch) * cos(yaw);
    f.y = sin(pitch);
    f.z = cos(pitch) * sin(yaw);
    return glm::normalize(f);
  }

  glm::vec3 right() const {
    return glm::normalize(glm::cross(front(), glm::vec3(0.0f, 1.0f, 0.0f)));
  }

  glm::mat4 get_view_matrix() const {
    return glm::lookAt(position, position + front(),
                       glm::vec3(0.0f, 1.0f, 0.0f));
  }

  glm::mat4 get_projection_matrix(float aspect_ratio) const {
    return glm::perspective(glm::radians(45.0f), aspect_ratio, 0.1f, 100.0f);
  }

  void handle_mouse(int xrel, int yrel) {
    yaw += xrel * sensitivity;
    pitch -= yrel * sensitivity;
    pitch = glm::clamp(pitch, -glm::half_pi<float>() + 0.01f,
                       glm::half_pi<float>() - 0.01f);
  }

  void move_forward(float delta) { position += front() * speed * delta; }
  void move_backward(float delta) { position -= front() * speed * delta; }
  void move_left(float delta) { position -= right() * speed * delta; }
  void move_right(float delta) { position += right() * speed * delta; }
};
