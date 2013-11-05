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

struct PmxHeader {
    char magic[4];
    float version;
    uint8_t reading_info_len;
    uint8_t text_encode_type;
    uint8_t appendix_uv;
    uint8_t vertex_index_size;
    uint8_t texture_index_size;
    uint8_t material_index_size;
    uint8_t bone_index_size;
    uint8_t morph_index_size;
    uint8_t rigid_body_index_size;
} __attribute__((packed));

struct PmxModelInfo {
    string name;
    string name_english;
    string comment;
    string comment_english;
};

struct PmxVertex {
    float pos[3];
    float normal_vec[3];
    float uv[2];
    uint16_t bone_num[2];
    uint8_t bone_weight;
    uint8_t edge_flag;
} __attribute__((packed));

struct PmxMaterial {
    string name;
    string name_english;
    float diffuse_color[4];
    float specular_color[3];
    float specularity;
    float ambient_color[4];
    uint8_t draw_flag;
    float edge_color[4];
    float edge_size;
    int32_t texture_index;
    int32_t sphere_index;
    int32_t sphere_mode;
    int32_t toon_flag;
    int32_t toon_index;
    int32_t toon_mode;
    int32_t face_num;
    string memo;
} __attribute__((packed));

static int utf162utf8(char *text, size_t text_len, char *buf, size_t bufsize)
{
    iconv_t cd;
    size_t destlen;
    size_t ret;
    
    cd = iconv_open("UTF-8", "UTF-16LE");
    if (cd == (iconv_t)-1) {
        perror("iconv open");
        exit(1);
        return 0;
    }
    
    destlen = bufsize - 1;
    memset(buf, '\0', bufsize);
    
    ret = iconv(cd, &text, &text_len, &buf, &destlen);
    if (ret == -1) {
        perror("iconv");
        exit(1);
        return 0;
    }
    
    iconv_close(cd);
    return 1;
}

static uint32_t native( uint32_t i )
{
    return i;
}

static uint16_t native( uint16_t i )
{
#if 1
    return i;
#else
    cout << i << " " << (uint16_t)((i << 8) | (i >> 8)) << endl;
    return (i << 8) | (i >> 8);
#endif
}

static uint8_t native( uint8_t i )
{
    return i;
}

class PmxFile {
public:
    PmxFile( istream &in )
    {
        try {
            mBufSize = in.seekg(0, ios::end).tellg();
            in.seekg(ios::beg);
            mCur = mBuf = new char[mBufSize];
            in.read(mBuf, mBufSize);
            
            ParseHeader();
            ParseModelInfo();
            ParseVerteces();
            ParseTriangles();
            ParseTexture();
            ParseMaterials();
            
            PrintInfo();
            
        }catch( string &err ){
            cout << err << endl;
            exit(1);
        }
    }
    
    ~PmxFile()
    {
        delete[] mBuf;
    }
    
    void PrintInfo()
    {
        cout << "Header: " <<
        " magic:" << mHeader.magic <<
        " version:" << mHeader.version <<
        " encode:" << ((mHeader.text_encode_type==0)?"UCS2":"UTF-8") <<
        " index_size:" << (int)mHeader.appendix_uv << "," <<
        (int)mHeader.vertex_index_size << "," <<
        (int)mHeader.texture_index_size << "," <<
        (int)mHeader.material_index_size << "," <<
        (int)mHeader.bone_index_size << "," <<
        (int)mHeader.morph_index_size << "," <<
        (int)mHeader.rigid_body_index_size << endl;
        cout << "Name:" << mModelInfo.name << endl;
        // cout << "Comment:" << mModelInfo.comment << endl;
        //        " model_name:" << mHeader->model_name <<
//        " comment-len:" << strlen(mHeader->comment) << endl;
        cout << "Vertex: " << mVertex.size() << endl;
        cout << "Triangle: " << mTriangle.size()/3 << endl;
        cout << "Texture: " << mTexture.size() << endl;
        cout << "Material: " << mMaterial.size() << endl;
        for(auto &m: mMaterial){
            cout << "  '" << m.name << "'" <<
            " flag:" << (int)m.draw_flag <<
            // " diffuse:" << glm::to_string(glm::make_vec3(m->diffuse_color)) <<
            " count:" << m.face_num << endl;
        }
    }
    
