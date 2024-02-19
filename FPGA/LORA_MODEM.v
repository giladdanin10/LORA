
`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 12.09.2021 18:15:07
// Design Name: 
// Module Name: LORA_MODEM
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: a
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////




//`include "LoRaTXDefines.h"
`define CLOCK_COUNTER_PRECISION		17     // Transmit Packet Every Second
// `define CLOCK_COUNTER_PRECISION		23 // For Simulation
//Precision for all registers
`define PRECISION						    34
//Initial symbol precision
`define SYMBOL_PRECISION					16
//data precision
`define DATA_PRECISION						14
`define STATE_SIZE			                 5
`define CHIRP_TYPE_SIZE                      2

//Define different chirp type
`define TYPE_UPCHIRP		2'd0
`define TYPE_DOWNCHIRP   	2'd1
`define TYPE_Q_DOWNCHIRP 	2'd2
`define GAP_BETWEEN_PACKETS 27'd4000000
`define GAP_BETWEEN_PACKETS_RES 17'h10000

module LORA_MODEM(
input                               clk,
input                               clock_en,
input                               LoRa_ENABLE_REG,
// input [`SYMBOL_PRECISION-1:0] symbols [29:0],

input  wire  [9:0]                  lora_number_of_symbols_reg,
input  wire  [31:0]                 SYMBOL_LENGTH_FACTOR_REG,
input  wire  [31:0]                 SYMBOL_LENGTH_SUB1_REG,
input  wire  [31:0]                 SYMBOL_LENGTH_SUB2_REG,
input  wire  [31:0]                 DOWN_CHIRP_SYMBOL_SUB1_REG,
input  wire  [31:0]                 QDOWN_CHIRP_SYMBOL_SUB1_REG,
input  wire  signed [31:0]          LORA_BW_FACTOR_REG,
input  wire  signed [31:0]          LORA_FREQ_STEP_REG,
input  wire  signed [31:0]          LORA_2_POWER_SF_REG,

input  wire [9:0]                   PREAMBLE_LENGTH_REG,
input  wire [7:0]                   INTER_MESSAGE_DELAY_REG,

// LORA Symbol Memory Interface
output 	wire [9:0]		                  lora_memory_address,
input 	wire [`SYMBOL_PRECISION-1:0]	lora_memory_data_read,

// Output
output  reg                           loRa_Valid_Out,
output 	reg [15:0]		                Iout,
output 	reg [15:0]		                Qout


    );


 
//Counters
// reg [`DATA_PRECISION-1:0] preambleCounter;
// reg [`DATA_PRECISION-1:0] payloadCounter;
wire 	[15:0]		                cosOut;
wire 	[15:0]		                sinOut;
wire    [7:0] INTER_MESSAGE_DELAY_REG_shift;

assign INTER_MESSAGE_DELAY_REG_shift = {INTER_MESSAGE_DELAY_REG[5:0],2'b0};
reg signed [`SYMBOL_PRECISION-1:0] next_symVal = 0;
reg [`CHIRP_TYPE_SIZE-1:0]  next_symType = 0;

/*** States ***/
parameter [`STATE_SIZE-1:0] STATE_IDLE = `STATE_SIZE'd0, STATE_PREAMBLE = `STATE_SIZE'd1, STATE_SYNC_0 = `STATE_SIZE'd2, STATE_SYNC_1 = `STATE_SIZE'd3, 
                            STATE_DOWNCHIRP_0 = `STATE_SIZE'd4, STATE_DOWNCHIRP_1 = `STATE_SIZE'd5, STATE_QDOWNCHIRP = `STATE_SIZE'd6, STATE_PAYLOAD = `STATE_SIZE'd7,   
                            STATE_WAIT_BETWEEN_MESSAGES = `STATE_SIZE'd8; 


// typedef enum logic [`STATE_SIZE-1:0] {
//     STATE_IDLE = `STATE_SIZE'd0,
//     STATE_PREAMBLE = `STATE_SIZE'd1,
//     STATE_SYNC_0 = `STATE_SIZE'd2,
//     STATE_SYNC_1 = `STATE_SIZE'd3, 
//     STATE_DOWNCHIRP_0 = `STATE_SIZE'd4,
//     STATE_DOWNCHIRP_1 = `STATE_SIZE'd5,
//     STATE_QDOWNCHIRP = `STATE_SIZE'd6,
//     STATE_PAYLOAD = `STATE_SIZE'd7,   
//     STATE_WAIT_BETWEEN_MESSAGES = `STATE_SIZE'd8
// } StateType;

    // typedef enum logic [1:0] {
    //     IDLE = 2'b00,
    //     WORKING = 2'b01,
    //     DONE = 2'b10
    // } StateType;




// typedef enum logic [1:0] {
//     STATE_IDLE = 2'b00,
//     WORKING = 2'b01,
//     DONE = 2'b10
// } StateType;



reg [`STATE_SIZE-1:0] current_state = STATE_IDLE;

//TopModule Regs and Wires


//peamble, downchip and payload
// reg [`SYMBOL_PRECISION-1:0] preambleSym;
// reg [`SYMBOL_PRECISION-1:0] downSym;
// reg [`DATA_PRECISION-1:0]	payloadSize;
// reg [`DATA_PRECISION-1:0]	preambleSize;


reg [`SYMBOL_PRECISION-1:0] symbols [29:0];
reg loRa_Valid  = 0;
reg loRa_Valid_q1  = 0;
reg loRa_Valid_q2  = 0;
reg loRa_Valid_q3  = 0;
reg loRa_Valid_q4  = 0;

reg [9:0] symbol_count = 0;
reg [9:0] lora_memory_address_reg = 0;
reg [9:0] inter_message_delay_counter = 0;

reg [`CLOCK_COUNTER_PRECISION-1:0] count_clocks = 0;
reg [`CLOCK_COUNTER_PRECISION-1:0] count_clocks_between_messages = 0;
reg count_clocks_between_messages_en = 0;


reg [7:0] count_periods_between_messages = 0;


reg [31:0] symbol_length_count = 0;
reg Start_LoRa_Packet_Rising = 0;
reg symbol_start = 0;
reg symbol_start_q1 = 0;
reg symbol_start_q2 = 0;
reg symbol_start_q3 = 0;
reg signed [33:0] angleAccellerator = 0;
reg signed [33:0] LORA_BW_FACTOR = 0;
reg signed [33:0] LORA_FREQ_STEP = 0;
reg signed [33:0] LORA_2_POWER_SF = 0;

// reg signed [33:0] wideAngle = 0;
// reg signed [33:0] wideAngleAccumulator = 0;
reg  [33:0] wideAngle = 0;
reg  [33:0] wideAngleAccumulator = 0;
reg [11:0] Angle = 0;
reg [15:0] Angle16Bits = 0;
reg [15:0] Angle16BitsSigned = 0;

reg count_clocks_between_messages_en_Q1 = 0;
reg LoRa_ENABLE_REG_Q1 = 0;
reg LoRa_ENABLE_REG_Q2 = 0;
reg LoRa_ENABLE_REG_Q3 = 0;
reg LoRa_ENABLE_REG_Q4 = 0;
reg LoRa_ENABLE_REG_Q5 = 0;


wire [0:0] cordicValid;
wire [31:0] sinCosCordicOut;
wire [15:0] sinCordicOut16Bits;
wire [15:0] cosCordicOut16Bits;

/////   symbol selection

/////////////////////////////////////////////////
always @(posedge clk) begin

 if(clock_en == 1) begin

        LoRa_ENABLE_REG_Q1 <= LoRa_ENABLE_REG;
        LoRa_ENABLE_REG_Q2 <= LoRa_ENABLE_REG_Q1;
        LoRa_ENABLE_REG_Q3 <= LoRa_ENABLE_REG_Q2;
        LoRa_ENABLE_REG_Q4 <= LoRa_ENABLE_REG_Q3;
        LoRa_ENABLE_REG_Q5 <= LoRa_ENABLE_REG_Q4;
        


 end

end


////// State Machine ///////
always @(posedge clk) begin
    if (clock_en == 1) begin

        if (LoRa_ENABLE_REG_Q5 == 0) begin
                next_symType    = `TYPE_UPCHIRP;
                current_state      = STATE_IDLE;
                symbol_count    <= 0;
                lora_memory_address_reg <= 0;
                symbol_start    <= 0;
                symbol_length_count <= 0;
                loRa_Valid <= 0;


        end else begin


            case(current_state)

        
                STATE_IDLE: begin

                    next_symType    = `TYPE_UPCHIRP;
                    symbol_count = 0;
                    symbol_length_count <= 0;
                    lora_memory_address_reg <= 0;
                    count_clocks_between_messages_en <= 0;
                //  if(Start_LoRa_Packet_Rising == 1) begin
                    if (LoRa_ENABLE_REG==1) 
                    begin
                        current_state	<= STATE_PREAMBLE;
                        symbol_start    <= 1;
                        symbol_count    <= 0;
                        lora_memory_address_reg <= 0;
                        loRa_Valid     <= 1;
                    end
                 else begin
                    current_state		= STATE_IDLE;
                    symbol_start    <= 0;
                    symbol_count    <= 0;
                    lora_memory_address_reg <= 0;
                    loRa_Valid      <= 0;
                  end

            end

            /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
            /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
             STATE_PREAMBLE: begin
      
                  loRa_Valid     <= 1;
  
  
                   if (symbol_count == (PREAMBLE_LENGTH_REG-1) && symbol_length_count == ((2048*SYMBOL_LENGTH_FACTOR_REG)- SYMBOL_LENGTH_SUB1_REG)) begin   // If reach to end of last preamble
                      current_state        = STATE_SYNC_0;
                      symbol_start    <= 1;
                      symbol_count    <= 0;
//                      lora_memory_address_reg <= lora_memory_address_reg + 1;
                      next_symType    = `TYPE_UPCHIRP;
                      symbol_length_count <= 0;
  
  
                    end else begin
  
                      current_state        = current_state;
                      next_symType    <= next_symType;
  
                      /////////////////////////////////////////////////////////////////////////
                      if( symbol_length_count == ((2048*SYMBOL_LENGTH_FACTOR_REG) - SYMBOL_LENGTH_SUB1_REG)) begin
                          symbol_length_count <= 0;
                          symbol_start        <= 1;
                          symbol_count        <= symbol_count + 1;
                          lora_memory_address_reg <= 0;
                      
                      end
  
                      else begin
                          symbol_length_count <= symbol_length_count + 1 ;
                          symbol_start         <= 0;
                          symbol_count         <= symbol_count;
                          lora_memory_address_reg <= 0;
  
                      end
  
                                               
    
                      end
  
  
  
                  end
      
          
          
              /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
              /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
                  STATE_SYNC_0: begin
  
                  loRa_Valid     <= 1;
  
  
                    if (symbol_count == 1 && symbol_length_count == ((2048*SYMBOL_LENGTH_FACTOR_REG) - SYMBOL_LENGTH_SUB1_REG)) begin   // If reach to end of last sync ID
                      current_state        = STATE_DOWNCHIRP_0;
                      symbol_start    <= 1;
                      next_symType    = `TYPE_DOWNCHIRP;
                      symbol_count    <= 0;
//                      lora_memory_address_reg <= lora_memory_address_reg + 1;
                      symbol_length_count <= 0;
  
  
                    end else begin
  
                      current_state        = current_state;
                      next_symType    <= next_symType;
                      // next_symVal     <= next_symVal;
  
  
                      /////////////////////////////////////////////////////////////////////////
                      if( symbol_length_count == ((2048*SYMBOL_LENGTH_FACTOR_REG) - SYMBOL_LENGTH_SUB1_REG)) begin
                          symbol_length_count <= 0;
                          symbol_start        <= 1;
                          symbol_count        <= symbol_count + 1;
//                          lora_memory_address_reg <= lora_memory_address_reg + 1;
                      
                      end
  
                      else begin
                          symbol_length_count <= symbol_length_count + 1 ;
                          symbol_start         <= 0;
                          symbol_count         <= symbol_count;
                          lora_memory_address_reg <= lora_memory_address_reg;
  
                      end
  
  
                                               
    
                      end
  
  
  
  
                  end


            /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
            /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
                STATE_DOWNCHIRP_0: begin

                loRa_Valid     <= 1;

                  if (symbol_count == 1 && symbol_length_count == ((2048*SYMBOL_LENGTH_FACTOR_REG) - DOWN_CHIRP_SYMBOL_SUB1_REG)) begin   // If reach to end of last down chirp
                    current_state		= STATE_QDOWNCHIRP;
                    symbol_start    <= 1;
                    next_symType    = `TYPE_DOWNCHIRP;
                    symbol_count    <= 0;
//                    lora_memory_address_reg <= lora_memory_address_reg + 1;
                    symbol_length_count <= 0;


                  end else begin

                    current_state		= current_state;
                    next_symType    <= next_symType;
                    // next_symVal     <= next_symVal;


                    /////////////////////////////////////////////////////////////////////////
                    if( symbol_length_count == ((2048*SYMBOL_LENGTH_FACTOR_REG) - DOWN_CHIRP_SYMBOL_SUB1_REG)) begin
                        symbol_length_count <= 0;
                        symbol_start        <= 1;
                        symbol_count        <= symbol_count + 1;
//                        lora_memory_address_reg <= lora_memory_address_reg + 1;
                    
                    end

                    else begin
                        symbol_length_count <= symbol_length_count + 1 ;
                        symbol_start         <= 0;
                        symbol_count         <= symbol_count;
//                        lora_memory_address_reg <= lora_memory_address_reg;

                    end
                                             
  
                    end



                end




            /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
            /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
            
                STATE_QDOWNCHIRP: begin

                loRa_Valid     <= 1;


                  if (symbol_count == 0 && symbol_length_count == ((512*SYMBOL_LENGTH_FACTOR_REG) - QDOWN_CHIRP_SYMBOL_SUB1_REG)) begin   // If reach to end of quarter down chirp
                    current_state		= STATE_PAYLOAD;
                    symbol_start    <= 1;
                    next_symType    = `TYPE_UPCHIRP;
                    symbol_count    <= 0;
//                    lora_memory_address_reg <= lora_memory_address_reg + 1;
                    symbol_length_count <= 0;


                  end else begin

                    current_state		= current_state;
                    next_symType    <= next_symType;
                    // next_symVal     <= next_symVal;


                    /////////////////////////////////////////////////////////////////////////
                    if( symbol_length_count == ((512*SYMBOL_LENGTH_FACTOR_REG) - QDOWN_CHIRP_SYMBOL_SUB1_REG)) begin
                        symbol_length_count <= 0;
                        symbol_start        <= 1;
                        symbol_count        <= symbol_count + 1;
//                        lora_memory_address_reg <= lora_memory_address_reg + 1;
                    
                    end

                    else begin
                        symbol_length_count <= symbol_length_count + 1 ;
                        symbol_start         <= 0;
                        symbol_count         <= symbol_count;
//                        lora_memory_address_reg <= lora_memory_address_reg;

                    end
                                             
  
                    end




                end


            /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
            /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
                STATE_PAYLOAD: begin

                loRa_Valid     <= 1;


                 if (symbol_count == (lora_number_of_symbols_reg-1) && symbol_length_count == ((2048*SYMBOL_LENGTH_FACTOR_REG) - SYMBOL_LENGTH_SUB1_REG)) begin   // If reach to end of last payload 
                    current_state		= STATE_WAIT_BETWEEN_MESSAGES;
                    symbol_start    <= 0;
                    symbol_count    <= 0;
//                    lora_memory_address_reg <= lora_memory_address_reg + 1;
                    lora_memory_address_reg = 0;
                    next_symType    = `TYPE_UPCHIRP;
                    symbol_length_count <= 0;


                  end else begin

                    current_state		= current_state;
                    next_symType    <= next_symType;

                    /////////////////////////////////////////////////////////////////////////
                    if( symbol_length_count == ((2048*SYMBOL_LENGTH_FACTOR_REG) - SYMBOL_LENGTH_SUB1_REG)) begin
                        symbol_length_count <= 0;
                        symbol_start        <= 1;
                        symbol_count        <= symbol_count + 1;
                        lora_memory_address_reg <= lora_memory_address_reg + 1;
                    
                    end

                    else begin
                        symbol_length_count <= symbol_length_count + 1 ;
                        symbol_start         <= 0;
                        symbol_count         <= symbol_count;
                        lora_memory_address_reg <= lora_memory_address_reg;

                    end

                                             
  
                    end


                end
                     
               

            /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
            /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


                STATE_WAIT_BETWEEN_MESSAGES:
                begin
                    count_clocks_between_messages_en <= 1;
                    loRa_Valid     <= 0;
                    if (count_periods_between_messages == INTER_MESSAGE_DELAY_REG_shift)
                    begin
                        count_clocks_between_messages_en <= 0;
                        current_state      <= STATE_PREAMBLE;
                    end
                    else
                        count_clocks_between_messages_en <= 1;


                    
                end


                default: begin
                    next_symType    = `TYPE_UPCHIRP;
                    current_state      = STATE_IDLE;
                    symbol_count    <= 0;
                    lora_memory_address_reg <= 0;
                    symbol_start    <= 0;
                    symbol_length_count <= 0;
                    // next_symVal     = symbols[0];
                    loRa_Valid     <= 0;
                    count_clocks_between_messages_en <= 0;

                end


            endcase







        end
    end 

end


/////////////////////////////////////////////////

always @(posedge clk) begin

//  if(clock_en == 1) begin

//    if(symbol_start == 1)
//       next_symVal     = symbols[symbol_count];

//       else begin
//          next_symVal  <= next_symVal;
//       end


if(clock_en == 1) begin

   if(symbol_start_q2 == 1)
      next_symVal     = lora_memory_data_read;

      else begin
         next_symVal  <= next_symVal;
      end

 end

end


assign lora_memory_address = lora_memory_address_reg;


/////////////////////////////////////////////////
// always @(posedge clk) 
// begin

//  if(clock_en == 1)
//      begin
//         if (LoRa_ENABLE_REG==0)
//             count_clocks <= `GAP_BETWEEN_PACKETS-27'd1;

//         else if(count_clocks == `GAP_BETWEEN_PACKETS) 
//             count_clocks <= 0;

//         else
//             count_clocks <= count_clocks + `CLOCK_COUNTER_PRECISION'd1;


//     end
// end

always @(posedge clk) 
begin

 if(clock_en == 1)
     begin
        if (LoRa_ENABLE_REG==0)
            count_clocks_between_messages <= 0;

        
        else if (count_clocks_between_messages_en == 1)
            count_clocks_between_messages <= count_clocks_between_messages + `CLOCK_COUNTER_PRECISION'd1;

        else
            count_clocks_between_messages <= 0;
                        
    end
end


always @(posedge clk) 
begin
 if(clock_en == 1)
     begin
        if (LoRa_ENABLE_REG==0)
            count_periods_between_messages <= 0;

        
        else if ((count_clocks_between_messages_en_Q1 == 1) && (count_clocks_between_messages == 0))
            count_periods_between_messages <= count_periods_between_messages + 1;

        else if (count_clocks_between_messages_en_Q1 == 0)
            count_periods_between_messages <= 0;
                        
    end
end


always @(posedge clk)
begin
    count_clocks_between_messages_en_Q1 <= count_clocks_between_messages_en;
end


// alwaus @(posedge clk)
// begin
//     if (count_clocks_between_messages==)
// end



// always @(posedge clk)
// begin
//     if(clock_en == 1)
//     begin
//         if (count_clocks_between_messages_en)
//             count_clocks <= count_clocks+1;
//         else
//             count_clocks = 0;

//     end
// end
/*
always @(posedge clk) begin

 if(clock_en == 1) begin

        if(count_clocks == `GAP_BETWEEN_PACKETS) 
        begin

        if(inter_message_delay_counter == INTER_MESSAGE_DELAY_REG || LoRa_ENABLE_REG_Q5 == 0)
            inter_message_delay_counter <= 0;

           else
            inter_message_delay_counter <= inter_message_delay_counter + 1;

        end




        if(count_clocks == `GAP_BETWEEN_PACKETS && inter_message_delay_counter == INTER_MESSAGE_DELAY_REG) 
           Start_LoRa_Packet_Rising <= 1;

        else 
           Start_LoRa_Packet_Rising <= 0;



        //if(count_clocks == `CLOCK_COUNTER_PRECISION'd256) 
           //c <= 1;

        //else 
           //Start_LoRa_Packet_Rising <= 0;




 end

end
*/

/////////////////////////////////////////////////
always @(posedge clk) begin

 if(clock_en == 1) begin

        symbol_start_q1 <= symbol_start;
        symbol_start_q2 <= symbol_start_q1;
        symbol_start_q3 <= symbol_start_q2;


 end

end


/////////////////////////////////////////////////
always @(posedge clk) begin

 if(clock_en == 1) begin

        LORA_BW_FACTOR <= LORA_BW_FACTOR_REG;
        LORA_FREQ_STEP <= LORA_FREQ_STEP_REG;
        LORA_2_POWER_SF <= {2'd0, LORA_2_POWER_SF_REG};


 end

end




/////////////////////////////////////////////////
// Calculate Angle Accellerator
always @(posedge clk) begin

 if(clock_en == 1) begin

 if( loRa_Valid == 1) begin


        if(symbol_start_q3 == 1) begin

         if(next_symType    == `TYPE_UPCHIRP) begin
             angleAccellerator <= -1048576*LORA_BW_FACTOR + next_symVal * LORA_2_POWER_SF;  // Use Shift Left

         end
          
          else begin
              angleAccellerator <= 1048576*LORA_BW_FACTOR  - LORA_FREQ_STEP;
          end

        end


        else begin

         if(next_symType    == `TYPE_UPCHIRP) begin

         if((angleAccellerator  + LORA_FREQ_STEP) > (1048576*LORA_BW_FACTOR  - LORA_FREQ_STEP))
             angleAccellerator <= -1048576*LORA_BW_FACTOR ;

         else
              angleAccellerator <= angleAccellerator  + LORA_FREQ_STEP;

         end
          
          else begin

         if((angleAccellerator  - LORA_FREQ_STEP) < (-1048576*LORA_BW_FACTOR))
            angleAccellerator <= 1048576*LORA_BW_FACTOR  - LORA_FREQ_STEP;

         else
              angleAccellerator <= angleAccellerator  - LORA_FREQ_STEP;


          end

        end

    end
    


    else begin
        angleAccellerator <= 0;

    end
 end

end




/////////////////////////////////////////////////
// Calculate Angle  * 2^14  (16384)
always @(posedge clk) begin
 if(clock_en == 1) begin

   loRa_Valid_q1 <= loRa_Valid;
   loRa_Valid_q2 <= loRa_Valid_q1;
   loRa_Valid_q3 <= loRa_Valid_q2;
   loRa_Valid_q4 <= loRa_Valid_q3;
   loRa_Valid_Out <= loRa_Valid_q4;

 end
 else begin

   loRa_Valid_q1 <= loRa_Valid_q1;
   loRa_Valid_q2 <= loRa_Valid_q2;
   loRa_Valid_q3 <= loRa_Valid_q3;
   loRa_Valid_q4 <= loRa_Valid_q4;
   loRa_Valid_Out <= loRa_Valid_Out;

 end

end



/////////////////////////////////////////////////
// Calculate Angle  * 2^14  (16384)
always @(posedge clk) begin
 if(clock_en == 1) begin

 if( loRa_Valid_q1 == 1) begin
  
    // wideAngleAccumulator = $signed(wideAngle) + $signed(angleAccellerator/32);
    wideAngleAccumulator = $signed(wideAngle) + $signed({angleAccellerator[33], angleAccellerator[33], angleAccellerator[33], angleAccellerator[33], angleAccellerator[33], angleAccellerator[33], angleAccellerator[27:5]});
    wideAngle <= wideAngleAccumulator;
/*
//    if ($signed(wideAngleAccumulator) < 0) begin
    if ((wideAngleAccumulator) < 0) begin
        wideAngle = $signed(wideAngle) + $signed(`SCALE_2X);
    end

    if ($signed(wideAngleAccumulator) >= $signed(`SCALE_2X)) begin
        wideAngle = $signed(wideAngle) - $signed(`SCALE_2X);
    end		
    else begin
         wideAngle <= wideAngleAccumulator;
    end
*/


 end

 else begin
     wideAngle <= 0;
     wideAngleAccumulator <= 0;
 end

 end

end


/////////////////////////////////////////////////
// Calculate Angle  * 2^12  (4096) Look Up Table Entries
always @(posedge clk) begin
 if(clock_en == 1) begin

	Angle = wideAngle >> (25-11);  // Divide By 16384
  Angle16Bits <= wideAngle >> (25-15);  // Divide By 16384
//  Angle16BitsSigned <= {~Angle16Bits[15],~Angle16Bits[15],~Angle16Bits[15], Angle16Bits[14:2]};
  Angle16BitsSigned <= {Angle16Bits[15],Angle16Bits[15],Angle16Bits[15], Angle16Bits[14:2]};
  end
end


/////////////////////////////////////////////////
// I/Q Output mask
always @(posedge clk) begin
 if(clock_en == 1) begin

if(loRa_Valid_q4 == 1)
     begin
     	// Iout <= cosOut;  
      //   Qout <= sinOut;  

      Iout  <= sinCosCordicOut[15:0];
      Qout  <= sinCosCordicOut[31:16];


      end
       else begin

     	Iout <= 0;  
     	Qout <= 0;  
      end

  end
end



/////////////////////////////////////////////////
// Calculate Cos(Angle)


// cosTable1 cosTable02
//   (
//     .clka(clk),    //: IN STD_LOGIC;
//     .ena(clock_en),    //: IN STD_LOGIC;
//     .wea(0),    //: IN STD_LOGIC_VECTOR(0 DOWNTO 0);
//     .addra(Angle),   //:   IN STD_LOGIC_VECTOR(11 DOWNTO 0);
//     .dina(0),    //: IN STD_LOGIC_VECTOR(15 DOWNTO 0);
//     .douta(cosOut)    //: OUT STD_LOGIC_VECTOR(sinCordicOut16Bits

/////////////////////////////////////////////////
// Calculate Sin(Angle)


// sinTable1 sinTable02
//   (
//     .clka(clk),    //: IN STD_LOGIC;
//     .ena(clock_en),    //: IN STD_LOGIC;
//     .wea(0),    //: IN STD_LOGIC_VECTOR(0 DOWNTO 0);
//     .addra(Angle),   //:   IN STD_LOGIC_VECTOR(11 DOWNTO 0);
//     .dina(0),    //: IN STD_LOGIC_VECTOR(15 DOWNTO 0);
//     .douta(sinOut)    //: OUT STD_LOGIC_VECTOR(15 DOWNTO 0)
//   );



sinCosCordic sinCosCordicInst (
    .aclk(clk),
    .s_axis_phase_tvalid(1),
    .s_axis_phase_tdata(Angle16BitsSigned),
    .m_axis_dout_tvalid(cordicValid),
    .m_axis_dout_tdata(sinCosCordicOut)
    );

/////////////////////////////////////////////////
// Calculate Cos(Angle)




/////////////////////////////////////////////////
// Calculate Sin(Angle)




// assign sinCordicOut16Bits = sinCosCordicOut[31:16];
// assign cosCordicOut16Bits = sinCosCordicOut[15:0];

endmodule
