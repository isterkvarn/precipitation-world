shader_type spatial;

varying vec3 world_normal;

void vertex() {
	// Called for every vertex the material is visible on.
	world_normal = NORMAL;
}

void fragment() {
	// Called for every pixel the material is visible on.
	float slope_amount = abs(world_normal.y);
	ALBEDO = vec3(0.0, 0.1, 0.1) * slope_amount  + (1.0 - slope_amount) * 0.5 * vec3(1.0, 0.1, 0.1);
	//COLOR = vec4(0.0, 0.0, 0.0, 0.0);
}

//void light() {
	// Called for every pixel for every light affecting the material.
	// Uncomment to replace the default light processing function with this one.
//}
