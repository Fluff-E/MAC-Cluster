/* my_aes128_ip_coprocesor.v; AES 128 encryption coprocessor   
Developed by Radu Muresan, March 2022

This AES implementation is an asynchronous, combinational implementation
The module implements the encryption algorithm and the key expansion algorithm
The ciphertext result is generated after the propagation delay through the AES rounds
The AES coprocessor was tested with the NIST example found in AES_NIST.FIPS.197.pdf
Plaintext input:   32 43 f6 a8 88 5a 30 8d 31 31 98 a2 e0 37 07 34
Cipher Key:        2b 7e 15 16 28 ae d2 a6 ab f7 15 88 09 cf 4f 3c
Ciphertext result: 39 25 84 1d 02 dc 09 fb dc 11 85 97 19 6a 0b 32
The ciphertext result was correctly generated and verified!

Implementation Notes!
The AES-128 cipher algorithm follows the pseudo-code of Figure 5 (pp. 15) presented in
AES_NIST.FIPS.197.pdf document. The implementation was developed by following
the Appendix B example round by round and state by state.
For the AES-128 algorithm, we have the length of the input block, output block, and
the state as 128-bits, and Nb = 4, Nk = 4, and Nr = 10 (See Figure 4, pp. 13).
*/

module my_aes128_coprocessor ( input wire [127:0] ptext,
					input wire [127:0] key,
					output wire [127:0] ctext_aes
					);

//organize the initial state; see Figure 3 of AES_NIST.FIPS.197.pdf document					
wire [7:0] B0; wire [7:0] B1; wire [7:0] B2; wire [7:0] B3;
wire [7:0] B4; wire [7:0] B5; wire [7:0] B6; wire [7:0] B7;
wire [7:0] B8; wire [7:0] B9; wire [7:0] B10; wire [7:0] B11;
wire [7:0] B12; wire [7:0] B13; wire [7:0] B14; wire [7:0] B15;
wire [31:0] key00; wire [31:0] key01; wire [31:0] key02; wire [31:0] key03;
wire [31:0] ctext0; wire [31:0] ctext1; wire [31:0] ctext2; wire [31:0] ctext3;	

//organize the input and output signals
assign B0 = ptext [127:120];
assign B1 = ptext [119:112];
assign B2 = ptext [111:104];
assign B3 = ptext [103:96];
assign B4 = ptext [95:88];
assign B5 = ptext [87:80];
assign B6 = ptext [79:72];
assign B7 = ptext [71:64];
assign B8 = ptext [63:56];
assign B9 = ptext [55:48];
assign B10 = ptext [47:40];
assign B11 = ptext [39:32];
assign B12 = ptext [31:24];
assign B13 = ptext [23:16];
assign B14 = ptext [15:8];
assign B15 = ptext [7:0];
assign key00 = key [127:96];
assign key01 = key [95:64];
assign key02 = key [63:32];
assign key03 = key [31:0];
assign ctext_aes [127:96] = ctext0;
assign ctext_aes [95:64] = ctext1;
assign ctext_aes [63:32] = ctext2;
assign ctext_aes [31:0] = ctext3;

//round keys generation section generates the 10 round keys for rounds 1 to 10
//the keyschedule algorithm for each round key follows the
//pseudocode for Key Expanaion from Figure 11 of AES_NIST.FIPS.197.pdf document
wire [31:0] key10; wire [31:0] key11;
wire [31:0] key12; wire [31:0] key13;
wire [7:0] ri1;
assign ri1 = 8'b00000001; // constant ri for round 1
keyschedule1 R1_key(
			ri1,
			key00, key01, key02, key03,
			key10, key11, key12, key13
			);
wire [31:0] key20; wire [31:0] key21;
wire [31:0] key22; wire [31:0] key23;
wire [7:0] ri2;
assign ri2 = 8'b00000010; // constant ri for round 2
keyschedule1 R2_key(
			ri2,
			key10, key11, key12, key13,
			key20, key21, key22, key23
			);
wire [31:0] key30; wire [31:0] key31;
wire [31:0] key32; wire [31:0] key33;
wire [7:0] ri3;
assign ri3 = 8'b00000100; // constant ri for round 3
keyschedule1 R3_key(
			ri3,
			key20, key21, key22, key23,
			key30, key31, key32, key33
			);
wire [31:0] key40; wire [31:0] key41;
wire [31:0] key42; wire [31:0] key43;
wire [7:0] ri4;
assign ri4 = 8'b00001000; // constant ri for round 4
keyschedule1 R4_key(
			ri4,
			key30, key31, key32, key33,
			key40, key41, key42, key43
			);
wire [31:0] key50; wire [31:0] key51;
wire [31:0] key52; wire [31:0] key53;
wire [7:0] ri5;
assign ri5 = 8'b00010000; // constant ri for round 5
keyschedule1 R5_key(
			ri5,
			key40, key41, key42, key43,
			key50, key51, key52, key53
			);
wire [31:0] key60; wire [31:0] key61;
wire [31:0] key62; wire [31:0] key63;
wire [7:0] ri6;
assign ri6 = 8'b00100000; // constant ri for round 6
keyschedule1 R6_key(
			ri6,
			key50, key51, key52, key53,
			key60, key61, key62, key63
			);
wire [31:0] key70; wire [31:0] key71;
wire [31:0] key72; wire [31:0] key73;
wire [7:0] ri7;
assign ri7 = 8'b01000000; // constant ri for round 7
keyschedule1 R7_key(
			ri7,
			key60, key61, key62, key63,
			key70, key71, key72, key73
			);			
wire [31:0] key80; wire [31:0] key81;
wire [31:0] key82; wire [31:0] key83;
wire [7:0] ri8;
assign ri8 = 8'b10000000; // constant ri for round 8
keyschedule1 R8_key(
			ri8,
			key70, key71, key72, key73,
			key80, key81, key82, key83
			);			
wire [31:0] key90; wire [31:0] key91;
wire [31:0] key92; wire [31:0] key93;
wire [7:0] ri9;
assign ri9 = 8'b00011011; // constant ri for round 9
keyschedule1 R9_key(
			ri9,
			key80, key81, key82, key83,
			key90, key91, key92, key93
			);			
