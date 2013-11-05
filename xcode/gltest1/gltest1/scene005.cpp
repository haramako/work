#include "util.h"
#include <OpenGL/gl.h>
#include "glm/glm.hpp"
#include "glm/gtc/type_ptr.hpp"
#include "glm/gtx/normal.hpp"
#include "glm/gtx/string_cast.hpp"
#include "glm/gtx/transform.hpp"
#include <iostream>

using namespace glm;
const int SHADOW_MAP_SIZE = 1024;

class Scene005 : public Scene {
public:
    static Scene* Create(){ return new Scene005(); }
    
    Model *mModel;
    Texture *mDepth;
    GLuint mFramebuffer;
    
    void Init()
    {
        mModel = Model::Get("miku.pmd");
        
        mDepth = Texture::CreateDepthTexture(SHADOW_MAP_SIZE, SHADOW_MAP_SIZE);
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
        glScalef(2,2,2);
        glTranslated(0,-12.0,0);
        
        GLfloat light_matrix[16];

        {
            // draw depth map
            SaveAttrib save;
            glBindFramebufferEXT(GL_FRAMEBUFFER_EXT, mFramebuffer);
            glClear(GL_DEPTH_BUFFER_BIT);
            glCullFace(GL_FRONT);
            glViewport(0, 0, SHADOW_MAP_SIZE, SHADOW_MAP_SIZE);
            
            glMatrixMode(GL_PROJECTION);
            glPushMatrix();
            glLoadIdentity();
            glOrtho(-20, 20, -20, 20, 20, 200);
            glTranslated(0, 1, 1);
            gluLookAt(0, 100, 100, 0, 0, 0, 0, 10, 0);
            glGetFloatv(GL_PROJECTION_MATRIX, light_matrix);
            glMatrixMode(GL_MODELVIEW);
            
            glUseProgram( *Program::Get("simple.vert+simple.frag") );
            glEnableClientState(GL_VERTEX_ARRAY);
            
            mModel->mVertexBuf->BindAsVertex();
            glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, *mModel->mFaceBuf);
            for(auto &m: mModel->mMaterial){
                if( m.flag == 0 ) continue;
                glDrawElements(GL_TRIANGLES, sizeof(GLushort)*3*m.count, GL_UNSIGNED_SHORT, (void*)(m.start_index*3*sizeof(GLushort)));
            }

            glBindFramebufferEXT(GL_FRAMEBUFFER_EXT, 0);
            glMatrixMode(GL_PROJECTION);
            glPopMatrix();
            glMatrixMode(GL_MODELVIEW);
        }

        glEnableClientState(GL_VERTEX_ARRAY);
        glEnableClientState(GL_NORMAL_ARRAY);
        glEnableClientState(GL_TEXTURE_COORD_ARRAY);
        glDepthFunc(GL_LEQUAL);
        
        glUseProgram(*Program::Get("depth_shadow.vert+depth_shadow.frag"));
        
        // set shadow texture
        Program *prog = Program::Get("depth_shadow.vert+depth_shadow.frag");
        (*prog)["shadow_texture"] = mDepth->Bind(1);
        mat4 x = translate(vec3(0.5)) * scale(vec3(0.5)) * translate<float>(0,0,-0.001) * make_mat4(light_matrix);
        glUniformMatrix4fv(glGetUniformLocation(*prog, "light_matrix"), 1, GL_FALSE, value_ptr(x));
        
        mModel->mVertexBuf->BindAsVertex();
        mModel->mNormalBuf->BindAsNormal();
        mModel->mUvBuf->BindAsTexCoord();
        glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, *mModel->mFaceBuf);
        for(auto &m: mModel->mMaterial){
            glMaterialfv(GL_FRONT, GL_DIFFUSE, m.diffuse_color);
            glMaterialfv(GL_FRONT, GL_SPECULAR, m.specular_color);
            glMaterialf(GL_FRONT, GL_SHININESS, m.specularity);
            glBindTexture(GL_TEXTURE_2D, *m.texture);
            glDrawElements(GL_TRIANGLES, sizeof(GLushort)*3*m.count, GL_UNSIGNED_SHORT, (void*)(m.start_index*3*sizeof(GLushort)));
        }

        {
            SaveAttrib save;
            glDisable(GL_DEPTH_TEST);
            int size = Util::GetFloat(GL_MAX_VIEWPORT_DIMS);
            Util::SetMatrix(GL_PROJECTION, ortho<float>(0, size, 0, size, -1, 1));
            glViewport(0, 0, size, size);
            Util::SetMatrix(GL_MODELVIEW, mat4());
            
            glUseProgram(Program::Get("depth_view.frag")->Handle());
            glBindTexture(GL_TEXTURE_2D, *mDepth);
            
            Util::DrawRect(0, 0, 256, 256);
        }

        CHECK();
    }
};

INITIALIZER()
{
    Scene::Register( "Scene005", Scene005::Create );
}
