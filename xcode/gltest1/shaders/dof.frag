uniform sampler2D texture;
uniform sampler2D shadow_texture;

vec4 get_blur( float x, float y, vec2 tex, float blur, float depth)
{
    vec2 tex2 = tex + vec2(blur*x, blur*y);
    vec4 color;
    if( texture2D(shadow_texture, tex2).r >= (depth - 0.3) ){
        return texture2D(texture, tex2);
    }else{
        return texture2D(texture, tex);
    }
}

void main(void)
{
    vec2 tex = gl_TexCoord[0].xy / gl_TexCoord[0].w;
    float depth = texture2D(shadow_texture, tex).r;
    if( depth >= 1.0 ) discard;
    float blur = abs(depth - 0.6)/32.0;
    vec4 sum = vec4(0.0);
    float c = 1.0;
    if( blur < 0.03/32.0 ){
        gl_FragColor = texture2D(texture, tex);
    }else if( blur < 0.07/32.0 ){
        for( int x = -1; x <= 1; x++ ){
            for( int y = -1; y <= 1; y++ ){
                sum += get_blur(float(x),float(y),tex,blur,depth);
            }
        }
        gl_FragColor = sum / 9.0;
    }else{
        for( int x = -2; x <= 2; x++ ){
            for( int y = -2; y <= 2; y++ ){
                sum += get_blur(float(x),float(y),tex,blur,depth);
            }
        }
        gl_FragColor = sum / 25.0;
    }
}