wire [31:0] key100; wire [31:0] key101;
wire [31:0] key102; wire [31:0] key103;
wire [7:0] ri10;
assign ri10 = 8'b00110110; // constant ri for round 10
keyschedule1 R10_key(
			ri10,
			key90, key91, key92, key93,
			key100, key101, key102, key103
			);	
			
//AES-128 has one whitening round (round 0) plus 9 regular rounds (rounds 1 to 9)
//and a final round (round 10)
 
//transfer the ptext to R0 - whitening round

wire [7:0] r0_w0; wire [7:0] r0_w1; wire [7:0] r0_w2; wire [7:0] r0_w3;
wire [7:0] r0_w4; wire [7:0] r0_w5; wire [7:0] r0_w6; wire [7:0] r0_w7; 
wire [7:0] r0_w8; wire [7:0] r0_w9; wire [7:0] r0_w10; wire [7:0] r0_w11;
wire [7:0] r0_w12; wire [7:0] r0_w13; wire [7:0] r0_w14; wire [7:0] r0_w15;

//perform the round 0 which is just the AddRoundKey

AddRoundKey R1_start (key00[31:24], key00[23:16], key00[15:8], key00[7:0],
					key01[31:24], key01[23:16], key01[15:8], key01[7:0],
					key02[31:24], key02[23:16], key02[15:8], key02[7:0],
					key03[31:24], key03[23:16], key03[15:8], key03[7:0],
					B0, B1, B2, B3, B4, B5, B6, B7,
					B8, B9, B10, B11, B12, B13, B14, B15,
					r0_w0, r0_w1, r0_w2, r0_w3, r0_w4, r0_w5, r0_w6, r0_w7,
					r0_w8, r0_w9, r0_w10, r0_w11, r0_w12, r0_w13, r0_w14, r0_w15
					);
					
//next is round 1
wire [7:0] r1_w0; wire [7:0] r1_w1; wire [7:0] r1_w2; wire [7:0] r1_w3;
wire [7:0] r1_w4; wire [7:0] r1_w5; wire [7:0] r1_w6; wire [7:0] r1_w7; 
wire [7:0] r1_w8; wire [7:0] r1_w9; wire [7:0] r1_w10; wire [7:0] r1_w11;
wire [7:0] r1_w12; wire [7:0] r1_w13; wire [7:0] r1_w14; wire [7:0] r1_w15;

Round_i Round_1 (r0_w0, r0_w1, r0_w2, r0_w3, r0_w4, r0_w5, r0_w6, r0_w7,
					r0_w8, r0_w9, r0_w10, r0_w11, r0_w12, r0_w13, r0_w14, r0_w15,
					key10, key11, key12, key13,
					r1_w0, r1_w1, r1_w2, r1_w3, r1_w4, r1_w5, r1_w6, r1_w7,
					r1_w8, r1_w9, r1_w10, r1_w11, r1_w12, r1_w13, r1_w14, r1_w15
					);
//next is round 2
wire [7:0] r2_w0; wire [7:0] r2_w1; wire [7:0] r2_w2; wire [7:0] r2_w3;
wire [7:0] r2_w4; wire [7:0] r2_w5; wire [7:0] r2_w6; wire [7:0] r2_w7; 
wire [7:0] r2_w8; wire [7:0] r2_w9; wire [7:0] r2_w10; wire [7:0] r2_w11;
wire [7:0] r2_w12; wire [7:0] r2_w13; wire [7:0] r2_w14; wire [7:0] r2_w15;

Round_i Round_2 (r1_w0, r1_w1, r1_w2, r1_w3, r1_w4, r1_w5, r1_w6, r1_w7,
					r1_w8, r1_w9, r1_w10, r1_w11, r1_w12, r1_w13, r1_w14, r1_w15,
					key20, key21, key22, key23,
					r2_w0, r2_w1, r2_w2, r2_w3, r2_w4, r2_w5, r2_w6, r2_w7,
					r2_w8, r2_w9, r2_w10, r2_w11, r2_w12, r2_w13, r2_w14, r2_w15
					);

//next is round 3
wire [7:0] r3_w0; wire [7:0] r3_w1; wire [7:0] r3_w2; wire [7:0] r3_w3;
wire [7:0] r3_w4; wire [7:0] r3_w5; wire [7:0] r3_w6; wire [7:0] r3_w7; 
wire [7:0] r3_w8; wire [7:0] r3_w9; wire [7:0] r3_w10; wire [7:0] r3_w11;
wire [7:0] r3_w12; wire [7:0] r3_w13; wire [7:0] r3_w14; wire [7:0] r3_w15;

Round_i Round_3 (r2_w0, r2_w1, r2_w2, r2_w3, r2_w4, r2_w5, r2_w6, r2_w7,
					r2_w8, r2_w9, r2_w10, r2_w11, r2_w12, r2_w13, r2_w14, r2_w15,
					key30, key31, key32, key33,
					r3_w0, r3_w1, r3_w2, r3_w3, r3_w4, r3_w5, r3_w6, r3_w7,
					r3_w8, r3_w9, r3_w10, r3_w11, r3_w12, r3_w13, r3_w14, r3_w15
					);
//next is round 4
wire [7:0] r4_w0; wire [7:0] r4_w1; wire [7:0] r4_w2; wire [7:0] r4_w3;
wire [7:0] r4_w4; wire [7:0] r4_w5; wire [7:0] r4_w6; wire [7:0] r4_w7; 
wire [7:0] r4_w8; wire [7:0] r4_w9; wire [7:0] r4_w10; wire [7:0] r4_w11;
wire [7:0] r4_w12; wire [7:0] r4_w13; wire [7:0] r4_w14; wire [7:0] r4_w15;

Round_i Round_4 (r3_w0, r3_w1, r3_w2, r3_w3, r3_w4, r3_w5, r3_w6, r3_w7,
					r3_w8, r3_w9, r3_w10, r3_w11, r3_w12, r3_w13, r3_w14, r3_w15,
					key40, key41, key42, key43,
					r4_w0, r4_w1, r4_w2, r4_w3, r4_w4, r4_w5, r4_w6, r4_w7,
					r4_w8, r4_w9, r4_w10, r4_w11, r4_w12, r4_w13, r4_w14, r4_w15
					);
