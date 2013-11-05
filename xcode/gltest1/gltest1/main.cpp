//
//  main.cpp
//  Three-Dimentional Gasket
//
//  Created by Liang Sun on 1/6/13.
//  Copyright (c) 2013 Liang Sun. All rights reserved.
//

#include <iostream>
#include <stdlib.h>
#include <math.h>
#include <GLUT/glut.h>
#include "trackball.h"
#include "util.h"

static Scene *_scene;

static void _init() {
    glEnable(GL_DEPTH_TEST);
    glEnable(GL_CULL_FACE);
    glClearColor(0.5,0.5,0.5,1);
    glColor3f(1,1,1);
    _scene->Init();
    CHECK();
}

static void idle(void)
{
    /* 画面の描き替え */
    glutPostRedisplay();
}

static void mouse(int button, int state, int x, int y)
{
    switch (button) {
        case GLUT_LEFT_BUTTON:
            switch (state) {
                case GLUT_DOWN:
                    /* トラックボール開始 */
                    trackballStart(x, y);
                    glutIdleFunc(idle);
                    break;
                case GLUT_UP:
                    /* トラックボール停止 */
                    trackballStop(x, y);
                    glutIdleFunc(0);
                    break;
                default:
                    break;
            }
            break;
        default:
            break;
    }
}

static void motion(int x, int y)
{
    /* トラックボール移動 */
    trackballMotion(x, y);
}

static void _display();

static void keyboard(unsigned char key, int x, int y)
{
    switch (key) {
        case 'q':
        case 'Q':
        case '\033':
            /* ESC か q か Q をタイプしたら終了 */
            exit(0);
        case 'r':
        case 'R':
            Program::ClearAll();
            Shader::ClearAll();
            _display();
            break;
        default:
            break;
    }
}

static void resize(int w, int h)
{
    trackballRegion(w, h);
    glViewport(0, 0, w, h);
}

static void _display()
{
    // 透視変換を設定
    glMatrixMode(GL_PROJECTION);
    glLoadIdentity();
    float view_x, view_y;
    if( glutGet(GLUT_WINDOW_WIDTH) > glutGet(GLUT_WINDOW_HEIGHT) ){
        view_x = 1.0;
        view_y = 1.0 * glutGet( GLUT_WINDOW_HEIGHT) / glutGet( GLUT_WINDOW_WIDTH );
    }else{
        view_x = 1.0 * glutGet( GLUT_WINDOW_WIDTH) / glutGet( GLUT_WINDOW_HEIGHT );
        view_y = 1.0;
    }
    view_x *= 10;
    view_y *= 10;
    glFrustum(-view_x,view_x, -view_y,view_y, 40, 100000);
    gluLookAt(0, 0, 100, 0, 0, 0, 0, 1.0, 0);
    
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    
    // モデル変換を設定
    glMatrixMode(GL_MODELVIEW);
    glLoadIdentity();

    glLightfv(GL_LIGHT0, GL_AMBIENT, glm::value_ptr(glm::vec4(0.3)));
    glLightfv(GL_LIGHT0, GL_POSITION, glm::value_ptr(glm::vec4(0,1,1,0)));
    glLightfv(GL_LIGHT0, GL_DIFFUSE, glm::value_ptr(glm::vec4(1)));
    glLightfv(GL_LIGHT0, GL_SPECULAR, glm::value_ptr(glm::vec4(8)));
    
    _scene->BeforeDisplay();
    
    /* トラックボール処理による回転 */
    glMultMatrixd(trackballRotation());
    
    _scene->Display();
    CHECK();
    
    glutSwapBuffers();

}

int main(int argc, char** argv)
{
    Initializer::Run();
    
    glutInit(&argc, argv);
    
    glutInitDisplayMode(GLUT_RGBA | GLUT_DOUBLE | GLUT_DEPTH);
    
    glutInitWindowSize(512, 512);
    glutInitWindowPosition(0, 0);
    glutCreateWindow("GLUT Program");
  
    if(argc > 1){
        _scene = Scene::CreateByName(argv[1]);
    }else{
        _scene = Scene::CreateByName("Scene008");
    }
    _scene->SetParam("model", "miku.pmd");
    
    glutReshapeFunc(resize);
    glutMouseFunc(mouse);
    glutMotionFunc(motion);
    glutDisplayFunc(_display);
    glutKeyboardFunc(keyboard);
    
    _init();
    glutMainLoop();
    return 0;
}