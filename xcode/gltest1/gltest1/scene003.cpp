#include "util.h"
#include <OpenGL/gl.h>
#include "glm/glm.hpp"
#include "glm/gtc/type_ptr.hpp"
#include "glm/gtx/normal.hpp"
#include "glm/gtx/string_cast.hpp"
#include <iostream>

using namespace glm;
const int SHADOW_MAP_SIZE = 512;

class Scene003 : public Scene {
public:
    static Scene* Create(){ return new Scene003(); }
    
    Model *mModel;
    GLuint mBuf[4];
    GLuint mShadowMapTexture;
    
    Scene003()
    {
        mModel = Model::Get("miku.pmd");
        glGenTextures(1, &mShadowMapTexture);
        glBindTexture(GL_TEXTURE_2D, mShadowMapTexture);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_COMPARE_MODE, GL_COMPARE_R_TO_TEXTURE);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_COMPARE_FUNC, GL_LEQUAL);
        glTexParameteri(GL_TEXTURE_2D, GL_DEPTH_TEXTURE_MODE, GL_LUMINANCE);
        glTexImage2D(GL_TEXTURE_2D, 0, GL_DEPTH_COMPONENT, SHADOW_MAP_SIZE, SHADOW_MAP_SIZE, 0, GL_DEPTH_COMPONENT, GL_UNSIGNED_BYTE, nullptr);
        CHECK();
    };
        
    void Display()
    {
        glMatrixMode(GL_MODELVIEW);
        glScalef(3,3,3);
        glTranslated(0,-12.0,0);

        glPushAttrib(GL_ALL_ATTRIB_BITS);
        glEnableClientState(GL_VERTEX_ARRAY);
        glViewport(0, 0, SHADOW_MAP_SIZE, SHADOW_MAP_SIZE);
        // glColorMask(GL_FALSE, GL_FALSE, GL_FALSE, GL_FALSE);

        glUseProgram( Program::Get("depth.vert+depth.frag")->Handle() );
        //        glUseProgram( Program::Get("depth.vert+depth.frag")->Handle() );
        
        mModel->mVertexBuf->BindAsVertex();
        glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, *mModel->mFaceBuf);
        for(auto &m: mModel->mMaterial){
            glDrawElements(GL_TRIANGLES, sizeof(GLushort)*3*m.count, GL_UNSIGNED_SHORT, (void*)(m.start_index*3*sizeof(GLushort)));
        }
        
        glBindTexture(GL_TEXTURE_2D, mShadowMapTexture);
        glCopyTexSubImage2D(GL_TEXTURE_2D, 0, 0, 0, 0, 0, SHADOW_MAP_SIZE, SHADOW_MAP_SIZE);
        
        // glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
        
        glPopAttrib();
        
        glMatrixMode(GL_PROJECTION);
        glLoadIdentity();
        glOrtho(0, 20, 0, 20, 1, 10);
        glMatrixMode(GL_MODELVIEW);
        glLoadIdentity();
        
        glUseProgram( Program::Get("gouraud.vert+depth_view.frag")->Handle() );
        //glUseProgram(0);
        glEnable(GL_TEXTURE_2D);
        glBindTexture(GL_TEXTURE_2D, mShadowMapTexture);
        // glBindTexture(GL_TEXTURE_2D, *Texture::Get("顔.tga"));
        
        glBegin(GL_QUADS);
        glTexCoord2f(0,0);
        glVertex3f(0,0,-2);
        glTexCoord2f(1,0);
        glVertex3f(10,0,-2);
        glTexCoord2f(1,1);
        glVertex3f(10,10,-2);
        glTexCoord2f(0,1);
        glVertex3f(0,10,-2);
        glEnd();

        CHECK();
    }
};

INITIALIZER()
{
    Scene::Register( "Scene003", Scene003::Create );
}