//next is round 5
wire [7:0] r5_w0; wire [7:0] r5_w1; wire [7:0] r5_w2; wire [7:0] r5_w3;
wire [7:0] r5_w4; wire [7:0] r5_w5; wire [7:0] r5_w6; wire [7:0] r5_w7; 
wire [7:0] r5_w8; wire [7:0] r5_w9; wire [7:0] r5_w10; wire [7:0] r5_w11;
wire [7:0] r5_w12; wire [7:0] r5_w13; wire [7:0] r5_w14; wire [7:0] r5_w15;

Round_i Round_5 (r4_w0, r4_w1, r4_w2, r4_w3, r4_w4, r4_w5, r4_w6, r4_w7,
					r4_w8, r4_w9, r4_w10, r4_w11, r4_w12, r4_w13, r4_w14, r4_w15,
					key50, key51, key52, key53,
					r5_w0, r5_w1, r5_w2, r5_w3, r5_w4, r5_w5, r5_w6, r5_w7,
					r5_w8, r5_w9, r5_w10, r5_w11, r5_w12, r5_w13, r5_w14, r5_w15
					);					
//next is round 6
wire [7:0] r6_w0; wire [7:0] r6_w1; wire [7:0] r6_w2; wire [7:0] r6_w3;
wire [7:0] r6_w4; wire [7:0] r6_w5; wire [7:0] r6_w6; wire [7:0] r6_w7; 
wire [7:0] r6_w8; wire [7:0] r6_w9; wire [7:0] r6_w10; wire [7:0] r6_w11;
wire [7:0] r6_w12; wire [7:0] r6_w13; wire [7:0] r6_w14; wire [7:0] r6_w15;

Round_i Round_6 (r5_w0, r5_w1, r5_w2, r5_w3, r5_w4, r5_w5, r5_w6, r5_w7,
					r5_w8, r5_w9, r5_w10, r5_w11, r5_w12, r5_w13, r5_w14, r5_w15,
					key60, key61, key62, key63,
					r6_w0, r6_w1, r6_w2, r6_w3, r6_w4, r6_w5, r6_w6, r6_w7,
					r6_w8, r6_w9, r6_w10, r6_w11, r6_w12, r6_w13, r6_w14, r6_w15
					);	
//next is round 7
wire [7:0] r7_w0; wire [7:0] r7_w1; wire [7:0] r7_w2; wire [7:0] r7_w3;
wire [7:0] r7_w4; wire [7:0] r7_w5; wire [7:0] r7_w6; wire [7:0] r7_w7; 
wire [7:0] r7_w8; wire [7:0] r7_w9; wire [7:0] r7_w10; wire [7:0] r7_w11;
wire [7:0] r7_w12; wire [7:0] r7_w13; wire [7:0] r7_w14; wire [7:0] r7_w15;

Round_i Round_7 (r6_w0, r6_w1, r6_w2, r6_w3, r6_w4, r6_w5, r6_w6, r6_w7,
					r6_w8, r6_w9, r6_w10, r6_w11, r6_w12, r6_w13, r6_w14, r6_w15,
					key70, key71, key72, key73,
					r7_w0, r7_w1, r7_w2, r7_w3, r7_w4, r7_w5, r7_w6, r7_w7,
					r7_w8, r7_w9, r7_w10, r7_w11, r7_w12, r7_w13, r7_w14, r7_w15
					);	
//next is round 8
wire [7:0] r8_w0; wire [7:0] r8_w1; wire [7:0] r8_w2; wire [7:0] r8_w3;
wire [7:0] r8_w4; wire [7:0] r8_w5; wire [7:0] r8_w6; wire [7:0] r8_w7; 
wire [7:0] r8_w8; wire [7:0] r8_w9; wire [7:0] r8_w10; wire [7:0] r8_w11;
wire [7:0] r8_w12; wire [7:0] r8_w13; wire [7:0] r8_w14; wire [7:0] r8_w15;

Round_i Round_8 (r7_w0, r7_w1, r7_w2, r7_w3, r7_w4, r7_w5, r7_w6, r7_w7,
					r7_w8, r7_w9, r7_w10, r7_w11, r7_w12, r7_w13, r7_w14, r7_w15,
					key80, key81, key82, key83,
					r8_w0, r8_w1, r8_w2, r8_w3, r8_w4, r8_w5, r8_w6, r8_w7,
					r8_w8, r8_w9, r8_w10, r8_w11, r8_w12, r8_w13, r8_w14, r8_w15
					);	
//next is round 9
wire [7:0] r9_w0; wire [7:0] r9_w1; wire [7:0] r9_w2; wire [7:0] r9_w3;
wire [7:0] r9_w4; wire [7:0] r9_w5; wire [7:0] r9_w6; wire [7:0] r9_w7; 
wire [7:0] r9_w8; wire [7:0] r9_w9; wire [7:0] r9_w10; wire [7:0] r9_w11;
wire [7:0] r9_w12; wire [7:0] r9_w13; wire [7:0] r9_w14; wire [7:0] r9_w15;

Round_i Round_9 (r8_w0, r8_w1, r8_w2, r8_w3, r8_w4, r8_w5, r8_w6, r8_w7,
					r8_w8, r8_w9, r8_w10, r8_w11, r8_w12, r8_w13, r8_w14, r8_w15,
					key90, key91, key92, key93,
					r9_w0, r9_w1, r9_w2, r9_w3, r9_w4, r9_w5, r9_w6, r9_w7,
					r9_w8, r9_w9, r9_w10, r9_w11, r9_w12, r9_w13, r9_w14, r9_w15
					);	
//next is round 10, the final round

