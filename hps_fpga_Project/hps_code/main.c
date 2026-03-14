#include <stdio.h> 
#include <unistd.h> 
#include <fcntl.h> 
#include <sys/mman.h> 
#include "hwlib.h" 
#include "socal/socal.h" 
#include "socal/hps.h" 
#include "socal/alt_gpio.h" 
#include "hps_0.h" 
 
#define HW_REGS_BASE ( ALT_STM_OFST ) 
#define HW_REGS_SPAN ( 0x04000000 ) 
#define HW_REGS_MASK ( HW_REGS_SPAN - 1 ) 

// Defintions of instruction and status functions
#define INST_RESET 0x00000000
#define INST_SIGNAL_TX 0x00000001
#define INST_TX_COMPLETE 0x00000003
#define INST_RX_COMPLETE 0x00000005

#define STATUS_RESET 0X00000000
#define STATUS_READY_RX 0x00000003
#define STATUS_ACK_RX 0x00000005
#define STATUS_PROCESSING 0x00000009
#define STATUS_DONE_TX 0x0000000F

// Definitions of apb offsets
#define INSTRUCTION_BASE 0x00000000
#define STATUS_BASE 0x00000004
#define DATA_BASE 0x00000008 // 14 32-bit words
#define DATA_END 0x0000003C
#define DATA_RX_0_LO 0x00000008
#define DATA_RX_0_HI 0x0000000C
#define DATA_RX_1_LO 0x00000010
#define DATA_RX_1_HI 0x00000014
#define DATA_RX_2_LO 0x00000018
#define DATA_RX_2_HI 0x0000001C

// Benchmarking parameters
#define BENCHMARK_ITERATIONS 1000
#define DATA_BYTES 4 // limit on int size for generation
#define MATRIX_SIZE 2
#define SEQ_VALUE_COUNT 16
#define BUS_ADDRESSES 14

// Benchmarking data structure definitions
typedef struct {
    uint32_t entry[MATRIX_SIZE][MATRIX_SIZE];
} square_matrix_t;

// packet for sending to mac core
typedef struct {
    uint32_t data[MATRIX_SIZE*2];
} mac_pack_t;

typedef struct {
    mac_pack_t pack[MATRIX_SIZE*2]; // 2 packs for 2 rows of output matrix
} matrix_mult_pack_t;

void init_identity_matrix(square_matrix_t *matrix) {
    int row, col;
    for (row = 0; row < MATRIX_SIZE; row++) {
        for (col = 0; col < MATRIX_SIZE; col++) {
            matrix->entry[row][col] = 0;
            if (row == col) {
                matrix->entry[row][col] = 1;
            }
        }
    }
}

void init_ones_row_matrix(square_matrix_t *matrix) {
   int row, col;
   row = 0; // only first row is ones, rest are zeros
   for (col = 0; col < MATRIX_SIZE; col++) {
      matrix->entry[row][col] = 1;
   }
}

/* function to generate sequential data for testing
   generates matrix of size MATRIX_SIZE x MATRIX_SIZE
   stored in a single 2D array where 2nd col is identity

   [0 0] [1 0] 
   [0 0] [0 1]

   [1 1] [1 0]
   [1 1] [0 1]
*/
void generate_sequential_data_with_identity(
    square_matrix_t out[SEQ_VALUE_COUNT][2],
    const square_matrix_t *identity)
{
    int value_idx, row, col;
    uint32_t mask;

    if (DATA_BYTES >= 4) {
        mask = 0xFFFFFFFFu;
    } else {
         // 0x00001000 - 1 = 0x00000FFF for 3 bytes, 0x00000100 - 1 = 0x000000FF for 2 bytes, etc
        mask = (1u << (DATA_BYTES * 8)) - 1u;
    }

    for (value_idx = 0; value_idx < SEQ_VALUE_COUNT; value_idx++) {
        uint32_t v = ((uint32_t)value_idx) & mask;
        for (row = 0; row < MATRIX_SIZE; row++) {
            for (col = 0; col < MATRIX_SIZE; col++) {
                out[value_idx][0].entry[row][col] = v;
                out[value_idx][1].entry[row][col] = identity->entry[row][col];
            }
        }
    }
}

