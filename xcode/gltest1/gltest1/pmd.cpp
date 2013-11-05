#include "util.h"
#include <iostream>
#include <fstream>
#include <stdint.h>
#include <OpenGL/gl.h>
#include <iconv.h>
#include "glm/glm.hpp"
#include "glm/gtc/type_ptr.hpp"
#include "glm/gtx/normal.hpp"
#include "glm/gtx/string_cast.hpp"

struct PmdHeader {
    char magic[3];
    float version;
    char model_name[20];
    char comment[256];
} __attribute__((packed));

struct PmdVertex {
    float pos[3];
    float normal_vec[3];
    float uv[2];
    uint16_t bone_num[2];
    uint8_t bone_weight;
    uint8_t edge_flag;
} __attribute__((packed));

struct PmdMaterial {
    float diffuse_color[3];
    float alpha;
    float specularity;
    float specular_color[3];
    float mirror_color[3];
    uint8_t toon_index;
    uint8_t edge_flag;
    uint32_t face_vert_count;
    char *texture_file_name;
} __attribute__((packed));

static int sjis2utf8(char *text, char *buf, size_t bufsize)
{
    iconv_t cd;
    size_t srclen, destlen;
    size_t ret;
    
    cd = iconv_open("UTF-8", "CP932");
    if (cd == (iconv_t)-1) {
        perror("iconv open");
        return 0;
    }
    
    srclen = strlen(text);
    destlen = bufsize - 1;
    memset(buf, '\0', bufsize);

    ret = iconv(cd, &text, &srclen, &buf, &destlen);
    if (ret == -1) {
        perror("iconv");
        exit(1);
        return 0;
    }
    
    iconv_close(cd);
    return 1;
}

uint32_t native( uint32_t i )
{
    return i;
}

uint16_t native( uint16_t i )
{
#if 1
    return i;
#else
    cout << i << " " << (uint16_t)((i << 8) | (i >> 8)) << endl;
    return (i << 8) | (i >> 8);
#endif
}

class PmdFile {
public:
    PmdFile( istream &in )
    {
        try {
            mBufSize = in.seekg(0, ios::end).tellg();
            in.seekg(ios::beg);
            mCur = mBuf = new char[mBufSize];
            in.read(mBuf, mBufSize);
            
            ParseHeader();
            ParseVerteces();
            ParseTriangles();
            ParseMaterials();
            
            PrintInfo();
            
            // throw string("stop");
        }catch( string &err ){
            cout << err << endl;
            exit(1);
        }
    }
    
    ~PmdFile()
    {
        delete[] mBuf;
    }
    
    void PrintInfo()
    {
        cout << "Header: " <<
        " magic:" << mHeader->magic <<
        " version:" << mHeader->version <<
        " model_name:" << mHeader->model_name <<
        " comment-len:" << strlen(mHeader->comment) << endl;
        cout << "Vertex: " << mVertexCount << endl;
        cout << "Triangle: " << mTriangleCount << endl;
        cout << "Material: " << mMaterialCount << endl;
        for(int i=0; i<mMaterialCount; ++i){
            PmdMaterial *m = mMaterial+i;
            cout << "  " << i <<
            ": '" << m->texture_file_name << "'" <<
            " flag:" << (int)m->edge_flag <<
            // " diffuse:" << glm::to_string(glm::make_vec3(m->diffuse_color)) <<
            " count:" << m->face_vert_count << endl;
        }
    }
    
    size_t mBufSize;
    char *mBuf;
    char *mCur;
    
    PmdHeader *mHeader;
    int mVertexCount;
    PmdVertex *mVertex;
    int mTriangleCount;
    uint16_t *mTriangle;
    int mMaterialCount;
    PmdMaterial *mMaterial;
    
private:
    
    uint32_t readUint32()
    {
        uint32_t i = native(*((uint32_t*)mCur));
        mCur += 4;
        return i;
    }
    
    void ParseHeader()
    {
        mHeader = reinterpret_cast<PmdHeader*>(mBuf);
        mCur += sizeof(PmdHeader);
        
        if( memcmp( mHeader->magic, "Pmd", 3 ) ) throw string("invalid magic");
        if( mHeader->version < 1.0 ) throw string("invalid version");
    }
    