wire [7:0] r10_n0; wire [7:0] r10_n1; wire [7:0] r10_n2; wire [7:0] r10_n3;
wire [7:0] r10_n4; wire [7:0] r10_n5; wire [7:0] r10_n6; wire [7:0] r10_n7; 
wire [7:0] r10_n8; wire [7:0] r10_n9; wire [7:0] r10_n10; wire [7:0] r10_n11;
wire [7:0] r10_n12; wire [7:0] r10_n13; wire [7:0] r10_n14; wire [7:0] r10_n15;
subbytes32 R9_sbox (r9_w0, r9_w1, r9_w2, r9_w3, r9_w4, r9_w5, r9_w6, r9_w7,
						r9_w8, r9_w9, r9_w10, r9_w11, r9_w12, r9_w13, r9_w14, r9_w15,
						r10_n0, r10_n1, r10_n2, r10_n3, r10_n4, r10_n5, r10_n6, r10_n7,
						r10_n8, r10_n9, r10_n10, r10_n11, r10_n12, r10_n13, r10_n14, r10_n15); 

wire [7:0] r10_nn0; wire [7:0] r10_nn1; wire [7:0] r10_nn2; wire [7:0] r10_nn3;
wire [7:0] r10_nn4; wire [7:0] r10_nn5; wire [7:0] r10_nn6; wire [7:0] r10_nn7; 
wire [7:0] r10_nn8; wire [7:0] r10_nn9; wire [7:0] r10_nn10; wire [7:0] r10_nn11;
wire [7:0] r10_nn12; wire [7:0] r10_nn13; wire [7:0] r10_nn14; wire [7:0] r10_nn15;

shiftrows R10_s_row(r10_n0, r10_n1, r10_n2, r10_n3, r10_n4, r10_n5, r10_n6, r10_n7,
			r10_n8, r10_n9, r10_n10, r10_n11, r10_n12, r10_n13, r10_n14, r10_n15,
			r10_nn0, r10_nn1, r10_nn2, r10_nn3, r10_nn4, r10_nn5, r10_nn6, r10_nn7,
			r10_nn8, r10_nn9, r10_nn10, r10_nn11, r10_nn12, r10_nn13, r10_nn14, r10_nn15);

wire [7:0] r10_w0; wire [7:0] r10_w1; wire [7:0] r10_w2; wire [7:0] r10_w3;
wire [7:0] r10_w4; wire [7:0] r10_w5; wire [7:0] r10_w6; wire [7:0] r10_w7; 
wire [7:0] r10_w8; wire [7:0] r10_w9; wire [7:0] r10_w10; wire [7:0] r10_w11;
wire [7:0] r10_w12; wire [7:0] r10_w13; wire [7:0] r10_w14; wire [7:0] r10_w15;

AddRoundKey R10_result (key100[31:24], key100[23:16], key100[15:8], key100[7:0],
					key101[31:24], key101[23:16], key101[15:8], key101[7:0],
					key102[31:24], key102[23:16], key102[15:8], key102[7:0],
					key103[31:24], key103[23:16], key103[15:8], key103[7:0],
					r10_nn0, r10_nn1, r10_nn2, r10_nn3, r10_nn4, r10_nn5, r10_nn6, r10_nn7,
			      r10_nn8, r10_nn9, r10_nn10, r10_nn11, r10_nn12, r10_nn13, r10_nn14, r10_nn15,
					r10_w0, r10_w1, r10_w2, r10_w3, r10_w4, r10_w5, r10_w6, r10_w7,
					r10_w8, r10_w9, r10_w10, r10_w11, r10_w12, r10_w13, r10_w14, r10_w15
					);

//the following assign statements write the final ciphertext result to the output

assign ctext0[31:24] = r10_w0;
assign ctext0[23:16] = r10_w1;
assign ctext0[15:8] = r10_w2;
assign ctext0[7:0] = r10_w3;
assign ctext1[31:24] = r10_w4;
assign ctext1[23:16] = r10_w5;
assign ctext1[15:8] = r10_w6;
assign ctext1[7:0] = r10_w7;
assign ctext2[31:24] = r10_w8;
assign ctext2[23:16] = r10_w9;
assign ctext2[15:8] = r10_w10;
assign ctext2[7:0] = r10_w11;
assign ctext3[31:24] = r10_w12;
assign ctext3[23:16] = r10_w13;
assign ctext3[15:8] = r10_w14;
assign ctext3[7:0] = r10_w15;
	
endmodule 

module AddRoundKey (
			input wire [7:0] key0,
			input wire [7:0] key1,
			input wire [7:0] key2,
			input wire [7:0] key3,
			input wire [7:0] key4,
			input wire [7:0] key5,
			input wire [7:0] key6,
			input wire [7:0] key7,
			input wire [7:0] key8,
			input wire [7:0] key9,
			input wire [7:0] key10,
			input wire [7:0] key11,
			input wire [7:0] key12,
			input wire [7:0] key13,
			input wire [7:0] key14,
			input wire [7:0] key15,
			input wire [7:0] p0,
			input wire [7:0] p1,
			input wire [7:0] p2,
			input wire [7:0] p3,
			input wire [7:0] p4,
			input wire [7:0] p5,
			input wire [7:0] p6,
			input wire [7:0] p7,
			input wire [7:0] p8,
			input wire [7:0] p9,
			input wire [7:0] p10,
			input wire [7:0] p11,
			input wire [7:0] p12,
			input wire [7:0] p13,
			input wire [7:0] p14,
			input wire [7:0] p15,
			output wire [7:0] q0,
			output wire [7:0] q1,
			output wire [7:0] q2,
			output wire [7:0] q3,
			output wire [7:0] q4,
			output wire [7:0] q5,
			output wire [7:0] q6,
			output wire [7:0] q7,
			output wire [7:0] q8,
			output wire [7:0] q9,
			output wire [7:0] q10,
			output wire [7:0] q11,
			output wire [7:0] q12,
			output wire [7:0] q13,
			output wire [7:0] q14,
			output wire [7:0] q15
			);