void generate_sequential_data_with_ones_row(
    square_matrix_t out[SEQ_VALUE_COUNT][2],
    const square_matrix_t *ones_row)
{
    int value_idx, row, col;
    uint32_t mask;

    if (DATA_BYTES >= 4) {
        mask = 0xFFFFFFFFu;
    } else {
         // 0x00001000 - 1 = 0x00000FFF for 3 bytes, 0x00000100 - 1 = 0x000000FF for 2 bytes, etc
        mask = (1u << (DATA_BYTES * 8)) - 1u;
    }

    for (value_idx = 0; value_idx < SEQ_VALUE_COUNT; value_idx++) {
        uint32_t v = ((uint32_t)value_idx) & mask;
        for (row = 0; row < MATRIX_SIZE; row++) {
            for (col = 0; col < MATRIX_SIZE; col++) {
                out[value_idx][0].entry[row][col] = v;
                out[value_idx][1].entry[row][col] = ones_row->entry[row][col];
            }
        }
    }
}

// make matrix_mult_pack
/* In:
   [a0 a1] [b0 d0] 
   [c0 c1] [b1 d1]

    Out:
   [a0]
   [a1]
   [b0]
   [b1]
   [c0]
   [c1]
   [d0]
   [d1]
*/
// output is array of mac packs
void make_matrix_mult_pack( square_matrix_t matrix_in[SEQ_VALUE_COUNT][2],
                                matrix_mult_pack_t matrix_out[SEQ_VALUE_COUNT]) {
    int value_idx, row, col;
    for (value_idx = 0; value_idx < SEQ_VALUE_COUNT; value_idx++) {
        for (row = 0; row < MATRIX_SIZE; row++) {
            for (col = 0; col < MATRIX_SIZE; col++) {
                matrix_out[value_idx].pack[row*2 + col].data[0] = matrix_in[value_idx][0].entry[row][col];
                matrix_out[value_idx].pack[row*2 + col].data[1] = matrix_in[value_idx][1].entry[row][col];
            }
        }
    }
}

/* Helper function to print a pair of matrices, for verification of generated data
   [0 0] [1 0] 
   [0 0] [0 1]

   [1 1] [1 0]
   [1 1] [0 1]
*/
void print_matrix_2d(const square_matrix_t pair[2]) {
    int row, col;
    for (row = 0; row < MATRIX_SIZE; row++) {
        printf("[");
        for (col = 0; col < MATRIX_SIZE; col++) {
            printf("%u", pair[0].entry[row][col]);
            if (col < MATRIX_SIZE - 1) {
                printf(" ");
            }
        }
        printf("] [");
        for (col = 0; col < MATRIX_SIZE; col++) {
            printf("%u", pair[1].entry[row][col]);
            if (col < MATRIX_SIZE - 1) {
                printf(" ");
            }
        }
        printf("]\n");
    }
    printf("\n");
}

void print_all_matrix_pairs(const square_matrix_t pairs[SEQ_VALUE_COUNT][2]) {
    int idx;
    for (idx = 0; idx < SEQ_VALUE_COUNT; idx++) {
        printf("Pair %d:\n", idx);
        print_matrix_2d(pairs[idx]);
    }
}

void print_matrix_mult_pack(const matrix_mult_pack_t pack) {
    int row, col, data_idx;
    for (row = 0; row < MATRIX_SIZE; row++) {
        for (col = 0; col < MATRIX_SIZE; col++) {
            printf("Pack for output matrix element [%d][%d]:\n", row, col);
            for (data_idx = 0; data_idx < MATRIX_SIZE*2; data_idx++) {
                printf("%08x ", pack.pack[row*2 + col].data[data_idx]);
            }
            printf("\n");
        }
    }
}

// Future helper function to map status and instruction to led
// pio bits [3:0] are apb STATUS BASE bits [3:0]
// pio bits [9:6] are apb INSTRUCTION BASE bits [3:0]

// helper function for setting apb pointer
void *set_apb_pointer(void *virtual_base, unsigned long offset) {
    return virtual_base + ((unsigned long)(ALT_LWFPGASLVS_OFST + ERIC_IP2_0_BASE + offset) &
        (unsigned long)(HW_REGS_MASK));
}

