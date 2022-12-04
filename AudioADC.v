module AudioADC
(
input rst, //reset
input AUD_BCLK, //Audio chip clock
input AUD_ADCLRCK, // Wait for it to go high
input AUD_ADCDAT, // ADC Data

output reg done,
output reg [31:0]digital_signal_out
);

parameter START = 3'd0, RECIEVE = 3'd1, DONE = 3'd2, ERROR = 3'd3;

reg [2:0]S, NS;

//The current bit we're receiving
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
		digital_signal_out <= 31'd0;
	end
	else		
		case(S)
			START: 
			begin
				done <= 1'b0;
				bits_left <= 5'd31;
				digital_signal_out <= 31'd0;
			end
			RECIEVE:
			begin
				bits_left <= bits_left - 5'd1;
				temp_data[bits_left] <= AUD_ADCDAT;
			end	
			DONE:
			begin
				done <= 1'b1;
				bits_left <= 5'd31;			
				digital_signal_out <= temp_data;
			end	
		endcase
end

always @ (*)
begin
	case (S)
		START:
		begin
			if(AUD_ADCLRCK == 1'd1)
				NS = RECIEVE;
			else
				NS = START;
		end
		RECIEVE:
		begin
			if(bits_left == 5'd0)
				NS = DONE;
			else
				NS = RECIEVE;
		end
		DONE: NS = START;
		ERROR: NS = ERROR;
		default: NS = ERROR;
	endcase
end

endmodule
