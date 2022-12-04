module LowPassFilter
(
input rst,
input AUDIO_CLK, 
input AUD_DACLRCK, 
input [31:0]currentADCData,
output reg [31:0]lowPassFilterOutput
);

// Declare variables for doing arithmetic
reg [31:0]lastAudioIn;
reg [31:0]lastOutput;
initial lastOutput = 32'd0;

//use 32 bits so we can do arithmetic without losing information.
wire signed [31:0]leftAudio = {{16{currentADCData[31]}}, currentADCData[31:16]};
wire signed [31:0]leftLastOutput = {{16{lastOutput[31]}}, lastOutput[31:16]};
reg signed [31:0]leftResult;

wire signed [31:0]rightAudio = { {16{currentADCData[15]}}, currentADCData[15:0]};
wire signed [31:0]rightLastOutput = {{16{lastOutput[15]}}, lastOutput[15:0]};
reg signed [31:0]rightResult;

always @ (*)
begin
	// y[i] = a * x[i] + (1-a) * y[i-1]
	// a = dt / (RC + dt) = 8e-8 / (6.25e-7 + 8e-8) = .113 = 16/141
	// dt = 1/12.5MHz = 8e-8   RC = 12.5Kohms * 50pF = 6.25e-7
	leftResult = (($signed(32'd16) * $signed(leftAudio)) / $signed(32'd141)) + (($signed(32'd125) * $signed(leftLastOutput)) / $signed(32'd141));
	rightResult = (($signed(32'd16) * $signed(rightAudio)) / $signed(32'd141)) + (($signed(32'd125) * $signed(rightLastOutput)) / $signed(32'd141));
	
	lowPassFilterOutput[31:16] = leftResult[15:0];
	lowPassFilterOutput[15:0] =  rightResult[15:0];
end

always @ (posedge AUDIO_CLK or negedge rst)
begin	
	if(rst == 0)
		lastOutput <= 32'd0;
	else 
		if(AUD_DACLRCK == 1'b1)
			lastOutput <= lowPassFilterOutput;
end

endmodule