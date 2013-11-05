#include "util.h"
#include <OpenGL/gl.h>
#include "glm/glm.hpp"
#include "glm/gtc/type_ptr.hpp"
#include "glm/gtx/normal.hpp"
#include "glm/gtx/string_cast.hpp"
#include "glm/gtx/transform.hpp"
#include <iostream>

using namespace glm;

static const int SHADOW_MAP_SIZE = 1024;

class Scene007 : public Scene {
public:
    static Scene* Create(){ return new Scene007(); }
    
    Model *mModel;
    Framebuffer *mFramebuffer;
    
    void Init()
    {
        mModel = Model::Get("miku.pmd");
        mFramebuffer = new Framebuffer(SHADOW_MAP_SIZE, SHADOW_MAP_SIZE);
    }
    
    void Display()
    {
        glMatrixMode(GL_MODELVIEW);
        glMultMatrixf( value_ptr(scale(vec3(3.0f))*translate<float>(0,-12.0,0)*rotate<float>(180,0,1,0)) );

        {
            SaveAttrib save;
            glUseProgram( Program::Get("gouraud.vert+gouraud.frag")->Handle() );
            glBindFramebuffer(GL_FRAMEBUFFER, *mFramebuffer);
            glClear(GL_COLOR_BUFFER_BIT|GL_DEPTH_BUFFER_BIT);
            glViewport(0, 0, SHADOW_MAP_SIZE, SHADOW_MAP_SIZE);
            mModel->Draw();
            glBindFramebuffer(GL_FRAMEBUFFER, 0);
        }
        
        {
            Scoped2DMode mode;
            
            Program *prog = Program::Get("dof.frag");
            glUseProgram(*prog);
            prog->Bind("texture", 0, mFramebuffer->GetColorTexture());
            prog->Bind("shadow_texture", 1, mFramebuffer->GetDepthTexture());
            Util::DrawRect(0,0, glutGet(GLUT_WINDOW_WIDTH), glutGet(GLUT_WINDOW_HEIGHT));
            
            glUseProgram(*Program::Get("depth_view.frag"));
            glBindTexture(GL_TEXTURE_2D, *mFramebuffer->GetColorTexture());
            Util::DrawRect(0, 0, 256, 256);
        }
        
    }
};

INITIALIZER()
{
    Scene::Register( "Scene007", Scene007::Create );
}
