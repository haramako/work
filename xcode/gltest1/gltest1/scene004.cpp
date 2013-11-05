#include "util.h"
#include <OpenGL/gl.h>
#include "glm/glm.hpp"
#include "glm/gtc/type_ptr.hpp"
#include "glm/gtx/normal.hpp"
#include "glm/gtx/string_cast.hpp"
#include <iostream>

using namespace glm;
const int SHADOW_MAP_SIZE = 512;

static Texture* _create_depth_texture( int width, int height )
{
    GLuint tex;
    glGenTextures(1, &tex);
    glBindTexture(GL_TEXTURE_2D, tex);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_COMPARE_MODE, GL_COMPARE_R_TO_TEXTURE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_COMPARE_FUNC, GL_LEQUAL);
    glTexParameteri(GL_TEXTURE_2D, GL_DEPTH_TEXTURE_MODE, GL_LUMINANCE);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_DEPTH_COMPONENT, width, height, 0, GL_DEPTH_COMPONENT, GL_UNSIGNED_BYTE, nullptr);
    CHECK();
    return new Texture(tex);
}

class Scene004 : public Scene {
public:
    static Scene* Create(){ return new Scene004(); }
    
    Model *mModel;
    Texture *mDepth;
    GLuint mFramebuffer;
    
    void Init()
    {
        mModel = Model::Get("miku.pmd");
        
        mDepth = _create_depth_texture(SHADOW_MAP_SIZE, SHADOW_MAP_SIZE);
        glGenFramebuffersEXT(1,&mFramebuffer);
        glBindFramebufferEXT(GL_FRAMEBUFFER_EXT, mFramebuffer);
        glFramebufferTexture2DEXT(GL_FRAMEBUFFER_EXT, GL_DEPTH_ATTACHMENT_EXT, GL_TEXTURE_2D, *mDepth, 0);
        glDrawBuffer(GL_NONE);
        glReadBuffer(GL_NONE);
        glBindFramebufferEXT(GL_FRAMEBUFFER_EXT, 0);
    };
    
    void Display()
    {
        glMatrixMode(GL_MODELVIEW);
        glScalef(3,3,3);
        glTranslated(0,-12.0,0);

        {
            // draw depth map
            SaveAttrib save;
            glBindFramebufferEXT(GL_FRAMEBUFFER_EXT, mFramebuffer);
            glClear(GL_DEPTH_BUFFER_BIT);
            glViewport(0, 0, SHADOW_MAP_SIZE, SHADOW_MAP_SIZE);
            
            glUseProgram( *Program::Get("simple.vert+simple.frag") );
            glEnableClientState(GL_VERTEX_ARRAY);
            
            mModel->mVertexBuf->BindAsVertex();
            glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, *mModel->mFaceBuf);
            for(auto &m: mModel->mMaterial){
                glDrawElements(GL_TRIANGLES, sizeof(GLushort)*3*m.count, GL_UNSIGNED_SHORT, (void*)(m.start_index*3*sizeof(GLushort)));
            }

            glBindFramebufferEXT(GL_FRAMEBUFFER_EXT, 0);
        }
        
        {
            SaveAttrib save;
            glDisable(GL_DEPTH_TEST);
            glMatrixMode(GL_PROJECTION);
            glLoadIdentity();
            glOrtho(0, 1024, 0, 1024, -1, 1);
            glViewport(0, 0, 1024, 1024);
            glMatrixMode(GL_MODELVIEW);
            glLoadIdentity();
            
            glUseProgram( Program::Get("depth_view.vert+depth_view.frag")->Handle() );
            glBindTexture(GL_TEXTURE_2D, *mDepth);
            
            Util::DrawRect(0, 0, 512, 512);
        }

        CHECK();
    }
};

INITIALIZER()
{
    Scene::Register( "Scene004", Scene004::Create );
}
