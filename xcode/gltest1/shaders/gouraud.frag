uniform sampler2D texture;

void main(void)
{
    vec4 color = texture2DProj(texture, gl_TexCoord[0]);
    // gl_FragColor = gl_Color;
    gl_FragColor = color * gl_Color;
}
