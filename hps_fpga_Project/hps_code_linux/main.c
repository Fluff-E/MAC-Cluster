#include <stdio.h> 
#include <unistd.h> 
#include <fcntl.h> 
#include <sys/mman.h> 
#include <time.h>
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
#define BUS_ADDRESSES 4

// Benchmarking data structure definitions
typedef struct {
    uint32_t entry[MATRIX_SIZE][MATRIX_SIZE];
} square_matrix_t;

// packet for sending to mac core does operation on matrix row and col
typedef struct {
    uint32_t data[MATRIX_SIZE*2];
} mac_pack_t;

typedef struct {
    mac_pack_t pack[MATRIX_SIZE*MATRIX_SIZE]; // one pack per output element
} matrix_mult_pack_t;

typedef struct{
    uint32_t out_entry[1]; // contains RX_#_LO and RX_#_HI for one output element, used for reading back results from cluster
} cluster_out_entry_t;

void print_cluster_status(uint32_t status_value) {
    switch (status_value) {
        case STATUS_RESET:
            printf("\tStatus: STATUS_RESET (0x%08x)\n", status_value);
            break;
        case STATUS_READY_RX:
            printf("\tStatus: STATUS_READY_RX (0x%08x)\n", status_value);
            break;
        case STATUS_ACK_RX:
            printf("\tStatus: STATUS_ACK_RX (0x%08x)\n", status_value);
            break;
        case STATUS_PROCESSING:
            printf("\tStatus: STATUS_PROCESSING (0x%08x)\n", status_value);
            break;
        case STATUS_DONE_TX:
            printf("\tStatus: STATUS_DONE_TX (0x%08x)\n", status_value);
            break;
        default:
            printf("\tStatus: UNKNOWN (0x%08x)\n", status_value);
            break;
    }
}

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

    for (row = 0; row < MATRIX_SIZE; row++) {
        for (col = 0; col < MATRIX_SIZE; col++) {
            matrix->entry[row][col] = 0;
        }
    }

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

   matrix_out:
   mac_pack 0:
      [a0]
      [a1]
      [b0]
      [b1]
   mac_pack 1:
      [a0]
      [a1]
      [d0]
      [d1]
   mac_pack 2:
      [c0]
      [c1]
      [b0]
      [b1]
   mac_pack 3:
      [c0]
      [c1]
      [d0]
      [d1]
