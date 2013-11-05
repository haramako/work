uniform sampler2D texture;
const float blur_size = 1.0/512.0;

void main(void)
{
    vec2 tex = gl_TexCoord[0].xy / gl_TexCoord[0].w + vec2(blur_size/4.0, 0.0);
    vec4 sum = vec4(0.0);
	sum += texture2D(texture, vec2(tex.x - 4.0*blur_size, tex.y)) * 0.05;
	sum += texture2D(texture, vec2(tex.x - 3.0*blur_size, tex.y)) * 0.10;
	sum += texture2D(texture, vec2(tex.x - 2.0*blur_size, tex.y)) * 0.12;
	sum += texture2D(texture, vec2(tex.x - 1.0*blur_size, tex.y)) * 0.15;
	sum += texture2D(texture, vec2(tex.x - 0.0*blur_size, tex.y)) * 0.16;
	sum += texture2D(texture, vec2(tex.x + 1.0*blur_size, tex.y)) * 0.15;
	sum += texture2D(texture, vec2(tex.x + 2.0*blur_size, tex.y)) * 0.12;
	sum += texture2D(texture, vec2(tex.x + 3.0*blur_size, tex.y)) * 0.10;
	sum += texture2D(texture, vec2(tex.x + 4.0*blur_size, tex.y)) * 0.05;
    gl_FragColor = sum;
    // gl_FragColor = texture2DProj(texture, gl_TexCoord[0]);
}