    void ParseVerteces()
    {
        mVertexCount = native(*((uint32_t*)mCur));
        mCur += 4;
        mVertex = (PmdVertex*)mCur;
        mCur += sizeof(PmdVertex)*mVertexCount;
        for( int i=0; i<mVertexCount; ++i){
            for( int j=0; j<2; ++j){
                mVertex[i].bone_num[j] = native(mVertex[i].bone_num[j]);
            }
        }
    }
    
    void ParseTriangles()
    {
        mTriangleCount = native(*((uint32_t*)mCur)) / 3;
        mCur += 4;
        mTriangle = (uint16_t*)mCur;
        mCur += 2 * 3 * mTriangleCount;
        for( int i=0; i<mTriangleCount*3; ++i){
            mTriangle[i] = native(mTriangle[i]);
        }
    }
    
    void ParseMaterials()
    {
        mMaterialCount = readUint32();
        mMaterial = new PmdMaterial[mMaterialCount];
        size_t bare_size = sizeof(PmdMaterial) - sizeof(char*);
        size_t record_size = bare_size + 20;
        for(int i=0; i<mMaterialCount; ++i){
            memcpy( mMaterial+i, mCur+record_size*i, bare_size );
            mMaterial[i].face_vert_count = native(mMaterial[i].face_vert_count);
            
            char *texture = mCur+record_size*i+bare_size;
            mMaterial[i].texture_file_name = new char[64];
            sjis2utf8( texture, mMaterial[i].texture_file_name, 64);
            for(int j=0;j<64;j++) if( mMaterial[i].texture_file_name[j]=='*') mMaterial[i].texture_file_name[j] = '\0'; // '*' で切る
        }
        mCur += record_size * mMaterialCount;
    }
};

class PmdLoader: public ModelLoader {
public:
    PmdLoader(){}
    Model* LoadFromFile( const string &filename)
    {
        ifstream in;
        in.open(filename);
        if( !in.is_open() ){
            cout << "cannot open " << filename << endl;
            exit(1);
        }
        
        PmdFile *pmd = new PmdFile(in);
        Model *model = new Model();
        
        char tmp[0x10000*4*3];
        
        for( int i=0; i<pmd->mVertexCount; ++i ){
            memcpy(tmp + i*3*sizeof(GLfloat), pmd->mVertex[i].pos, sizeof(GLfloat)*3 );
        }
        model->mVertexBuf = new Buffer(GL_ARRAY_BUFFER, sizeof(GLfloat), 3, pmd->mVertexCount, tmp);
        
        for( int i=0; i<pmd->mVertexCount; ++i ){
            memcpy(tmp + i*3*sizeof(GLfloat), pmd->mVertex[i].normal_vec, sizeof(GLfloat)*3 );
        }
        model->mNormalBuf = new Buffer(GL_ARRAY_BUFFER, sizeof(GLfloat), 3, pmd->mVertexCount, tmp);
        
        for( int i=0; i<pmd->mVertexCount; ++i ){
            memcpy(tmp + i*2*sizeof(GLfloat), pmd->mVertex[i].uv, sizeof(GLfloat)*2 );
        }
        model->mUvBuf = new Buffer(GL_ARRAY_BUFFER, sizeof(GLfloat), 2, pmd->mVertexCount, tmp);
        
        model->mFaceBuf = new Buffer( GL_ELEMENT_ARRAY_BUFFER, sizeof(GLushort), 3, pmd->mTriangleCount, pmd->mTriangle );
        
        model->mMaterial.resize(pmd->mMaterialCount);
        int idx = 0;
        for( int i=0; i < pmd->mMaterialCount; ++i){
            Material &m = model->mMaterial[i];
            PmdMaterial &pm = pmd->mMaterial[i];
            memcpy( m.diffuse_color, pm.diffuse_color, sizeof(pm.diffuse_color));
            m.diffuse_color[3] = 1.0;
            m.specularity = pm.specularity;
            if(m.specularity == 0) m.specularity = 0.001;
            memcpy( m.specular_color, pm.specular_color, sizeof(pm.specular_color));
            m.specular_color[3] = 1.0;
            m.texture = Texture::Get(pm.texture_file_name);
            m.flag = pm.edge_flag;
            m.start_index = idx;
            m.count = pm.face_vert_count / 3;
            idx += m.count;
        }
        
        return model;
    }
};

INITIALIZER(){
    ModelLoader::Register( "pmd", new PmdLoader() );
};
