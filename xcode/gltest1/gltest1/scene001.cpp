#include "util.h"
#include <OpenGL/gl.h>
#include "glm/glm.hpp"
#include "glm/gtc/type_ptr.hpp"
#include "glm/gtx/normal.hpp"

const GLfloat EDGE = 50.0;
const GLfloat SQR3 = sqrt(3);
const GLfloat SQR6 = sqrt(6);

bool is_equal(GLfloat a[3], GLfloat b[3]) {
    for (int i = 0; i < 3; ++i) {
        if (abs(a[i] - b[i]) >= 10) {
            return false;
        }
    }
    return true;
}

bool is_equal(GLfloat vertices[4][3]) {
    for (int i = 0; i < 4; ++i) {
        for (int j = i + 1; j < 4; ++j) {
            if (!is_equal(vertices[i], vertices[j])) {
                return false;
            }
        }
    }
    return true;
}

void triangle(GLfloat vertices[3][3], GLfloat color[3], bool reverse = false ) {
    auto normal = glm::triangleNormal( glm::make_vec3(vertices[0]), glm::make_vec3(vertices[1]), glm::make_vec3(vertices[2]) );
    if( reverse ) normal = -normal;
    glNormal3fv( glm::value_ptr(normal) );
    glColor3fv(color);
    if( reverse ){
        for (int i = 2; i >= 0; --i) {
            glVertex3fv(vertices[i]);
        }
    }else{
        for (int i = 0; i < 3; ++i) {
            glVertex3fv(vertices[i]);
        }
    }
}

bool cmp(GLfloat v1[3], GLfloat v2[3]) {
    for (int i = 2; i >= 0; --i) {
        if (v1[i] != v2[i]) {
            return v1[i] < v2[i];
        }
    }
    return false;
}

void swap(GLfloat v1[3], GLfloat v2[3]) {
    for (int i = 0; i < 3; ++i) {
        GLfloat tmp = v1[i];
        v1[i] = v2[i];
        v2[i] = tmp;
    }
}

void sort(GLfloat vertices[4][3]) {
    for (int i = 0; i < 4; ++i) {
        for (int j = i + 1; j < 4; ++j) {
            if (!cmp(vertices[i], vertices[j])) {
                swap(vertices[i], vertices[j]);
            }
        }
    }
}

void tetra(GLfloat vertices[4][3], GLfloat colors[4][3]) {
    sort(vertices);
    for (int i = 0; i < 4; ++i) {
        GLfloat tri[3][3];
        for (int j = 0; j < 3; ++j) {
            for (int k = 0; k < 3; ++k) {
                tri[j][k] = vertices[(i+j)%4][k];
            }
        }
        triangle(tri, colors[i], i == 0 || i == 2 );
    }
}

void divide_triangle(GLfloat vertices[4][3], GLfloat colors[4][3]) {
    if (is_equal(vertices)) {
        tetra(vertices, colors);
    }
    else {
        for (int i = 0; i < 4; ++i) {
            GLfloat child[4][3];
            for (int j = 0; j < 4; ++j) {
                for (int k = 0; k < 3; ++k) {
                    child[j][k] = (vertices[i][k] + vertices[(i+j)%4][k]) / 2;
                }
            }
            divide_triangle(child, colors);
        }
    }
}

void display()
{
    // GLfloat vertices[4][3] = { {0.0, 0.0, 0.0}, {EDGE, 0.0, 0.0}, {EDGE/2, EDGE*SQR3/2, 0.0}, {EDGE/2, EDGE*SQR3/6, EDGE*SQR6/3} };
    GLfloat vertices[4][3] = { {0.0, 10.0, 0.0}, {0.0, -10.0, -10.0}, {10.0, -10.0, 10.0}, {-10.0, -10.0, 10.0} };
    GLfloat colors[4][3] = { {1.0, 1.0, 0.5}, {0.5, 1.0, 0.5}, {0.5, 0.8, 0.5}, {0.5, 0.5, 1.0} };
        
    //glUseProgram( Program::Get("simple.frag+simple.vert")->Handle() );
    glUseProgram( Program::Get("gouraud.vert+gouraud.frag")->Handle() );
    glBegin(GL_TRIANGLES);
    divide_triangle(vertices, colors);
    glEnd();
    
    Util::print(10,100, "hoge");
    
}

class Scene001 : public Scene {
public:
    static Scene* Create(){ return new Scene001(); }
    Scene001(){};
    void Display()
    {
        display();
    }
};

INITIALIZER()
{
    Scene::Register( "Scene001", Scene001::Create );
}