//This module implements the AddRoundKey () transformation 
//on the state through XOR bitwise operations 
//(see Figure 10 in AES_NIST.FIPS.197.pdf document)
assign q0 = key0 ^ p0;
assign q1 = key1 ^ p1;
assign q2 = key2 ^ p2;
assign q3 = key3 ^ p3;
assign q4 = key4 ^ p4;
assign q5 = key5 ^ p5;
assign q6 = key6 ^ p6;
assign q7 = key7 ^ p7;
assign q8 = key8 ^ p8;
assign q9 = key9 ^ p9;
assign q10 = key10 ^ p10;
assign q11 = key11 ^ p11;
assign q12 = key12 ^ p12;
assign q13 = key13 ^ p13;
assign q14 = key14 ^ p14;
assign q15 = key15 ^ p15;

endmodule 


module subbytes8 (input wire [7:0] a, output wire [7:0] q);
//this module implements the subbytes operation of an element in GF(2^8) using
//GF (2^4) operatoins following the equations presented in:
//An ASIC Implementation of the AES SBoxes paper by J. Wokerstorfer, et al.
//I follow the Fig. 2 schematic in implementing the subbyte operation in GF(2^8) 
wire aA, aB, aC, al0, al1, al2, al3, ah0, ah1, ah2, ah3;
// convert from GF(2^8) to GF(2^f): a = ahx + al.

xor (aA, a[1], a[7]); xor (aB, a[5], a[7]); xor (aC, a[4], a[6]);
xor (al0, aC, a[0], a[5]); xor (al1, a[1], a[2]); buf (al2, aA); xor (al3, a[2], a[4]);
xor (ah0, aC, a[5]); xor (ah1, aA, aC); xor (ah2, aB, a[2], a[3]); buf (ah3, aB);
//square ah and al elements go get qh and ql
wire qh0, qh1, qh2, qh3;
xor (qh0, ah0, ah2); buf (qh1, ah2); xor (qh2, ah1, ah3); buf (qh3, ah3);
wire ql0, ql1, ql2, ql3;
xor (ql0, al0, al2); buf (ql1, al2); xor (ql2, al1, al3); buf (ql3, al3);

//multiply qh with e
wire qhe0, qhe1, qhe2, qhe3;
xor (qhe0, qh1, qh2, qh3); xor (qhe1, qh0, qh1); xor (qhe2, qh0, qh1, qh2); xor (qhe3, qh0, qh1, qh2, qh3);
//xor qhe and ql to get qhel
wire qhel0, qhel1, qhel2, qhel3;
xor (qhel0, qhe0, ql0); xor (qhel1, qhe1, ql1); xor (qhel2, qhe2, ql2); xor (qhel3, qhe3, ql3); 


//multiply ah with al to get qhl
wire qhl0, qhl1, qhl2, qhl3, qhA, qhB;
xor (qhA, ah0, ah3); xor (qhB, ah2, ah3);
assign qhl0 = (ah0 & al0) ^ (ah3 & al1) ^ (ah2 & al2) ^ (ah1 & al3);
assign qhl1 = (ah1 & al0) ^ (qhA & al1) ^ (qhB & al2) ^ ((ah1 ^ ah2)& al3);
assign qhl2 = (ah2 & al0) ^ (ah1 & al1) ^ (qhA & al2) ^ (qhB & al3);
assign qhl3 = (ah3 & al0) ^ (ah2 & al1) ^ (ah1 & al2) ^ (qhA & al3);

// xor qhel with qhl to get xin
wire xin0, xin1, xin2, xin3;
xor (xin0, qhel0, qhl0); xor (xin1, qhel1, qhl1); xor (xin2, qhel2, qhl2); xor (xin3, qhel3, qhl3); 
//invert xin to get inv
wire  inv0, inv1, inv2, inv3, aAinv;
assign aAinv = (xin1 ^ xin2 ^ xin3) ^ (xin1 & xin2 & xin3);
assign inv0 = aAinv ^ xin0 ^ (xin0 & xin2) ^ (xin1 & xin2) ^ (xin0 & xin1 & xin2);
assign inv1 = (xin0 & xin1) ^ (xin0 & xin2) ^ (xin1 & xin2) ^ xin3 ^ (xin1 & xin3) ^ (xin0 & xin1 & xin3);
assign inv2 = (xin0 & xin1) ^ xin2 ^ (xin0 & xin2) ^ xin3 ^ (xin0 & xin3) ^ (xin0 & xin2 & xin3);
assign inv3 = aAinv ^ (xin0 & xin3) ^ (xin1 & xin3) ^ (xin2 & xin3);
//calculate ah xor al to get xhl
wire xhl0, xhl1, xhl2, xhl3;
xor (xhl0, ah0, al0); xor (xhl1, ah1, al1); xor (xhl2, ah2, al2); xor (xhl3, ah3, al3); 

//calculate ah times inv to get qmh
wire qmh0, qmh1, qmh2, qmh3;
//xor (qmhA, ah0, ah3); xor (qmhB, ah2, ah3); // same as above, reuse
assign qmh0 = (ah0 & inv0) ^ (ah3 & inv1) ^ (ah2 & inv2) ^ (ah1 & inv3);
assign qmh1 = (ah1 & inv0) ^ (qhA & inv1) ^ (qhB & inv2) ^ ((ah1 ^ ah2)& inv3);
assign qmh2 = (ah2 & inv0) ^ (ah1 & inv1) ^ (qhA & inv2) ^ (qhB & inv3);
assign qmh3 = (ah3 & inv0) ^ (ah2 & inv1) ^ (ah1 & inv2) ^ (qhA & inv3); 

