#pragma once

#include <string>
#include <unordered_map>
#include <OpenGL/gl.h>
#include <GLUT/GLUT.h>
#include <iostream>
#include <vector>
#include "glm/glm.hpp"
#include "glm/gtc/type_ptr.hpp"

using namespace std;

extern GLenum g_checked_error;
#define CHECK() \
g_checked_error = glGetError(); \
if(g_checked_error != GL_NO_ERROR){ \
cout << "[ERROR] " << __FILE__ << ":" << __LINE__ << ": " << g_checked_error << " " << gluErrorString(g_checked_error) << endl;\
}

class handled_object {
public:
    handled_object(): mHandle(0) {}
    GLuint Handle(){ return mHandle; }
    operator GLuint(){ return mHandle; }
protected:
    GLuint mHandle;
};

template<class T>
class named_object {
public:
    static T* Get( const string &filename ){
        auto it = sCache.find(filename);
        if(it != sCache.end()) return it->second;
        // not found
        T *x = T::CreateByName(filename);
        sCache[filename] = x;
        return x;
    }
    static void ClearAll(){ sCache.clear(); }
    static void Register(const string &name, T* obj){ sCache[name] = obj; }
protected:
    static unordered_map<string,T*> sCache;
};

template<class T> unordered_map<string,T*> named_object<T>::sCache;

class Texture: public handled_object, public named_object<Texture> {
public:
    Texture(GLuint handle = 0, GLenum texture_type = GL_TEXTURE_2D){ mHandle = handle; mType = texture_type; }
    ~Texture();
    static Texture* CreateByName(const string &filename);
    static Texture* CreateDepthTexture(int width, int height);
    static Texture* CreateTexture(int width, int height);
    GLint Bind(GLint idx = 0);
private:
    GLenum mType;
};

class Framebuffer: public handled_object {
public:
    Framebuffer(int width, int height, bool has_color = true, bool has_depth = true);
    ~Framebuffer();
    Texture* GetColorTexture(){ return mColorTexture; }
    Texture* GetDepthTexture(){ return mDepthTexture; }
private:
    Texture *mColorTexture;
    Texture *mDepthTexture;
};

class Shader: public handled_object, public named_object<Shader> {
public:
    Shader( const string &filename );
    ~Shader();
    static Shader* CreateByName( const string &filename );
};

class Program: public handled_object, public named_object<Program> {
    class Parameter {
    public:
        Parameter(GLuint location): mLocation(location) {}
        Parameter& operator=(GLint v)
        {
            glUniform1i(mLocation,v);
            return *this;
        }
    private:
        GLuint mLocation;
    };
public:
    Program();
    ~Program();
    static Program* CreateByName( const string &filename );

    void Bind( const char *name, GLint val){ GLuint location = glGetUniformLocation(mHandle,name); glUniform1i(location, val); CHECK(); }
    void Bind( const char *name, GLuint target, Texture *texture ){ texture->Bind(target); Bind(name,target); }
    Parameter operator[]( const char *name)
    {
        GLuint idx = glGetUniformLocation(mHandle, name);
        CHECK();
        return Parameter(idx);
    }
};

class Util {
public:
    static void print( int x, int y, const string &str );
    static void DrawRect( GLfloat x, GLfloat y, GLfloat width, GLfloat height, GLfloat z = 0);
    static GLfloat GetFloat(GLenum e){ GLfloat v; glGetFloatv(e,&v); return v; }
    static void SetMatrix(GLenum target, const glm::mat4 &m){ glMatrixMode(target); glLoadMatrixf(glm::value_ptr(m)); }
};

class SaveAttrib {
public:
    SaveAttrib(GLenum bits = GL_ALL_ATTRIB_BITS){ glPushAttrib(bits); }
    ~SaveAttrib(){ glPopAttrib(); }
};

class Scoped2DMode: private SaveAttrib {
public:
    Scoped2DMode(): SaveAttrib(GL_ALL_ATTRIB_BITS)
    {
        glDisable(GL_DEPTH_TEST);
        glDepthMask(GL_FALSE);
        int size = Util::GetFloat(GL_MAX_VIEWPORT_DIMS);
        Util::SetMatrix(GL_PROJECTION, glm::ortho<float>(0, size, 0, size, -1, 1));
        glViewport(0, 0, size, size);
        Util::SetMatrix(GL_MODELVIEW, glm::mat4());
    }
};

class Buffer: public handled_object {
public:
    Buffer( GLenum buffer_type, int data_size, int unit_size, int size, void *p );
    ~Buffer(){ glDeleteBuffers(1, &mHandle); }
    int Size(){ return mSize; }
    void BindAsVertex( size_t index = 0);
    void BindAsNormal( size_t index = 0);
    void BindAsTexCoord( size_t index = 0);
private:
    int mDataSize;
    int mUnitSize;
    int mSize;
    GLenum mBufferType;
};

//================================================================
// Model
//================================================================

struct Material {
    float diffuse_color[4];
    float alpha;
    float specularity;
    float specular_color[4];
    int flag;
    int start_index;
    int count;
    Texture *texture;
} __attribute__((packed));

class Model: public named_object<Model> {
public:
    ~Model(){
        delete mVertexBuf;
        delete mNormalBuf;
        delete mUvBuf;
        delete mFaceBuf;
    }
    
    void Draw();
    
    int mVertexCount;
    int mTriangleCount;
    
    Buffer *mVertexBuf;
    Buffer *mNormalBuf;
    Buffer *mUvBuf;
    Buffer *mFaceBuf;
    
    vector<Material> mMaterial;
    
    static Model* CreateByName(const string &filename);
};

class ModelLoader: public named_object<ModelLoader> {
public:
    ModelLoader(){}
    virtual ~ModelLoader(){}
    virtual Model* LoadFromFile(const string &filename) = 0;
    static Model* Load(const string &filename);
};

//================================================================
// Scene
//================================================================

class Scene {
public:
    virtual ~Scene(){};
    virtual void Init(){}
    virtual void Display(){}
    virtual void BeforeDisplay(){}
    static void Register( const string &name, Scene* (*func)() ){
        sMap[name] = func;
    }
    static Scene* CreateByName( const string &name ){
        return sMap[name]();
    }
    const string& GetParam(const string &key){ return mParams[key]; }
    void SetParam(const string &key, const string &val){ mParams[key] = val; }
private:
    unordered_map<string,string> mParams;
    static unordered_map<string,function<Scene*()>> sMap;
};

struct Initializer {
    Initializer( void (*init_func)() ): mFunc(init_func) { mNext = sRoot; sRoot = this;}
    static void Run(){ if( sRoot ) sRoot->Excecute(); }
private:
    void Excecute(){
        mFunc();
        if( mNext ) mNext->Excecute();
    }
    void (*mFunc)();
    Initializer *mNext;
    static Initializer *sRoot;
};

#define INITIALIZER() \
static void __init_func__();\
static Initializer __initializer__(__init_func__);\
static void __init_func__()

