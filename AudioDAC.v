module AudioDAC
(
input rst,
input AUD_BCLK, //Audio chip clock
input AUD_DACLRCK, // Will go high when ready for data.
input [31:0]digital_signal_in,

output reg done,
output reg AUD_DACDAT //This output gets read by the DAC every pulse of the audio clock.
);

parameter START = 3'd0, SEND = 3'd1, DONE = 3'd2, ERROR = 3'd3;

reg [2:0]S, NS;

// Bits left to send and temp data for reading them in
reg [4:0]bits_left;
reg [31:0]temp_data;

always @(posedge AUD_BCLK or negedge rst)
begin
	if(rst == 1'b0)
		S <= START;
	else
		S <= NS;
end

always @ (posedge AUD_BCLK or negedge rst)
begin
	if(rst == 0)
		begin
			done <= 1'b0;
			bits_left <= 5'd31;
			temp_data <= 32'd0;
		end
	else
		case(S)
			START:
			begin
				done <= 1'b0;
				bits_left <= 5'd31;
				temp_data <= digital_signal_in;
			end
			SEND: bits_left <= bits_left - 5'd1;
			DONE:
			begin
				done <= 1'b1;				
				bits_left <= 5'd31;
			end
		endcase
end


always @ (*)
begin
	AUD_DACDAT = temp_data[bits_left];

	case (S)
		START:
		begin
			if(AUD_DACLRCK == 1)
				NS = SEND;
			else
				NS = START;	
		end
		SEND:
		begin
			if(bits_left == 5'd0)
				NS = DONE;
			else
				NS = SEND;
		end
		DONE: NS = START;
		ERROR: NS = ERROR;
		default: NS = ERROR;
	endcase
end

endmodule
