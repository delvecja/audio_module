module HighPassFilter
(
input rst,
input AUDIO_CLK, 
input AUD_DACLRCK,  
input [31:0]currentADCData,
output reg [31:0]highPassFilterOutput
);

// Declare variables for doing arithmetic
reg [31:0]lastAudioIn;
reg [31:0]lastOutput;

//use 32 bits so we can do arithmetic without losing information.
wire signed [31:0]leftAudio = {{16{currentADCData[31]}}, currentADCData[31:16]};
wire signed [31:0]leftLastOutput = {{16{lastOutput[31]}}, lastOutput[31:16]};
wire signed [31:0]leftLastInput = { {16{lastAudioIn[31]}}, lastAudioIn[31:16]};
reg signed [31:0]leftResult;

wire signed [31:0]rightAudio = {{16{currentADCData[15]}}, currentADCData[15:0]};
wire signed [31:0]rightLastOutput = {{16{lastOutput[15]}}, lastOutput[15:0]};
wire signed [31:0]rightLastInput = {{16{lastAudioIn[15]}}, lastAudioIn[15:0]};
reg signed [31:0]rightResult;

always @ (*)
begin
	// y[i] = a * y[i-1] + a * (x[i] - x[i-1])
	// a = dt / (RC + dt) = 8e-8 / (6.25e-7 + 8e-8) = .113 = 16/141
	// dt = 1/12.5MHz = 8e-8   RC = 12.5Kohms * 50pF = 6.25e-7
	leftResult = (($signed(32'd16) * ($signed(leftLastOutput) + $signed(leftAudio) - $signed(leftLastInput))) / $signed(32'd141));
	rightResult = (($signed(32'd16) * ($signed(rightLastOutput) + $signed(rightAudio) - $signed(rightLastInput))) / $signed(32'd141));

	
	highPassFilterOutput[31:16] = leftResult[15:0];
	highPassFilterOutput[15:0] =  rightResult[15:0];
end

always @ (posedge AUDIO_CLK or negedge rst)
begin	
	if(rst == 0)
		lastOutput <= 32'd0;
	else 
		if(AUD_DACLRCK == 1'b1)
		begin
			lastOutput <= highPassFilterOutput;
			lastAudioIn <= currentADCData;
		end
end
endmodule