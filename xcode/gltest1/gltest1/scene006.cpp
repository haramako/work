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

class Scene006 : public Scene {
public:
    static Scene* Create(){ return new Scene006(); }
    
    Model *mModel;
    Texture *mColor;
    Texture *mDepth;
    GLuint mFramebuffer;
    Texture *mColor2;
    GLuint mFramebuffer2;
    
    void Init()
    {
        mModel = Model::Get("miku.pmd");
        
        mColor = Texture::CreateTexture(SHADOW_MAP_SIZE, SHADOW_MAP_SIZE);
        mDepth = Texture::CreateDepthTexture(SHADOW_MAP_SIZE, SHADOW_MAP_SIZE);
        glGenFramebuffers(1,&mFramebuffer);
        glBindFramebuffer(GL_FRAMEBUFFER, mFramebuffer);
        glFramebufferTexture2DEXT(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, *mColor, 0);
        glFramebufferTexture2DEXT(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, GL_TEXTURE_2D, *mDepth, 0);
        glBindFramebuffer(GL_FRAMEBUFFER, 0);
        
        mColor2 = Texture::CreateTexture(SHADOW_MAP_SIZE, SHADOW_MAP_SIZE);
        glGenFramebuffers(1,&mFramebuffer2);
        glBindFramebuffer(GL_FRAMEBUFFER, mFramebuffer2);
        glFramebufferTexture2DEXT(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, *mColor2, 0);
        glBindFramebuffer(GL_FRAMEBUFFER, 0);
        
    };
        
    void Display()
    {
        CHECK();
        glMatrixMode(GL_MODELVIEW);
        glMultMatrixf( value_ptr(scale(vec3(3.0f))*translate<float>(0,-12.0,0)*rotate<float>(180,0,1,0)) );

        {
            SaveAttrib save;
            glUseProgram( Program::Get("gouraud.vert+gouraud.frag")->Handle() );
            glBindFramebuffer(GL_FRAMEBUFFER, mFramebuffer);
            glClear(GL_COLOR_BUFFER_BIT|GL_DEPTH_BUFFER_BIT);
            glViewport(0, 0, SHADOW_MAP_SIZE, SHADOW_MAP_SIZE);
            mModel->Draw();
            glBindFramebuffer(GL_FRAMEBUFFER, 0);
        }
        
        {
            SaveAttrib save;
            glDisable(GL_DEPTH_TEST);
            glDepthMask(GL_FALSE);
            int size = Util::GetFloat(GL_MAX_VIEWPORT_DIMS);
            Util::SetMatrix(GL_PROJECTION, ortho<float>(0, size, 0, size, -1, 1));
            glViewport(0, 0, size, size);
            Util::SetMatrix(GL_MODELVIEW, mat4());
            
            glBindFramebuffer(GL_FRAMEBUFFER, mFramebuffer2);
            glClear(GL_COLOR_BUFFER_BIT);
            glUseProgram(*Program::Get("gauss_x.frag"));
            glBindTexture(GL_TEXTURE_2D, *mColor);
            Util::DrawRect(0,0, SHADOW_MAP_SIZE, SHADOW_MAP_SIZE);
            glBindFramebuffer(GL_FRAMEBUFFER, 0);
            
            glUseProgram(*Program::Get("gauss_y.frag"));
            glBindTexture(GL_TEXTURE_2D, *mColor2);
            Util::DrawRect(0,0, SHADOW_MAP_SIZE, SHADOW_MAP_SIZE);
            
            glUseProgram(*Program::Get("depth_view.frag"));
            glBindTexture(GL_TEXTURE_2D, *mColor);
            Util::DrawRect(0, 0, 256, 256);
            glBindTexture(GL_TEXTURE_2D, *mColor2);
            Util::DrawRect(256, 0, 256, 256);
            
        }
        
    }
};

INITIALIZER()
{
    Scene::Register( "Scene006", Scene006::Create );
}
