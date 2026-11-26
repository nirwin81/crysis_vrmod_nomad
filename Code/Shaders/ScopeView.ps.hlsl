// Draws the magnified scope image onto the scope's eyepiece, with a simple reticle.
// Used with FullScreenTri.vs.hlsl and a viewport covering the eyepiece's on-screen bounding box.
// The eyepiece is a disc seen at an angle, i.e. an ellipse on screen; discFromViewport maps viewport
// coordinates (0..1) to coordinates on the disc (-1..1, y down), so the image sticks to the eyepiece.
// The image can sit deeper inside the scope tube than its rear opening: the opening limits what is visible
// (as the tube's rim would), the image disc decides what is shown there.
Texture2D scopeTex;
SamplerState scopeSampler;

cbuffer ScopeParams : register(b0)
{
	float4 discFromViewportX;  // opening: p.x = dot(xy, texcoord) + z
	float4 discFromViewportY;  // opening: p.y = dot(xy, texcoord) + z
	float4 imageFromViewportX; // image disc: p.x = dot(xy, texcoord) + z
	float4 imageFromViewportY; // image disc: p.y = dot(xy, texcoord) + z
};

float4 main(in float4 position : SV_POSITION, in float2 texcoord : TEXCOORD0) : SV_TARGET
{
	float2 q = float2(dot(discFromViewportX.xy, texcoord) + discFromViewportX.z,
	                  dot(discFromViewportY.xy, texcoord) + discFromViewportY.z);
	float rOpening = length(q);
	if (rOpening > 1.0)
		discard;

	float2 p = float2(dot(imageFromViewportX.xy, texcoord) + imageFromViewportX.z,
	                  dot(imageFromViewportY.xy, texcoord) + imageFromViewportY.z);
	float r = length(p);

	// outside the image disc but inside the opening: the dark inside of the tube
	float3 color = float3(0, 0, 0);
	if (r <= 1.0)
	{
		color = scopeTex.Sample(scopeSampler, p * 0.5 + 0.5).rgb;

		// darken towards the rim like a real eyepiece
		color *= 1.0 - smoothstep(0.82, 1.0, r);

		// reticle: thin crosshair in the middle, thicker posts towards the edge
		float2 a = abs(p);
		bool thinLine = a.x < 0.006 || a.y < 0.006;
		bool post = (a.x < 0.025 && a.y > 0.45) || (a.y < 0.025 && a.x > 0.45);
		if (thinLine || post)
			color = float3(0, 0, 0);
	}

	// a little shading where the tube's rim cuts the view off
	color *= 1.0 - 0.5 * smoothstep(0.9, 1.0, rOpening);

	return float4(color, 1.0);
}
