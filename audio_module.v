module audio_module
(
	input [17:0]SW,
	input [3:0]KEY,
	input CLOCK_50,
	// Audio Codec signals
	output AUD_XCK,
	input AUD_BCLK,
	output AUD_DACDAT,
	input AUD_DACLRCK,
	input AUD_ADCDAT,
	input AUD_ADCLRCK,
	// I2C signals
	inout I2C_SDAT,
	output I2C_SCLK,
	output [0:6]HEX0,
	output [0:6]HEX1,
	output [0:6]HEX2
);

// Assign
assign AUD_XCK = AUDIO_CLK;
assign AUD_DACDAT = AUD_DACDATOUT;
reg rst;
always @(*)
	rst = KEY[0];

// Audio Clock instantation

wire AUDIO_CLK;
wire reset_source_reset;

Audio_CLK my_audio_clk(AUDIO_CLK, CLOCK_50, rst, reset_source_reset);

// Initialize Audio Chip
reg audio_init;
wire audio_init_done;
wire [3:0]audio_init_err;

reg send;
reg [6:0]register;
reg [8:0]data;
wire send_done;

Audio_Chip_Init aud_init(rst, CLOCK_50, audio_init, I2C_SDAT, I2C_SCLK, audio_init_done, 
	send, register, data, send_done, audio_init_err);
	
//ADC AND DAC
wire DACDone;
wire ADCDone;
wire [31:0]currentADCData;
reg [31:0]currentDACData;

wire AUD_DACDATOUT;

AudioDAC myDAC(
	rst, //reset
	AUD_BCLK, //Audio chip clock
	AUD_DACLRCK, //Will go high when ready for data.
	currentDACData, //The full data we want to send.
	DACDone, //Pulses high on done
	AUD_DACDATOUT //The data to send out on each pulse.
);

AudioADC myADC(
	rst, //reset
	AUD_BCLK, //Audio chip clock
	AUD_ADCLRCK, //Will go high when ready for data.
	AUD_ADCDAT, //The data to receive
	ADCDone, //Pulses high on done
	currentADCData //The full data we want to send.
);

// Finite State Machine
reg [3:0]S, NS;
parameter START = 4'd0, INIT = 4'd1, SEND = 4'd2, STANDBY = 4'd3, ERROR = 4'hF;

always @(posedge CLOCK_50 or negedge rst)
begin
	if(rst == 1'b0)
		S <= START;
	else
		S <= NS;
end

always @(*)
begin
	if(rst == 1'b0)
		NS = START;
	else
		case(S)
			START: NS = INIT;
			INIT:
			begin
				if(audio_init_done)
					NS = SEND;
				else
					NS = INIT;
			end
			SEND: NS = STANDBY;
			STANDBY:
			begin
				if(send_done)
					NS = SEND;
				else
					NS = STANDBY;
			end
			ERROR: NS = ERROR;
			default: NS = ERROR;
		endcase
end

always @(posedge CLOCK_50 or negedge rst)
begin
	if(rst == 1'b0)
	begin
		audio_init <= 1'b0;
		send <= 1'b0;
		register <= 7'd0;
		data <= 9'd0;
	end
	else
	begin
		case(S)
			START:
			begin
				audio_init <= 1'b0;
				send <= 1'b0;
				register <= 7'd0;
				data <= 9'd0;			
			end
			INIT: audio_init <= 1'b1;
			SEND:
			begin
				send <= 1'b1;
				register <= 7'b0000100;
				data <= 9'b0000_10_000; // The 4th bit from the right enables the bypass feature				
			end
			STANDBY:
			begin
				send <= 1'b0;
				register <= 7'd0;
				data <= 9'd0;
			end
		endcase
	end
end

// Initialize filter modules
wire [31:0]lowPassFilterOutput;
LowPassFilter lowpass(rst, AUD_BCLK, AUD_DACLRCK, currentADCData, lowPassFilterOutput);

wire [31:0]highPassFilterOutput;
HighPassFilter highpass(rst, AUD_BCLK, AUD_DACLRCK, currentADCData, highPassFilterOutput);

wire [31:0]echoFilterOutput;
EchoFilter echo(rst, AUD_BCLK, AUD_DACLRCK, currentADCData, echoFilterOutput);

//// Assign Switches to functions
//// Switch Variables
wire sw0_debounced, sw1_debounced, sw2_debounced;

// Debouncing
debouncer deb_sw0(CLOCK_50, rst, SW[0], sw0_debounced);
debouncer deb_sw1(CLOCK_50, rst, SW[1], sw1_debounced);
debouncer deb_sw2(CLOCK_50, rst, SW[2], sw2_debounced);

// Audio Effect Mixing
always @(*)
begin
	case({SW[2], SW[1], SW[0]})
	//case({sw3_debounced, sw2_debounced, sw1_debounced, sw0_debounced})
		3'b001: currentDACData = lowPassFilterOutput;// LOWPASS
		3'b010: currentDACData = highPassFilterOutput;// HIGHPASS
		3'b100: currentDACData = echoFilterOutput;// ECHO
		default: currentDACData = currentADCData;
	endcase
end

seven_segment true_selection({1'b0, SW[2], SW[1], SW[0]}, HEX2);
seven_segment selection({1'b0, sw2_debounced, sw1_debounced, sw0_debounced}, HEX1);
seven_segment error(audio_init_err, HEX0);

endmodule