//calculate xhl times inv to get qml
wire qml0, qml1, qml2, qml3, xhlA, xhlB;
xor (xhlA, xhl0, xhl3); xor (xhlB, xhl2, xhl3); 
assign qml0 = (xhl0 & inv0) ^ (xhl3 & inv1) ^ (xhl2 & inv2) ^ (xhl1 & inv3);
assign qml1 = (xhl1 & inv0) ^ (xhlA & inv1) ^ (xhlB & inv2) ^ ((xhl1 ^ xhl2)& inv3);
assign qml2 = (xhl2 & inv0) ^ (xhl1 & inv1) ^ (xhlA & inv2) ^ (xhlB & inv3);
assign qml3 = (xhl3 & inv0) ^ (xhl2 & inv1) ^ (xhl1 & inv2) ^ (xhlA & inv3); 
// convert polynomial qmhX + qml from GF(2^4) back to GF(2^8)
wire gf0, gf1, gf2, gf3, gf4, gf5, gf6, gf7, qmA, qmB;
xor (qmA, qml1, qmh3); xor (qmB, qmh0, qmh1);
xor (gf0, qml0, qmh0); xor (gf1, qmB, qmh3); xor (gf2, qmA, qmB); xor (gf3, qmB, qml1, qmh2);
xor (gf4, qmA, qmB, qml3); xor (gf5, qmB, qml2);
xor (gf6, qmA, qml2, qml3, qmh0); xor (gf7, qmB, qml2, qmh3);

//next I do the affine transformation applied to gf byte to get sbox byte
wire sbox0, sbox1, sbox2, sbox3, sbox4, sbox5, sbox6, sbox7, gfA, gfB, gfC, gfD;
wire ngf0, ngf5, ngf1, ngf6;
not (ngf0, gf0); not (ngf1, gf1); not (ngf5, gf5); not (ngf6, gf6);
xor (gfA, gf0, gf1); xor (gfB, gf2, gf3); xor (gfC, gf4, gf5); xor (gfD, gf6, gf7);
xor (sbox0, ngf0, gfC, gfD); 
//xor (sbox0, gf0, gfC, gfD); 
xor (sbox1, ngf5, gfA, gfD);
//xor (sbox1, gf5, gfA, gfD);
xor (sbox2, gf2, gfA, gfD); 
xor (sbox3, gf7, gfA, gfB);
xor (sbox4, gf4, gfA, gfB); 
xor (sbox5, ngf1, gfB, gfC);
//xor (sbox5, gf1, gfB, gfC);
xor (sbox6, ngf6, gfB, gfC);
//xor (sbox6, gf6, gfB, gfC); 
xor (sbox7, gf3, gfC, gfD);
//
assign q[0] = sbox0; assign q[1] = sbox1;
assign q[2] = sbox2; assign q[3] = sbox3;
assign q[4] = sbox4; assign q[5] = sbox5;
assign q[6] = sbox6; assign q[7] = sbox7; 


endmodule

module subbytes32 (
			input wire [7:0] m0,
			input wire [7:0] m1,
			input wire [7:0] m2,
			input wire [7:0] m3,
			input wire [7:0] m4,
			input wire [7:0] m5,
			input wire [7:0] m6,
			input wire [7:0] m7,
			input wire [7:0] m8,
			input wire [7:0] m9,
			input wire [7:0] m10,
			input wire [7:0] m11,
			input wire [7:0] m12,
			input wire [7:0] m13,
			input wire [7:0] m14,
			input wire [7:0] m15,
			output wire [7:0] n0,
			output wire [7:0] n1,
			output wire [7:0] n2,
			output wire [7:0] n3,
			output wire [7:0] n4,
			output wire [7:0] n5,
			output wire [7:0] n6,
			output wire [7:0] n7,
			output wire [7:0] n8,
			output wire [7:0] n9,
			output wire [7:0] n10,
			output wire [7:0] n11,
			output wire [7:0] n12,
			output wire [7:0] n13,
			output wire [7:0] n14,
			output wire [7:0] n15
			);
//this module utilizes the subbytes8 GF(2^8) operation to perform 
//the SubBytes () transformation of each byte of the current state
//See Figure 6 in AES_NIST.FIPS.197.pdf document 
subbytes8 sbox0 (m0, n0);
subbytes8 sbox1 (m1, n1);
subbytes8 sbox2 (m2, n2);
subbytes8 sbox3 (m3, n3);
subbytes8 sbox4 (m4, n4);
subbytes8 sbox5 (m5, n5);
subbytes8 sbox6 (m6, n6);
subbytes8 sbox7 (m7, n7);
subbytes8 sbox8 (m8, n8);
subbytes8 sbox9 (m9, n9);
subbytes8 sbox10 (m10, n10);
subbytes8 sbox11 (m11, n11);
subbytes8 sbox12 (m12, n12);
subbytes8 sbox13 (m13, n13);
subbytes8 sbox14 (m14, n14);
subbytes8 sbox15 (m15, n15);
endmodule 
		
module shiftrows (
			input wire [7:0] n0,
			input wire [7:0] n1,
			input wire [7:0] n2,
			input wire [7:0] n3,
			input wire [7:0] n4,
			input wire [7:0] n5,
			input wire [7:0] n6,
			input wire [7:0] n7,
			input wire [7:0] n8,
			input wire [7:0] n9,
			input wire [7:0] n10,
			input wire [7:0] n11,
			input wire [7:0] n12,
			input wire [7:0] n13,
			input wire [7:0] n14,
			input wire [7:0] n15,
			output wire [7:0] nn0,
			output wire [7:0] nn1,
			output wire [7:0] nn2,
			output wire [7:0] nn3,
			output wire [7:0] nn4,
			output wire [7:0] nn5,
			output wire [7:0] nn6,
			output wire [7:0] nn7,
			output wire [7:0] nn8,
			output wire [7:0] nn9,
			output wire [7:0] nn10,
			output wire [7:0] nn11,
			output wire [7:0] nn12,
			output wire [7:0] nn13,
			output wire [7:0] nn14,
			output wire [7:0] nn15
			);
//This module pefroms the ShiftRows () transformation as described in 
//Figure 8 of the AES_NIST.FIPS.197.pdf document.			
assign nn0 = n0; assign nn1 = n5; assign nn2 = n10; assign nn3 = n15;
assign nn4 = n4; assign nn5 = n9; assign nn6 = n14; assign nn7 = n3;
assign nn8 = n8; assign nn9 = n13; assign nn10 = n2; assign nn11 = n7;
assign nn12 = n12; assign nn13 = n1; assign nn14 = n6; assign nn15 = n11;

endmodule 		

module mixcolumns1 (	
			input wire [7:0] b3,
			input wire [7:0] b2,
			input wire [7:0] b1,
			input wire [7:0] b0,
			output wire [7:0] w3,
			output wire [7:0] w2,
			output wire [7:0] w1,
			output wire [7:0] w0
			);