    size_t mBufSize;
    char *mBuf;
    char *mCur;
    
    PmxHeader mHeader;
    PmxModelInfo mModelInfo;
    vector<PmxVertex> mVertex;
    vector<uint16_t> mTriangle;
    vector<string> mTexture;
    vector<PmxMaterial> mMaterial;
    
private:
    
    uint32_t ReadInt(int size)
    {
        switch(size){
            case 1:
                return ReadUint8();
            case 2:
                return ReadUint16();
            case 4:
                return ReadUint32();
            default:
                cout << "invalid size" << endl;
                exit(1);
        }
    }
    
    uint8_t ReadUint8()
    {
        uint8_t i = native(*((uint8_t*)mCur));
        mCur += 1;
        return i;
    }
    
    uint16_t ReadUint16()
    {
        uint16_t i = native(*((uint16_t*)mCur));
        mCur += 2;
        return i;
    }

    uint32_t ReadUint32()
    {
        uint32_t i = native(*((uint32_t*)mCur));
        mCur += 4;
        return i;
    }
    
    float ReadFloat()
    {
        float f = *((float*)mCur);
        mCur += 4;
        return f;
    }
    
    string ReadString()
    {
        int len = ReadUint32();
        if(mHeader.text_encode_type == 0){
            char buf[8192];
            utf162utf8(mCur, len, buf, sizeof(buf));
            string str(buf);
            mCur += len;
            return str;
        }else{
            string str(mCur,len);
            mCur += len;
            return str;
        }
    }
    
    void ParseHeader()
    {
        memcpy(&mHeader.magic, mCur, 4);
        mCur += 4;
        mHeader.version = ReadFloat();
        mHeader.reading_info_len = ReadUint8();
        memcpy( &mHeader.text_encode_type, mCur, mHeader.reading_info_len );
        mCur += mHeader.reading_info_len;
        
        if( memcmp( &mHeader.magic, "PMX ", 4 ) ) throw string("invalid magic");
        if( mHeader.version < 2.0 ) throw string("invalid version");
    }
    
    void ParseModelInfo()
    {
        mModelInfo.name = ReadString();
        mModelInfo.name_english = ReadString();
        mModelInfo.comment = ReadString();
        mModelInfo.comment_english = ReadString();
    }
    
    void ParseVerteces()
    {
        int len = ReadUint32();
        mVertex.resize(len);
        for( auto &v: mVertex ){
            v.pos[0] = ReadFloat();
            v.pos[1] = ReadFloat();
            v.pos[2] = ReadFloat();
            v.normal_vec[0] = ReadFloat();
            v.normal_vec[1] = ReadFloat();
            v.normal_vec[2] = ReadFloat();
            v.uv[0] = ReadFloat();
            v.uv[1] = ReadFloat();
            for( int i=0; i<mHeader.appendix_uv; ++i){
                ReadFloat();
            }
            uint8_t weight_type = ReadUint8();
            switch(weight_type){
                case 0:
                    ReadInt(mHeader.bone_index_size);
                    break;
                case 1:
                    ReadInt(mHeader.bone_index_size);
                    ReadInt(mHeader.bone_index_size);
                    ReadFloat();
                    break;
                default:
                    cout << "invalid weight_type " << (int)weight_type << endl;
                    exit(1);
            }
            ReadFloat(); // edge_scale
        }
    }
    
    void ParseTriangles()
    {
        int len = ReadUint32();
        mTriangle.resize(len);
        for(auto &t: mTriangle){
            t = ReadInt(mHeader.vertex_index_size);
        }
    }
    
    void ParseTexture()
    {
        int len = ReadUint32();
        mTexture.resize(len);
        for(auto &tex: mTexture){
            tex = ReadString();
        }
    }
    