int main() { 
 
   void *virtual_base; 
   int fd; 
   int loop_count; 
   int led_direction; 
   int led_mask;
	void *pio_led;
	void *apb_32x16; // eric_ip2_0
     
   int mem_data, mm_reg, j, ii; 
   int most_sig_bit, least_sig_bit;
   int aes_key[4];
   int aes_data[4];

    // map the address space for the LED registers into user space so we can interact with them. 
    // we'll map in the entire CSR span of the HPS since we want to access various registers within that span 
    printf("Calling fopen\n"); 
     
    if((fd = open( "/dev/mem", ( O_RDWR | O_SYNC))) == -1) { 
        printf("ERROR: could not open \"/dev/mem\"...\n"); 
        return(1); 
    } 
 
    printf("Creating mmap\n"); 
 
    virtual_base = mmap(NULL, HW_REGS_SPAN, ( PROT_READ | PROT_WRITE ), MAP_SHARED, fd, HW_REGS_BASE); 
 
    if(virtual_base == MAP_FAILED) { 
        printf("ERROR: mmap() failed...\n"); 
        close(fd); 
        return(1); 
    } 

	pio_led = virtual_base + ((unsigned long)(ALT_LWFPGASLVS_OFST + PIO_LED_BASE) & 
        (unsigned long)(HW_REGS_MASK)); 
	
	apb_32x16 = virtual_base + ((unsigned long)(ALT_LWFPGASLVS_OFST + ERIC_IP2_0_BASE) & 
         (unsigned long)(HW_REGS_MASK));
    
    // could use but hides the actual pointer math, which is helpful to see in this example
    //apb_32x16 = set_apb_pointer(virtual_base, 0); 
         
    loop_count = 0; 
    led_mask = 0x01; 
    led_direction = 0; // 0: left to right direction 
    printf("Starting while loop, base address: %p, virtual_base = %p\n", pio_led, virtual_base); 
    while(loop_count < 1) { 
        printf("In Loop, loop_count:%d, led_mask:%d, led_direction:%d\n", loop_count, led_mask, led_direction); 
        // control led 
        *(uint32_t *)pio_led = ~led_mask;  
 
        // wait 100ms 
        usleep(100*1000); 
         
        // update led mask 
        if (led_direction == 0){ 
            led_mask <<= 1; 
            if (led_mask == (0x01 << (PIO_LED_DATA_WIDTH-1))) 
                 led_direction = 1; 
        }else{ 
            led_mask >>= 1; 
            if (led_mask == 0x01){  
                led_direction = 0; 
                loop_count++; 
            } 
        }    
    } // while

    // Turn all LEDs off
    *(uint32_t *)pio_led = 0xFFF;
    usleep(100*5000); 
    *(uint32_t *)pio_led = 0x000; // Turn all LEDs on
    usleep(100*5000);  
    *(uint32_t *)pio_led = 0xFFF; // Turn all LEDs off

    // Test read and write to custom IP memory mapped registers
    int test_data= 0x10101010;
    for (ii = 0; ii < 64; ii+=4){
        mm_reg = ii;
        apb_32x16 = virtual_base + ((unsigned long)(ALT_LWFPGASLVS_OFST + ERIC_IP2_0_BASE + mm_reg) &
            (unsigned long)(HW_REGS_MASK));
		printf("Writing test data: %x to memory address = %p\n", test_data, apb_32x16);
        *(uint32_t *)apb_32x16 = test_data;
        test_data += 0x10101010;
    }

    printf("Reading memory locations\n");
    for (ii = 0; ii < 64; ii+=4){
        mm_reg = ii;
        apb_32x16 = virtual_base + ((unsigned long)(ALT_LWFPGASLVS_OFST + ERIC_IP2_0_BASE + mm_reg) &
            (unsigned long)(HW_REGS_MASK));
        mem_data = *(uint32_t *)apb_32x16;
        printf("Reading test data: %x from memory address = %p\n", mem_data, apb_32x16);
    }

   // Initialize matrices for benchmarking data generation
   square_matrix_t identity_matrix;
   square_matrix_t ones_row_matrix;
   init_identity_matrix(&identity_matrix);
   init_ones_row_matrix(&ones_row_matrix);
   generate_sequential_data_with_identity(identity_matrix_data, &identity_matrix);
   generate_sequential_data_with_ones_row(ones_row_matrix_data, &ones_row_matrix);
   print_all_matrix_pairs(identity_matrix_data);
   print_all_matrix_pairs(ones_row_matrix_data);

    // State machine test for MAC cluster coprocessor
    // Main loop
    while(1){
        // set instruction to reset, wait acknowledge
        apb_32x16 = set_apb_pointer(virtual_base, INSTRUCTION_BASE);
        *(uint32_t *)apb_32x16 = INST_RESET;
        apb_32x16 = set_apb_pointer(virtual_base, STATUS_BASE);
        while(*(uint32_t *)apb_32x16 != STATUS_RESET);
        printf("Cluster is in reset state\n");

        // set instruction to signal to tx, wait acknowledge
        apb_32x16 = set_apb_pointer(virtual_base, INSTRUCTION_BASE);
        *(uint32_t *)apb_32x16 = INST_SIGNAL_TX;
        apb_32x16 = set_apb_pointer(virtual_base, STATUS_BASE);
        while(*(uint32_t *)apb_32x16 != STATUS_READY_RX);
        printf("Cluster is ready to rx data\n");
        
        // LOAD matrix_mult_packs based on cores

        // set instruction to tx complete, wait acknowledge
        apb_32x16 = set_apb_pointer(virtual_base, INSTRUCTION_BASE);
        *(uint32_t *)apb_32x16 = INST_TX_COMPLETE;
        apb_32x16 = set_apb_pointer(virtual_base, STATUS_BASE);
        while(*(uint32_t *)apb_32x16 != STATUS_ACK_RX);
        printf("Cluster acknowledged tx complete\n");
		
        //while(*(uint32_t *)apb_32x16 != STATUS_PROCESSING);
        printf("Cluster has started processing\n");
        while(*(uint32_t *)apb_32x16 != STATUS_DONE_TX);
        printf("Cluster has completed processing and tx\n");

        printf("Reading data locations\n");
        for (j = 0, ii = 0; ii < 32; ii += 4, j++){
            apb_32x16 = set_apb_pointer(virtual_base, DATA_BASE + ii);
            mem_data = *(uint32_t *)apb_32x16;
            aes_data[j] = mem_data;
            printf("Memory data read [%x]: %08x\n", DATA_BASE + ii, mem_data);
        }
        printf("\n\n");
    }

    //====== MANUAL TEST ======================================================
    // for (ii = 0; ii < 32; ii+=4){
    //     printf("Enter coprocessor memory data in hexadecimal, to write in location = %x\n", ii);
    //     mm_reg = ii;
    //     scanf("%x", &mem_data);
    //     apb_32x16 = virtual_base + ((unsigned long)(ALT_LWFPGASLVS_OFST + ERIC_IP2_0_BASE + mm_reg) &
    //         (unsigned long)(HW_REGS_MASK));
    //     printf("Writing coprocessor memory address = %p\n", apb_32x16);
    //     *(uint32_t *)apb_32x16 = mem_data;
    // }

    // printf("Reading memory locations\n");
    // for (ii = 0; ii < 32; ii+=4){
    //     mm_reg = ii;
    //     apb_32x16 = virtual_base + ((unsigned long)(ALT_LWFPGASLVS_OFST + ERIC_IP2_0_BASE + mm_reg) &
    //         (unsigned long)(HW_REGS_MASK));
    //     printf("Reading coprocessor memory address = %p\n", apb_32x16);
    //     mem_data = *(uint32_t *)apb_32x16;
    //     printf("Memory data read: %x\n", mem_data);
    // }

    // clean up our memory mapping and exit 
        if( munmap(virtual_base, HW_REGS_SPAN) != 0) { 
        printf("ERROR: munmap() failed...\n"); 
        close(fd); 
        return(1); 
    } 
    close(fd); 
    return(0); 
} 