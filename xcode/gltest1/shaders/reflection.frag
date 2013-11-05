uniform sampler2D texture;
uniform samplerCube cube_texture;

varying vec3 reflection;

void main(void)
{
    vec4 color = texture2DProj(texture, gl_TexCoord[0]);
    vec4 ref_color = textureCube(cube_texture, reflection);
    gl_FragColor = color * gl_Color * 0.5 + ref_color * 0.5;
}