//This module implements the MixColums () transformation as described
//in AES_NIST.FIPS.197.pdf document
//But for the implementation of this transformation I use the algorithm
//presented in Fig. 5 of the paper:
//An efficient architecture for the AES mix columsn operation by H. Li, et al.  
wire [7:0] b0x2; wire [7:0] b1x2; wire [7:0] b2x2; wire [7:0] b3x2;
buf (b0x2[0], b0[7]); xor (b0x2[1], b0[0], b0[7]);
buf (b0x2[2], b0[1]); xor (b0x2[3], b0[2], b0[7]);
xor (b0x2[4], b0[3], b0[7]); buf (b0x2[5], b0[4]);
buf (b0x2[6], b0[5]); buf (b0x2[7], b0[6]);

buf (b1x2[0], b1[7]); xor (b1x2[1], b1[0], b1[7]);
buf (b1x2[2], b1[1]); xor (b1x2[3], b1[2], b1[7]);
xor (b1x2[4], b1[3], b1[7]); buf (b1x2[5], b1[4]);
buf (b1x2[6], b1[5]); buf (b1x2[7], b1[6]);

buf (b2x2[0], b2[7]); xor (b2x2[1], b2[0], b2[7]);
buf (b2x2[2], b2[1]); xor (b2x2[3], b2[2], b2[7]);
xor (b2x2[4], b2[3], b2[7]); buf (b2x2[5], b2[4]);
buf (b2x2[6], b2[5]); buf (b2x2[7], b2[6]);

buf (b3x2[0], b3[7]); xor (b3x2[1], b3[0], b3[7]);
buf (b3x2[2], b3[1]); xor (b3x2[3], b3[2], b3[7]);
xor (b3x2[4], b3[3], b3[7]); buf (b3x2[5], b3[4]);
buf (b3x2[6], b3[5]); buf (b3x2[7], b3[6]);

wire [7:0] x1w0; wire [7:0] x1w1; wire [7:0] x1w2; wire [7:0] x1w3;

assign x1w0 = b0x2 ^ b0;
assign x1w1 = b1x2 ^ b1;
assign x1w2 = b2x2 ^ b2;
assign x1w3 = b3x2 ^ b3;

wire [7:0] x2w0l; wire [7:0] x2w1l; wire [7:0] x2w2l; wire [7:0] x2w3l;
wire [7:0] x2w0r; wire [7:0] x2w1r; wire [7:0] x2w2r; wire [7:0] x2w3r;

assign x2w0r = b0x2 ^ x1w3; assign x2w0l = b2 ^ b1;
assign x2w1r = b1x2 ^ x1w0; assign x2w1l = b3 ^ b2;
assign x2w2r = b2x2 ^ x1w1; assign x2w2l = b3 ^ b0;
assign x2w3r = b3x2 ^ x1w2; assign x2w3l = b0 ^ b1; 

assign w0 = x2w0r ^ x2w0l;
assign w1 = x2w1r ^ x2w1l;
assign w2 = x2w2r ^ x2w2l;
assign w3 = x2w3r ^ x2w3l;

endmodule  
		
module mixcolumns4 (
			input wire [7:0] b0,
			input wire [7:0] b1,
			input wire [7:0] b2,
			input wire [7:0] b3,
			input wire [7:0] b4,
			input wire [7:0] b5,
			input wire [7:0] b6,
			input wire [7:0] b7,
			input wire [7:0] b8,
			input wire [7:0] b9,
			input wire [7:0] b10,
			input wire [7:0] b11,
			input wire [7:0] b12,
			input wire [7:0] b13,
			input wire [7:0] b14,
			input wire [7:0] b15,
			output wire [7:0] w0,
			output wire [7:0] w1,
			output wire [7:0] w2,
			output wire [7:0] w3,
			output wire [7:0] w4,
			output wire [7:0] w5,
			output wire [7:0] w6,
			output wire [7:0] w7,
			output wire [7:0] w8,
			output wire [7:0] w9,
			output wire [7:0] w10,
			output wire [7:0] w11,
			output wire [7:0] w12,
			output wire [7:0] w13,
			output wire [7:0] w14,
			output wire [7:0] w15
			);
//This module implements the MixColumn () tranformation for the state			
mixcolumns1 col0 ( b0, b1, b2, b3,
						w0, w1, w2, w3);
mixcolumns1 col1 ( b4, b5, b6, b7,
						w4, w5, w6, w7);
mixcolumns1 col2 ( b8, b9, b10, b11,
						w8, w9, w10, w11);
mixcolumns1 col3 ( b12, b13, b14, b15,
						w12, w13, w14, w15);
endmodule 

module keyschedule1 (
			input wire [7:0] r1,
			input wire [31:0] key00,
			input wire [31:0] key01,
			input wire [31:0] key02,
			input wire [31:0] key03,
			output wire [31:0] key10,
			output wire [31:0] key11,
			output wire [31:0] key12,
			output wire [31:0] key13
			);
wire [7:0] ks0; wire [7:0] ks1;
wire [7:0] ks2; wire [7:0] ks3;
wire [31:0] sw0; 
wire [31:0] xw0;
wire [31:0] xw1; wire [31:0] xw2;
wire [31:0] xw3;
//wire [31:0] r1;
//assign r1 = 8'b00000001; // constant ri for round 1
subbytes8 s0 (key03[23:16], ks0);
subbytes8 s1 (key03[15:8], ks1);
subbytes8 s2 (key03[7:0], ks2);
subbytes8 s3 (key03[31:24], ks3);
assign sw0[31:24] = ks0 ^ r1;
assign sw0[23:16] = ks1;
assign sw0[15:8] = ks2;
assign sw0[7:0] = ks3;
//generate the key round output
assign xw0 = key00 ^ sw0;
assign key10 = xw0;
assign xw1 = key01 ^ xw0;
assign key11 = xw1;
assign xw2 = key02 ^ xw1;
assign key12 = xw2;
assign xw3 = key03 ^ xw2;
assign key13 = xw3;

