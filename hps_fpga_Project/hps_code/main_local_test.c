#include <stdio.h> 
#include <unistd.h> 
#include <fcntl.h>  
#include "hps_0.h" 
#include <stdint.h>

// Benchmarking parameters
#define BENCHMARK_ITERATIONS 1000
#define DATA_BYTES 4 // limit on int size for generation
#define MATRIX_SIZE 2
#define SEQ_VALUE_COUNT 2
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
    mac_pack_t pack[MATRIX_SIZE*MATRIX_SIZE]; // one pack per output element
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
                printf("%08x ", pack.pack[row*MATRIX_SIZE + col].data[data_idx]);
            }
            printf("\n");
        }
    }
}

int main() {   

   // Initialize matrices for benchmarking data generation
   square_matrix_t identity_matrix;
   square_matrix_t ones_row_matrix;
   square_matrix_t identity_matrix_data[SEQ_VALUE_COUNT][2];
   square_matrix_t ones_row_matrix_data[SEQ_VALUE_COUNT][2];
    matrix_mult_pack_t identity_matrix_mult_pack[SEQ_VALUE_COUNT];
    int idx;
   
   init_identity_matrix(&identity_matrix);
   init_ones_row_matrix(&ones_row_matrix);
   
   generate_sequential_data_with_identity(identity_matrix_data, &identity_matrix);
   generate_sequential_data_with_ones_row(ones_row_matrix_data, &ones_row_matrix);
  
   printf("Identity Matrix Data:\n");
   print_all_matrix_pairs(identity_matrix_data);
   
   printf("\n\n");
   
   printf("Ones Row Matrix Data:\n");
   print_all_matrix_pairs(ones_row_matrix_data);

   printf("\n\n");

   printf("Identity Matrix Mult Pack:\n");
   make_matrix_mult_pack(identity_matrix_data, identity_matrix_mult_pack);
    for (idx = 0; idx < SEQ_VALUE_COUNT; idx++) {
        printf("Pair %d packed data:\n", idx);
        print_matrix_mult_pack(identity_matrix_mult_pack[idx]);
        printf("\n");
    }

   // want to use single mac core first tests. 1 mac_pack at a time

   return(0); 
}