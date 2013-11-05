#include "util.h"
#include <OpenGL/gl.h>
#include "glm/glm.hpp"
#include "glm/gtc/type_ptr.hpp"
#include "glm/gtx/normal.hpp"
#include "glm/gtx/string_cast.hpp"
#include "glm/gtx/transform.hpp"
#include <iostream>

using namespace glm;

class Scene008 : public Scene {
public:
    static Scene* Create(){ return new Scene008(); }
    
    Model *mModel;
    Texture *mCubeTexture;
    
    void Init()
    {
        mModel = Model::Get( GetParam("model") );
        mCubeTexture = Texture::Get("cube.png");
    };
        
    void Display()
    {
        glMatrixMode(GL_MODELVIEW);
        glMultMatrixf( value_ptr(scale(vec3(2.0f))*translate<float>(0,-12.0,0)*rotate<float>(180,0,1,0)) );

        {
            SaveAttrib save;
            Program *prog = Program::Get("reflection.vert+reflection.frag");
            glUseProgram( *prog );
            prog->Bind("texture", 0);
            prog->Bind("cube_texture", mCubeTexture->Bind(1));
            mModel->Draw();
        }
    }
};

INITIALIZER()
{
    Scene::Register( "Scene008", Scene008::Create );
}
