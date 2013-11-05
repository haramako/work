#include "util.h"
#include <OpenGL/gl.h>
#include <GLUT/GLUT.h>
#include <stdio.h>
#include <stdlib.h>
#include <sstream>
#include <iostream>
#include "SOIL.h"

GLenum g_checked_error;

//================================================================

Texture::~Texture()
{
    glDeleteTextures(1,&mHandle);
}

Texture* Texture::CreateByName( const string &filename )
{
    if( filename.empty() ){
        // ""の場合、無色テクスチャ を返す
        GLuint mTex;
        glGenTextures(1, &mTex);
        glBindTexture(GL_TEXTURE_2D, mTex);
        GLfloat pixel[] = {0,0,0,0};
        glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, 1, 1, 0, GL_RGBA, GL_FLOAT, pixel);
        CHECK();
        return new Texture(mTex);
    }
    
    GLuint handle;
    GLenum texture_type;
    if( filename.find("cube.") != string::npos ){
        handle = SOIL_load_OGL_single_cubemap(filename.c_str(), "UENWSD", SOIL_LOAD_AUTO, SOIL_CREATE_NEW_ID, 0);
        texture_type = GL_TEXTURE_CUBE_MAP;
    }else{
        handle = SOIL_load_OGL_texture(filename.c_str(), SOIL_LOAD_AUTO, SOIL_CREATE_NEW_ID, 0);
        texture_type = GL_TEXTURE_2D;
    }
    
    if(!handle){
        cout << "cannot load texture " << filename << endl;
        exit(1);
    }
    return new Texture(handle, texture_type);
}

Texture* Texture::CreateDepthTexture(int width, int height)
{
    GLuint tex;
    glGenTextures(1, &tex);
    glBindTexture(GL_TEXTURE_2D, tex);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_DEPTH_COMPONENT, width, height, 0, GL_DEPTH_COMPONENT, GL_UNSIGNED_BYTE, nullptr);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_COMPARE_MODE, GL_COMPARE_R_TO_TEXTURE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_COMPARE_FUNC, GL_LEQUAL);
    glTexParameteri(GL_TEXTURE_2D, GL_DEPTH_TEXTURE_MODE, GL_LUMINANCE);
    CHECK();
    return new Texture(tex);
}

Texture* Texture::CreateTexture(int width, int height)
{
    GLuint tex;
    glGenTextures(1, &tex);
    glBindTexture(GL_TEXTURE_2D, tex);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, width, height, 0, GL_RGBA, GL_UNSIGNED_BYTE, nullptr);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    CHECK();
    return new Texture(tex);
}

GLint Texture::Bind(GLint idx)
{
    GLint old;
    glGetIntegerv(GL_ACTIVE_TEXTURE, &old);
    glActiveTexture(GL_TEXTURE0+idx);
    glBindTexture(mType, mHandle);
    glActiveTexture(old);
    CHECK();
    return idx;
}

//================================================================
Framebuffer::Framebuffer(int width, int height, bool has_color, bool has_depth): mColorTexture(nullptr), mDepthTexture(nullptr)
{
    glGenFramebuffers(1,&mHandle);
    glBindFramebuffer(GL_FRAMEBUFFER, mHandle);
    if( has_color ){
        mColorTexture = Texture::CreateTexture(width, height);
        glFramebufferTexture2DEXT(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, *mColorTexture, 0);
    }
    
    if(has_depth){
        mDepthTexture = Texture::CreateDepthTexture(width, height);
        glFramebufferTexture2DEXT(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, GL_TEXTURE_2D, *mDepthTexture, 0);
    }
    
    glBindFramebuffer(GL_FRAMEBUFFER, 0);
    CHECK();
}

Framebuffer::~Framebuffer()
{
    
}

//================================================================

Shader* Shader::CreateByName( const string &filename )
{
    return new Shader(filename);
}

Shader::Shader( const string &filename )
{
    GLenum shader_type;
    if( filename.rfind(".frag") != string::npos ){
        shader_type = GL_FRAGMENT_SHADER;
    }else if( filename.rfind(".vert") != string::npos ){
        shader_type = GL_VERTEX_SHADER;
    }else{
        printf( "unkonwn file type %s\n", filename.c_str() );
        exit(-1);
    }
    
    mHandle = glCreateShader( shader_type );
    FILE *fp;
    const GLchar *source;
    GLsizei length;
    int ret;
    
    /* ファイルを開く */
    fp = fopen((string("shaders/")+filename).c_str(), "rb");
    if (fp == NULL) {
        printf( "cannot open %s\n", filename.c_str());
        exit(-1);
    }
    
    /* ファイルの末尾に移動し現在位置（つまりファイルサイズ）を得る */
    fseek(fp, 0L, SEEK_END);
    length = (GLsizei)ftell(fp);
    
    /* ファイルサイズのメモリを確保 */
    source = (GLchar *)malloc(length);
    if (source == NULL) {
        fprintf(stderr, "Could not allocate read buffer.\n");
        exit(-1);
    }
    
    /* ファイルを先頭から読み込む */
    fseek(fp, 0L, SEEK_SET);
    ret = fread((void *)source, 1, length, fp) != (size_t)length;
    fclose(fp);
    
    /* シェーダのソースプログラムのシェーダオブジェクトへの読み込み */
    if (ret){
        fprintf(stderr, "Could not read file: %s.\n", filename.c_str());
    }else{
        glShaderSource(mHandle, 1, &source, &length);
    }
    
    /* 確保したメモリの開放 */
    free((void *)source);
    
    // コンパイル
    GLint compiled;
    glCompileShader(mHandle);
    glGetShaderiv(mHandle, GL_COMPILE_STATUS, &compiled);
    if( compiled == GL_FALSE ){
        printf( "cannot compile %s\n", filename.c_str() );
        char buf[8192];
        glGetShaderInfoLog(mHandle, sizeof(buf), NULL, buf);
        puts(buf);
        exit(1);
    }
}

