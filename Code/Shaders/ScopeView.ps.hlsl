// Draws the magnified scope image as a round eyepiece with a simple reticle.
// Used with FullScreenTri.vs.hlsl and a viewport covering the scope circle's bounding square.
Texture2D scopeTex;
SamplerState scopeSampler;

float4 main(in float4 position : SV_POSITION, in float2 texcoord : TEXCOORD0) : SV_TARGET
{
	// -1..1 across the scope circle
	float2 p = texcoord * 2.0 - 1.0;
	float r = length(p);
	if (r > 1.0)
		discard;

	float3 color = scopeTex.Sample(scopeSampler, texcoord).rgb;

	// darken towards the rim like a real eyepiece
	color *= 1.0 - smoothstep(0.82, 1.0, r);

	// reticle: thin crosshair in the middle, thicker posts towards the edge
	float2 a = abs(p);
	bool thinLine = a.x < 0.004 || a.y < 0.004;
	bool post = (a.x < 0.02 && a.y > 0.45) || (a.y < 0.02 && a.x > 0.45);
	if (thinLine || post)
		color = float3(0, 0, 0);

	return float4(color, 1.0);
}
