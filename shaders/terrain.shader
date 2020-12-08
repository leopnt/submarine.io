shader_type canvas_item;

uniform int terrainDisplay;
uniform sampler2D tex;
uniform float width;
uniform float height;
uniform float l;


void fragment() {
	vec2 north_coor = vec2(UV.x, UV.y -1.0/height);
	vec2 west_coor = vec2(UV.x -1.0/width, UV.y);
	
	int hN = int(texture(tex, north_coor).r * l); //because it's black&white so take the r value  or anything else (blue, green), it doesn't matter
	int hW = int(texture(tex, west_coor).r * l);
	int h0 = int(texture(tex, UV).r * l);
	float h = texture(tex, UV).r;
	
	float shN = (texture(tex, north_coor).r * l); //because it's black&white so take the r value  or anything else (blue, green), it doesn't matter
	float shW = (texture(tex, west_coor).r * l);
	float sh0 = (texture(tex, UV).r * l);
	
	float slopeN = abs(sh0 - shN);
	float slopeW = abs(sh0 - shW);
	float slope = (slopeN + slopeW) / 2.0; // average value
	
	COLOR = vec4(0.0, 0.0, 0.0, 1.0); //background
	
	if(terrainDisplay == 1) {
		COLOR = vec4(0.0, pow(slope + 1.0, 3.0) * 0.2, 0.0, 5.0 * pow(h, 5.0)); //here we want it green
	}
	
	if(terrainDisplay == 0) {
		if(h0 != hW || h0 != hN) {
			COLOR = vec4(0.0, 0.8, 0.0, 5.0 * pow(h, 5.0)); //here we want it green
		}
	}
}