    void ParseMaterials()
    {
        int len = ReadUint32();
        mMaterial.resize(len);
        cout << len << endl;
        for(auto &m: mMaterial){
            m.name = ReadString();
            m.name_english = ReadString();
            cout << m.name << endl;
            for( int i=0; i<4; ++i) m.diffuse_color[i] = ReadFloat();
            for( int i=0; i<3; ++i) m.specular_color[i] = ReadFloat();
            m.specularity = ReadFloat();
            for( int i=0; i<4; ++i) m.ambient_color[i] = ReadFloat();
            m.draw_flag = ReadUint8();
            for( int i=0; i<3/*4*/; ++i) m.edge_color[i] = ReadFloat(); // float3の間違い？
            m.edge_size = ReadFloat();
            m.texture_index = ReadInt(mHeader.texture_index_size);
            m.sphere_index = ReadInt(mHeader.texture_index_size);
            m.sphere_mode = ReadUint8();
            m.toon_mode = ReadUint8();
            if( m.toon_mode == 0 ){
                ReadInt(mHeader.texture_index_size);
            }else{
                ReadUint8();
            }
            // mCur-=4; // float4 -> float3 の分のずれ？
            m.memo = ReadString();
            m.face_num = ReadUint32()/3;
        }
    }
};

class PmxLoader: public ModelLoader {
public:
    PmxLoader(){}
    Model* LoadFromFile( const string &filename)
    {
        ifstream in;
        in.open(filename);
        if( !in.is_open() ){
            cout << "cannot open " << filename << endl;
            exit(1);
        }
        
        PmxFile *pmx = new PmxFile(in);
        Model *model = new Model();
        
        char tmp[0x10000*4*3];
        
        for( int i=0; i<pmx->mVertex.size(); ++i ){
            memcpy(tmp + i*3*sizeof(GLfloat), pmx->mVertex[i].pos, sizeof(GLfloat)*3 );
        }
        model->mVertexBuf = new Buffer(GL_ARRAY_BUFFER, sizeof(GLfloat), 3, pmx->mVertex.size(), tmp);
        
        for( int i=0; i<pmx->mVertex.size(); ++i ){
            memcpy(tmp + i*3*sizeof(GLfloat), pmx->mVertex[i].normal_vec, sizeof(GLfloat)*3 );
        }
        model->mNormalBuf = new Buffer(GL_ARRAY_BUFFER, sizeof(GLfloat), 3, pmx->mVertex.size(), tmp);
        
        for( int i=0; i<pmx->mVertex.size(); ++i ){
            memcpy(tmp + i*2*sizeof(GLfloat), pmx->mVertex[i].uv, sizeof(GLfloat)*2 );
        }
        model->mUvBuf = new Buffer(GL_ARRAY_BUFFER, sizeof(GLfloat), 2, pmx->mVertex.size(), tmp);
        
        model->mFaceBuf = new Buffer( GL_ELEMENT_ARRAY_BUFFER, sizeof(GLushort), 3, pmx->mTriangle.size()/3,
                                     pmx->mTriangle.data() );
        
        model->mMaterial.resize(pmx->mMaterial.size());
        int idx = 0;
        int n = 0;
        for(auto &pm: pmx->mMaterial){
            Material &m = model->mMaterial[n];
            memcpy( m.diffuse_color, pm.diffuse_color, sizeof(pm.diffuse_color));
            m.specularity = pm.specularity;
            if(m.specularity == 0) m.specularity = 0.001;
            memcpy( m.specular_color, pm.specular_color, sizeof(pm.specular_color));
            m.specular_color[3] = 1.0;
            if( pm.texture_index == 255){
                m.texture = Texture::Get("");
            }else{
                m.texture = Texture::Get(pmx->mTexture[pm.texture_index]);
            }
            m.flag = pm.draw_flag;
            m.start_index = idx;
            m.count = pm.face_num;
            idx += m.count;
            n++;
        }
        cout << "vsize:" << pmx->mVertex.size() << " idx:" << idx << endl;
        
        return model;
    }
};

INITIALIZER(){
    ModelLoader::Register( "pmx", new PmxLoader() );
};