*/
// output is array of mac packs
void make_matrix_mult_pack( square_matrix_t matrix_in[SEQ_VALUE_COUNT][2],
                                matrix_mult_pack_t matrix_out[SEQ_VALUE_COUNT]) {
    int value_idx, row, col, k;
    for (value_idx = 0; value_idx < SEQ_VALUE_COUNT; value_idx++) {
        for (row = 0; row < MATRIX_SIZE; row++) {
            for (col = 0; col < MATRIX_SIZE; col++) {
                int pack_idx = row * MATRIX_SIZE + col;
                for (k = 0; k < MATRIX_SIZE; k++) {
                    matrix_out[value_idx].pack[pack_idx].data[k] = matrix_in[value_idx][0].entry[row][k];
                    matrix_out[value_idx].pack[pack_idx].data[MATRIX_SIZE + k] = matrix_in[value_idx][1].entry[k][col];
                }
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
        printf("\t[");
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
        printf("\tPair %d:\n", idx);
        print_matrix_2d(pairs[idx]);
    }
}

void print_matrix_mult_pack(const matrix_mult_pack_t pack) {
    int row, col, data_idx;
    for (row = 0; row < MATRIX_SIZE; row++) {
        for (col = 0; col < MATRIX_SIZE; col++) {
            printf("\tMAC_Pack for output matrix element [%d][%d]:\n", row, col);
            printf("\t");
            for (data_idx = 0; data_idx < MATRIX_SIZE*2; data_idx++) {
                printf("%08x ", pack.pack[row*MATRIX_SIZE + col].data[data_idx]);
            }
            printf("\n");
        }
    }
}

void clear_matrix(square_matrix_t *matrix) {
    int row;
    int col;

    for (row = 0; row < MATRIX_SIZE; row++) {
        for (col = 0; col < MATRIX_SIZE; col++) {
            matrix->entry[row][col] = 0;
        }
    }
}

void package_cluster_outputs_into_matrix(
    const cluster_out_entry_t *output_array,
    int output_count,
    int start_output_idx,
    square_matrix_t *matrix_out)
{
    int output_idx;

    if (output_array == NULL || matrix_out == NULL) {
        return;
    }

    for (output_idx = 0; output_idx < output_count; output_idx++) {
        int linear_idx = start_output_idx + output_idx;
        int row = linear_idx / MATRIX_SIZE;
        int col = linear_idx % MATRIX_SIZE;

        if (linear_idx >= (MATRIX_SIZE * MATRIX_SIZE)) {
            break;
        }

        matrix_out->entry[row][col] = output_array[output_idx].out_entry[0];
    }
}

void print_single_matrix(const square_matrix_t *matrix) {
    int row;
    int col;

    if (matrix == NULL) {
        return;
    }

    for (row = 0; row < MATRIX_SIZE; row++) {
        printf("\t[");
        for (col = 0; col < MATRIX_SIZE; col++) {
            printf("%u", matrix->entry[row][col]);
            if (col < MATRIX_SIZE - 1) {
                printf(" ");
            }
        }
        printf("]\n");
    }
}

void print_result_matrix_set(const char *label, const square_matrix_t matrices[SEQ_VALUE_COUNT]) {
    int idx;

    printf("\n%s\n", label);
    for (idx = 0; idx < SEQ_VALUE_COUNT; idx++) {
        printf("\tPair %d:\n", idx);
        print_single_matrix(&matrices[idx]);
        printf("\n");
    }
}

// helper function for setting apb pointer
void *set_apb_pointer(void *virtual_base, unsigned long offset) {
    return virtual_base + ((unsigned long)(ALT_LWFPGASLVS_OFST + ERIC_IP2_0_BASE + offset) &
        (unsigned long)(HW_REGS_MASK));
}

static inline void write_apb_word(void *virtual_base, unsigned long offset, uint32_t value) {
    *(volatile uint32_t *)set_apb_pointer(virtual_base, offset) = value;
}

static inline uint32_t read_apb_word(void *virtual_base, unsigned long offset) {
    return *(volatile uint32_t *)set_apb_pointer(virtual_base, offset);
}

static inline uint32_t read_cluster_status(void *virtual_base) {
    return read_apb_word(virtual_base, STATUS_BASE);
}

int cluster_transaction(
    void *virtual_base,
    unsigned long data_base,
    int num_cores,
    const matrix_mult_pack_t *pack_array,
    int pack_count,
    int pack_index,
    int start_core_idx,
    cluster_out_entry_t *output_array)
{
    int core_idx;
    int word_idx;
    const matrix_mult_pack_t *selected_pack;

    if (virtual_base == NULL || pack_array == NULL || output_array == NULL) {
        return -1;
    }

    if (num_cores <= 0 || num_cores > (MATRIX_SIZE * MATRIX_SIZE)) {
        return -1;
    }

    if (pack_count <= 0 || pack_index < 0 || pack_index >= pack_count) {
        return -1;
    }

    if (start_core_idx < 0 || start_core_idx >= (MATRIX_SIZE * MATRIX_SIZE)) {
        return -1;
    }

    if ((start_core_idx + num_cores) > (MATRIX_SIZE * MATRIX_SIZE)) {
        return -1;
    }

    selected_pack = &pack_array[pack_index];
    
    write_apb_word(virtual_base, INSTRUCTION_BASE, INST_RESET);
    print_cluster_status(read_cluster_status(virtual_base));
    while (read_cluster_status(virtual_base) != STATUS_RESET);
    print_cluster_status(read_cluster_status(virtual_base));

    write_apb_word(virtual_base, INSTRUCTION_BASE, INST_SIGNAL_TX);
    while (read_cluster_status(virtual_base) != STATUS_READY_RX);
    print_cluster_status(read_cluster_status(virtual_base));

    // Write one mac_pack payload per core into consecutive APB words.
    for (core_idx = 0; core_idx < num_cores; core_idx++) {
        for (word_idx = 0; word_idx < (MATRIX_SIZE * 2); word_idx++) {
            unsigned long word_offset = data_base +
                (unsigned long)((core_idx * (MATRIX_SIZE * 2) + word_idx) * 4);
            write_apb_word(
                virtual_base,
                word_offset,
                selected_pack->pack[start_core_idx + core_idx].data[word_idx]);
        }
    }

    write_apb_word(virtual_base, INSTRUCTION_BASE, INST_TX_COMPLETE);

    while (read_cluster_status(virtual_base) != STATUS_DONE_TX);
    print_cluster_status(read_cluster_status(virtual_base));

    // Read one result word per core from consecutive APB words.
    for (core_idx = 0; core_idx < num_cores; core_idx++) {
        unsigned long word_offset = data_base + (unsigned long)(core_idx * 4);
        output_array[core_idx].out_entry[0] = read_apb_word(virtual_base, word_offset);
    }

    return 0;
}

int full_cluster_transaction(
    void *virtual_base,
    unsigned long data_base,
    int num_cores,
    const matrix_mult_pack_t *pack_array,
    int pack_count,
    cluster_out_entry_t output_array[][MATRIX_SIZE * MATRIX_SIZE],
    square_matrix_t matrix_output_array[])
{
    int pack_idx;
    int start_core_idx;
    int chunk_core_count;
    int completed_transactions;
    struct timespec start_time;
    struct timespec end_time;
    double elapsed_seconds;

    if (virtual_base == NULL || pack_array == NULL || output_array == NULL || matrix_output_array == NULL) {
        return -1;
    }

    if (pack_count <= 0) {
        return -1;
    }

    completed_transactions = 0;

    if (clock_gettime(CLOCK_MONOTONIC, &start_time) != 0) {
        return -1;
    }

    for (pack_idx = 0; pack_idx < pack_count; pack_idx++) {
        clear_matrix(&matrix_output_array[pack_idx]);

        for (start_core_idx = 0; start_core_idx < (MATRIX_SIZE * MATRIX_SIZE); start_core_idx += num_cores) {
            chunk_core_count = num_cores;
            if ((start_core_idx + chunk_core_count) > (MATRIX_SIZE * MATRIX_SIZE)) {
                chunk_core_count = (MATRIX_SIZE * MATRIX_SIZE) - start_core_idx;
            }

            if (cluster_transaction(
                    virtual_base,
                    data_base,
                    chunk_core_count,
                    pack_array,
                    pack_count,
                    pack_idx,
                    start_core_idx,
                    output_array[pack_idx]) != 0) {
                return -1;
            }

            completed_transactions++;

            package_cluster_outputs_into_matrix(
                output_array[pack_idx],
                chunk_core_count,
                start_core_idx,
                &matrix_output_array[pack_idx]);
        }
    }

    if (clock_gettime(CLOCK_MONOTONIC, &end_time) != 0) {
        return -1;
    }

    elapsed_seconds = (double)(end_time.tv_sec - start_time.tv_sec) +
        ((double)(end_time.tv_nsec - start_time.tv_nsec) / 1000000000.0);
    printf("\n\tcompleted transactions: %d\n", completed_transactions);
    printf("\n\tcompute time: %.6f seconds\n", elapsed_seconds);

    return 0;
}

int main() { 
 
   void *virtual_base; 
   int fd; 
   int ii,j;
   int mm_reg;
   int mem_data;
    volatile uint32_t *pio_led;
	volatile uint32_t *apb_32x16; // eric_ip2_0

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

	pio_led = (volatile uint32_t *)(virtual_base + ((unsigned long)(ALT_LWFPGASLVS_OFST + PIO_LED_BASE) & 
	    (unsigned long)(HW_REGS_MASK)));
	
	apb_32x16 = (volatile uint32_t *)(virtual_base + ((unsigned long)(ALT_LWFPGASLVS_OFST + ERIC_IP2_0_BASE) & 
         (unsigned long)(HW_REGS_MASK)));
         
    // Turn all LEDs off
    *pio_led = 0xFFF;
    usleep(100*5000); 
    *pio_led = 0x000; // Turn all LEDs on
    usleep(100*5000);  
    *pio_led = 0xFFF; // Turn all LEDs off

    // Test read and write to custom IP memory mapped registers
    // int test_data= 0x10101010;
    // for (ii = 0; ii < 64; ii+=4){
    //     mm_reg = ii;
	// 	apb_32x16 = (volatile uint32_t *)(virtual_base + ((unsigned long)(ALT_LWFPGASLVS_OFST + ERIC_IP2_0_BASE + mm_reg) &
    //         (unsigned long)(HW_REGS_MASK)));
	// 	printf("Writing test data: %x to memory address = %p\n", test_data, apb_32x16);
    //     *apb_32x16 = test_data;
    //     test_data += 0x10101010;
    // }

    // printf("Reading memory locations\n");
    // for (ii = 0; ii < 64; ii+=4){
    //     mm_reg = ii;
	// 	apb_32x16 = (volatile uint32_t *)(virtual_base + ((unsigned long)(ALT_LWFPGASLVS_OFST + ERIC_IP2_0_BASE + mm_reg) &
    //         (unsigned long)(HW_REGS_MASK)));
    //     mem_data = *apb_32x16;
    //     printf("Reading test data: %x from memory address = %p\n", mem_data, apb_32x16);
    // }
	
	// printf("\n");

    // Initialize matrices for benchmarking data generation
   square_matrix_t identity_matrix;
   square_matrix_t ones_row_matrix;
   square_matrix_t identity_matrix_data[SEQ_VALUE_COUNT][2];
   square_matrix_t ones_row_matrix_data[SEQ_VALUE_COUNT][2];
   matrix_mult_pack_t identity_matrix_mult_pack[SEQ_VALUE_COUNT];
   matrix_mult_pack_t ones_row_matrix_mult_pack[SEQ_VALUE_COUNT];
   cluster_out_entry_t output_array[MATRIX_SIZE*MATRIX_SIZE]; // one output entry per core
    cluster_out_entry_t full_output_array[SEQ_VALUE_COUNT][MATRIX_SIZE*MATRIX_SIZE];
    square_matrix_t full_result_matrices[SEQ_VALUE_COUNT];
   int idx;
   
   init_identity_matrix(&identity_matrix);
   init_ones_row_matrix(&ones_row_matrix);
   
   generate_sequential_data_with_identity(identity_matrix_data, &identity_matrix);
   generate_sequential_data_with_ones_row(ones_row_matrix_data, &ones_row_matrix);
  
   printf("Identity Matrix Data:\n");
   print_all_matrix_pairs(identity_matrix_data);
   printf("\n");
   
   printf("Ones Row Matrix Data:\n");
   print_all_matrix_pairs(ones_row_matrix_data);
   printf("\n");

   printf("Identity Matrix Mult Packs:\n");
   make_matrix_mult_pack(identity_matrix_data, identity_matrix_mult_pack);
    for (idx = 0; idx < SEQ_VALUE_COUNT; idx++) {
        printf("Matrix Multiplication %d packed data:\n", idx);
        print_matrix_mult_pack(identity_matrix_mult_pack[idx]);
        printf("\n");
    }
   
   printf("Ones Row Matrix Mult Packs:\n");
   make_matrix_mult_pack(ones_row_matrix_data, ones_row_matrix_mult_pack);
    for (idx = 0; idx < SEQ_VALUE_COUNT; idx++) {
        printf("\tPair %d packed data:\n", idx);
        print_matrix_mult_pack(ones_row_matrix_mult_pack[idx]);
        printf("\n");
    }

    //=============================================================== 

    /* Descriptions of how to package above transaction state sequences into functions for benchmarking.

    full_cluster_transaction(DATA_BASE, num_cores, matrix_mult_pack_t pack_array[size], size, cluster_out_entry_t output_array[size][MATRIX_SIZE*MATRIX_SIZE], square_matrix_t matrix_output_array[size]) 
        which handles looping all cluster_transaction calls for benchmarking
        calls cluster_transaction in a loop for benchmarking iterations and handles timing
        and logging of results
        - goal is to show that more cores is faster
        - create timing log files for each core count with timestamps and output results for analysis
        - packages raw core outputs back into full result matrices for readable verification

    cluster_transaction(DATA_BASE, num_cores, matrix_mult_pack_t pack_array[size], size, pack_index, start_core_idx, cluster_out_entry_t output_array[MATRIX_SIZE*MATRIX_SIZE])
        which handles one full transaction sequence of:
            - resetting the cluster and waiting for STATUS_RESET
            - signaling tx and waiting for STATUS_READY_RX
            - writing pack data to apb starting at start_core_idx
            - signaling tx complete
            - waiting for processing and tx complete
            - reading back results from apb into output array

    need a function to package the output of cluster transactions into matrices for printing and verification of results, 
    to show that the cluster is correctly performing matrix multiplication
    Pair 0:
    [0 0]
    [0 0]

    Pair 1:
    [1 1]
    [1 1]
    */

    printf("\nTesting full_cluster_transaction with sequential identity packs on 1 core:\n");
    if (full_cluster_transaction(
            virtual_base,
            DATA_BASE,
            1,
            identity_matrix_mult_pack,
            SEQ_VALUE_COUNT,
            full_output_array,
            full_result_matrices) != 0) {
        printf("full_cluster_transaction failed\n");
    }

    print_result_matrix_set("Identity full_cluster_transaction result matrices on 1 core:", full_result_matrices);

    //===============================================================

    printf("\n\nTesting full_cluster_transaction with sequential identity packs on 2 core:\n");
    if (full_cluster_transaction(
            virtual_base,
            DATA_BASE,
            2,
            identity_matrix_mult_pack,
            SEQ_VALUE_COUNT,
            full_output_array,
            full_result_matrices) != 0) {
        printf("full_cluster_transaction failed\n");
    }

    print_result_matrix_set("Identity full_cluster_transaction result matrices on 2 core:", full_result_matrices);
    
     printf("\n\nTesting full_cluster_transaction with sequential identity packs on 3 core:\n");
    if (full_cluster_transaction(
            virtual_base,
            DATA_BASE,
            3,
            identity_matrix_mult_pack,
            SEQ_VALUE_COUNT,
            full_output_array,
            full_result_matrices) != 0) {
        printf("full_cluster_transaction failed\n");
    }

    print_result_matrix_set("Identity full_cluster_transaction result matrices on 3 core:", full_result_matrices);

    // clean up our memory mapping and exit 
        if( munmap(virtual_base, HW_REGS_SPAN) != 0) { 
        printf("ERROR: munmap() failed...\n"); 
        close(fd); 
        return(1); 
    } 
    close(fd); 
    return(0); 
} 