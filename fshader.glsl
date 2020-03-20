#version 330 core
uniform sampler2D tex_map;
//uniform float near;
//uniform float far;
//uniform vec3 light_pos;
uniform vec3 light_color;
uniform vec3 ambient_color;
//uniform vec3 view_pos;

in vec4 color;
in vec2 tex_cord;
in vec3 normal;
in vec3 frag_pos;
in vec3 _light_pos;

in vec4 gl_FragCoord;


void main() {

	vec3 light_pos = _light_pos;

	vec4 tex_color = texture(tex_map, tex_cord);
	vec3 surface_color = mix(tex_color.rgb, color.rgb, color.a);

	float dist = length(light_pos - frag_pos);
	float ant = (1.0 / (1.0 + (0.25 * dist * dist)));

	vec3 norm = normalize(normal);
	vec3 light_dir = normalize(light_pos - frag_pos);
	float diff = max(dot(norm, light_dir), 0.0);
	vec3 diffuse_color = diff * light_color * ant;

	float specular_strength = 1;
    float spec = pow(max(dot(normalize(-frag_pos), reflect(-light_dir, norm)), 0.0), 32);
    vec3 specular = specular_strength * spec * light_color * ant;

	gl_FragColor = vec4(surface_color * (ambient_color + diffuse_color + specular), 1);
	// test specular:
	//gl_FragColor = vec4(mix(surface_color, vec3(1,1,1), 0.999) * (mix(ambient_color, vec3(0,0,0), 0.999) + mix(diffuse_color, vec3(0,0,0), 0.999) + specular), 1);
	// test diffuse:
	//gl_FragColor = vec4(mix(surface_color, vec3(1,1,1), 0.999) * (mix(ambient_color, vec3(0,0,0), 0.999) + mix(specular, vec3(0,0,0), 0.999) + diffuse_color), 1);
	// test without light:
	//gl_FragColor = vec4(surface_color * mix(ambient_color + diffuse_color + specular, vec3(1,1,1), 0.999), 1);

}