endmodule

module Round_i (
					input wire [7:0] ri_s0,
					input wire [7:0] ri_s1,
					input wire [7:0] ri_s2,
					input wire [7:0] ri_s3,
					input wire [7:0] ri_s4,
					input wire [7:0] ri_s5,
			      input wire [7:0] ri_s6,
					input wire [7:0] ri_s7,
					input wire [7:0] ri_s8,
					input wire [7:0] ri_s9,
					input wire [7:0] ri_s10,
					input wire [7:0] ri_s11,
					input wire [7:0] ri_s12,
					input wire [7:0] ri_s13,
					input wire [7:0] ri_s14,
					input wire [7:0] ri_s15,
					input wire [31:0] ri_k0,
					input wire [31:0] ri_k1,
					input wire [31:0] ri_k2,
					input wire [31:0] ri_k3,
					output wire [7:0] ri_w0,
					output wire [7:0] ri_w1,
					output wire [7:0] ri_w2,
					output wire [7:0] ri_w3,
					output wire [7:0] ri_w4,
					output wire [7:0] ri_w5,
					output wire [7:0] ri_w6,
					output wire [7:0] ri_w7,
					output wire [7:0] ri_w8,
					output wire [7:0] ri_w9,
					output wire [7:0] ri_w10,
					output wire [7:0] ri_w11,
					output wire [7:0] ri_w12,
					output wire [7:0] ri_w13,
					output wire [7:0] ri_w14,
					output wire [7:0] ri_w15
					);
//This module combines the transformations for the round as described in
//Figure 4 algorithm to implement a regular round (see AES_NIST.FIPS.197.pdf document)					
wire [7:0] ri_n0; wire [7:0] ri_n1; wire [7:0] ri_n2; wire [7:0] ri_n3;
wire [7:0] ri_n4; wire [7:0] ri_n5; wire [7:0] ri_n6; wire [7:0] ri_n7; 
wire [7:0] ri_n8; wire [7:0] ri_n9; wire [7:0] ri_n10; wire [7:0] ri_n11;
wire [7:0] ri_n12; wire [7:0] ri_n13; wire [7:0] ri_n14; wire [7:0] ri_n15;

subbytes32 Ri_sbox (ri_s0, ri_s1, ri_s2, ri_s3, ri_s4, ri_s5, ri_s6, ri_s7,
						ri_s8, ri_s9, ri_s10, ri_s11, ri_s12, ri_s13, ri_s14, ri_s15,
						ri_n0, ri_n1, ri_n2, ri_n3, ri_n4, ri_n5, ri_n6, ri_n7,
						ri_n8, ri_n9, ri_n10, ri_n11, ri_n12, ri_n13, ri_n14, ri_n15); 

wire [7:0] ri_nn0; wire [7:0] ri_nn1; wire [7:0] ri_nn2; wire [7:0] ri_nn3;
wire [7:0] ri_nn4; wire [7:0] ri_nn5; wire [7:0] ri_nn6; wire [7:0] ri_nn7; 
wire [7:0] ri_nn8; wire [7:0] ri_nn9; wire [7:0] ri_nn10; wire [7:0] ri_nn11;
wire [7:0] ri_nn12; wire [7:0] ri_nn13; wire [7:0] ri_nn14; wire [7:0] ri_nn15;

shiftrows Ri_s_row(ri_n0, ri_n1, ri_n2, ri_n3, ri_n4, ri_n5, ri_n6, ri_n7,
			ri_n8, ri_n9, ri_n10, ri_n11, ri_n12, ri_n13, ri_n14, ri_n15,
			ri_nn0, ri_nn1, ri_nn2, ri_nn3, ri_nn4, ri_nn5, ri_nn6, ri_nn7,
			ri_nn8, ri_nn9, ri_nn10, ri_nn11, ri_nn12, ri_nn13, ri_nn14, ri_nn15);

wire [7:0] ri_mx0; wire [7:0] ri_mx1; wire [7:0] ri_mx2; wire [7:0] ri_mx3;
wire [7:0] ri_mx4; wire [7:0] ri_mx5; wire [7:0] ri_mx6; wire [7:0] ri_mx7; 
wire [7:0] ri_mx8; wire [7:0] ri_mx9; wire [7:0] ri_mx10; wire [7:0] ri_mx11;
wire [7:0] ri_mx12; wire [7:0] ri_mx13; wire [7:0] ri_mx14; wire [7:0] ri_mx15;

mixcolumns4 Ri_m_col (ri_nn0, ri_nn1, ri_nn2, ri_nn3, ri_nn4, ri_nn5, ri_nn6, ri_nn7,
			ri_nn8, ri_nn9, ri_nn10, ri_nn11, ri_nn12, ri_nn13, ri_nn14, ri_nn15,
			ri_mx0, ri_mx1, ri_mx2, ri_mx3, ri_mx4, ri_mx5, ri_mx6, ri_mx7,
			ri_mx8, ri_mx9, ri_mx10, ri_mx11, ri_mx12, ri_mx13, ri_mx14, ri_mx15);
//

AddRoundKey Ri_start (ri_k0[31:24], ri_k0[23:16], ri_k0[15:8], ri_k0[7:0],
					ri_k1[31:24], ri_k1[23:16], ri_k1[15:8], ri_k1[7:0],
					ri_k2[31:24], ri_k2[23:16], ri_k2[15:8], ri_k2[7:0],
					ri_k3[31:24], ri_k3[23:16], ri_k3[15:8], ri_k3[7:0],
					ri_mx0, ri_mx1, ri_mx2, ri_mx3, ri_mx4, ri_mx5, ri_mx6, ri_mx7,
					ri_mx8, ri_mx9, ri_mx10, ri_mx11, ri_mx12, ri_mx13, ri_mx14, ri_mx15,
					ri_w0, ri_w1, ri_w2, ri_w3, ri_w4, ri_w5, ri_w6, ri_w7,
					ri_w8, ri_w9, ri_w10, ri_w11, ri_w12, ri_w13, ri_w14, ri_w15
					);

endmodule 
