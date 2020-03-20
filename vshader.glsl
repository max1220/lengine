#version 330 core
uniform mat4 MAT_M;
uniform mat4 MAT_V;
uniform mat4 MAT_P;
uniform mat4 MAT_MVP;
uniform vec3 light_pos;

attribute vec4 vPosition;
attribute vec4 vColor;
attribute vec2 vTexCord;
attribute vec3 vNormal;

out vec4 color;
out vec2 tex_cord;
out vec3 normal;
out vec3 frag_pos;
out vec3 _light_pos;

void main() {
	//mat4 MVP = MAT_P * MAT_V * MAT_M;
	//gl_Position = MVP * vPosition;
	gl_Position = MAT_MVP * vPosition;

	color = vColor;
	tex_cord = vTexCord;
	normal = mat3(transpose(inverse(MAT_V * MAT_M))) * vNormal;
	frag_pos = vec3(MAT_V * MAT_M * vPosition);
	_light_pos = vec3(MAT_V * vec4(light_pos, 1));
}