Shader::~Shader()
{
    glDeleteShader(mHandle);
}

//================================================================

Program::Program()
{
    mHandle = glCreateProgram();
}

Program::~Program()
{
    glDeleteProgram(mHandle);
}

Program* Program::CreateByName( const string &filename )
{
    Program *program = new Program();
    stringstream ss(filename);
    while( !ss.eof() ){
        string buf;
        getline(ss,buf,'+');
        glAttachShader(program->Handle(), Shader::Get(buf)->Handle() );
    }
    
    glLinkProgram(program->Handle());
    GLint linked;
    glGetProgramiv(program->Handle(), GL_LINK_STATUS, &linked);
    if( linked == GL_FALSE ){
        printf( "link failed %s\n", filename.c_str() );
        char buf[8192];
        glGetProgramInfoLog(program->Handle(), sizeof(buf), NULL, buf);
        puts( buf );
        exit(1);
    }
    
    sCache[filename] = program;
    return program;
}

//================================================================

void Util::print( int x, int y, const string &str )
{
    glPushAttrib(GL_ALL_ATTRIB_BITS);
    glUseProgram(0);
    glColor3f(1,1,1);
    
    glWindowPos2i(x,y);
    for( char c: str ){
        glutBitmapCharacter(GLUT_BITMAP_HELVETICA_18, c );
    }
    
    glPopAttrib();
}

void Util::DrawRect( GLfloat x, GLfloat y, GLfloat width, GLfloat height, GLfloat z )
{
    glBegin(GL_QUADS);
    glTexCoord2f(0,0);
    glVertex3f(x,y,z);
    glTexCoord2f(1,0);
    glVertex3f(x+width,y,z);
    glTexCoord2f(1,1);
    glVertex3f(x+width,y+height,z);
    glTexCoord2f(0,1);
    glVertex3f(x,y+height,z);
    glEnd();
}



//================================================================

Buffer::Buffer( GLenum buffer_type, int data_size, int unit_size, int size, void *p )
{
    mBufferType = buffer_type;
    mDataSize = data_size;
    mUnitSize = unit_size;
    mSize = size;
    glGenBuffers(1,&mHandle);
    glBindBuffer(mBufferType, mHandle);
    glBufferData(mBufferType, mDataSize*mUnitSize*mSize, p, GL_STATIC_DRAW);
}

void Buffer::BindAsVertex( size_t index)
{
    glBindBuffer(GL_ARRAY_BUFFER, mHandle);
    glVertexPointer(mUnitSize, GL_FLOAT, 0, (GLvoid*)index);
}

void Buffer::BindAsNormal( size_t index)
{
    glBindBuffer(GL_ARRAY_BUFFER, mHandle);
    glNormalPointer(GL_FLOAT, 0, (GLvoid*)index);
}

void Buffer::BindAsTexCoord( size_t index)
{
    glBindBuffer(GL_ARRAY_BUFFER, mHandle);
    glTexCoordPointer(mUnitSize, GL_FLOAT, 0, (GLvoid*)index);
}

//================================================================

void Model::Draw()
{
    CHECK();
    SaveAttrib save;
    glEnableClientState(GL_VERTEX_ARRAY);
    glEnableClientState(GL_NORMAL_ARRAY);
    glEnableClientState(GL_TEXTURE_COORD_ARRAY);
    glDepthFunc(GL_LEQUAL);
    
    mVertexBuf->BindAsVertex();
    mNormalBuf->BindAsNormal();
    mUvBuf->BindAsTexCoord();
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, *mFaceBuf);
    int idx = 0;
    for(auto &m: mMaterial){
        glMaterialfv(GL_FRONT, GL_DIFFUSE, m.diffuse_color);
        glMaterialfv(GL_FRONT, GL_SPECULAR, m.specular_color);
        glMaterialf(GL_FRONT, GL_SHININESS, m.specularity);
        glBindTexture(GL_TEXTURE_2D, *m.texture);
        glDrawElements(GL_TRIANGLES, sizeof(GLushort)*3*m.count, GL_UNSIGNED_SHORT, (void*)(m.start_index*3*sizeof(GLushort)));
        idx++;
        CHECK();
    }
    CHECK();
}

Model* Model::CreateByName(const string &filename)
{
    return ModelLoader::Load(filename);
}

//================================================================
#include <stdlib.h>

Model* ModelLoader::Load(const string &filename)
{
    string ext(filename.substr(filename.find_last_of(".")+1));
    for(auto loader: sCache){
        if( loader.first == ext ){
            return loader.second->LoadFromFile(filename);
        }
    }
    return NULL;
}


//================================================================

unordered_map<string,function<Scene*()>> Scene::sMap;

Initializer* Initializer::sRoot = nullptr;

