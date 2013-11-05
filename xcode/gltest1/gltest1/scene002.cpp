#include "util.h"
#include <OpenGL/gl.h>
#include "glm/glm.hpp"
#include "glm/gtc/type_ptr.hpp"
#include "glm/gtx/normal.hpp"
#include "glm/gtx/string_cast.hpp"
#include <iostream>
#include "SOIL.h"

using namespace glm;

class Scene002 : public Scene {
public:
    static Scene* Create(){ return new Scene002(); }
    
    Model *mModel;
    GLuint mBuf[4];
    
    Scene002()
    {
        mModel = Model::Get("miku.pmd");
    };
    
    void Display()
    {
        glMatrixMode(GL_MODELVIEW);
        glScalef(3,3,3);
        glTranslated(0,-12.0,0);
        
        glUseProgram( Program::Get("gouraud.vert+gouraud.frag")->Handle() );
        
        glPushAttrib(GL_ALL_ATTRIB_BITS);
        glEnableClientState(GL_VERTEX_ARRAY);
        glEnableClientState(GL_NORMAL_ARRAY);
        glEnableClientState(GL_TEXTURE_COORD_ARRAY);
        glDepthFunc(GL_LEQUAL);

        mModel->mVertexBuf->BindAsVertex();
        mModel->mNormalBuf->BindAsNormal();
        mModel->mUvBuf->BindAsTexCoord();
        glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, *mModel->mFaceBuf);
        int idx = 0;
        for(auto &m: mModel->mMaterial){
            glMaterialfv(GL_FRONT, GL_DIFFUSE, m.diffuse_color);
            glMaterialfv(GL_FRONT, GL_SPECULAR, m.specular_color);
            glMaterialf(GL_FRONT, GL_SHININESS, m.specularity);
            glBindTexture(GL_TEXTURE_2D, *m.texture);
            glDrawElements(GL_TRIANGLES, sizeof(GLushort)*3*m.count, GL_UNSIGNED_SHORT, (void*)(m.start_index*3*sizeof(GLushort)));
            idx++;
        }
        
        glPopAttrib();
    }
};

INITIALIZER()
{
    Scene::Register( "Scene002", Scene002::Create );
}
