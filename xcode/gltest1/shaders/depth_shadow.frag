uniform sampler2D texture;
uniform sampler2DShadow shadow_texture;

varying vec4 shadow_vec;
varying vec4 ambient_color;

void main(void)
{
    vec4 color = texture2DProj(texture, gl_TexCoord[0]);
    vec4 shadow = shadow2DProj(shadow_texture, shadow_vec);
    gl_FragColor = color * (gl_Color * shadow.r + ambient_color);
}
