module EchoFilter
(
input rst,
input AUDIO_CLK, 
input AUD_DACLRCK, 
input [31:0]currentADCData,
output reg [31:0]echoFilterOutput
);

// Declare variables for doing arithmetic
reg [31:0]lastAudioIn;

//use 32 bits so we can do arithmetic without losing information.
wire signed [31:0]leftAudio = {{16{currentADCData[31]}}, currentADCData[31:16]};
wire signed [31:0]leftLastInput = { {16{lastAudioIn[31]}}, lastAudioIn[31:16]};
reg signed [31:0]leftResult;

wire signed [31:0]rightAudio = {{16{currentADCData[15]}}, currentADCData[15:0]};
wire signed [31:0]rightLastInput = {{16{lastAudioIn[15]}}, lastAudioIn[15:0]};
reg signed [31:0]rightResult;

always @ (*)
begin
	leftResult = (($signed(32'd3) * $signed(leftLastInput)) / $signed(32'd4)) + $signed(leftAudio) ;
	rightResult = (($signed(32'd3) * $signed(rightLastInput)) / $signed(32'd4)) + $signed(rightAudio);
	
	echoFilterOutput[31:16] = leftResult[15:0];
	echoFilterOutput[15:0] =  rightResult[15:0];
end

always @ (posedge AUDIO_CLK or negedge rst)
begin	
	if(rst == 0)
		lastAudioIn <= 32'd0;
	else 
		if(AUD_DACLRCK == 1'b1)
			lastAudioIn <= currentADCData;
end

endmodule