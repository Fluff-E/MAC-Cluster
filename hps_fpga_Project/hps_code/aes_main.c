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
#define INST_SIGNAL_LOAD_KEY 0x00000001
#define INST_LOADING_KEY 0x00000003
#define INST_LOADING_DATA 0x00000005
#define INST_START_ENCRYPTION 0x00000009

#define STATUS_RESET 0X00000000
#define STATUS_LOAD_KEY 0x00000003
#define STATUS_LOAD_DATA 0x00000005
#define STATUS_ENCRYPTING 0x00000009
#define STATUS_DONE 0x0000000F

// Definitions of apb offsets
#define INSTRUCTION_BASE 0x00000000
#define STATUS_BASE 0x00000004
#define AES_KEY_BASE 0x00000008 // 128 bit key, 4 32-bit words
#define AES_PTEXT_BASE 0x00000018 // Plain Text 128 bit data, 4 32-bit words
#define AES_CTEXT_BASE 0x00000028 // Cipher Text 128 bit data, 4 32-bit words

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
    *(uint32_t *)pio_led = 0xFF;
    usleep(100*5000); 
    *(uint32_t *)pio_led = 0x00; // Turn all LEDs on
    usleep(100*5000);  
    *(uint32_t *)pio_led = 0xFF; // Turn all LEDs off

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

    // State machine test for AES coprocessor
    // Main loop
    while(1){
        // set instruction to reset, wait acknowledge
        apb_32x16 = set_apb_pointer(virtual_base, INSTRUCTION_BASE);
        *(uint32_t *)apb_32x16 = INST_RESET;
        apb_32x16 = set_apb_pointer(virtual_base, STATUS_BASE);
        while(*(uint32_t *)apb_32x16 != STATUS_RESET);
        printf("Coprocessor is in reset state\n");

        // set instruction to signal load aes key, wait acknowledge
        apb_32x16 = set_apb_pointer(virtual_base, INSTRUCTION_BASE);
        *(uint32_t *)apb_32x16 = INST_SIGNAL_LOAD_KEY;
        apb_32x16 = set_apb_pointer(virtual_base, STATUS_BASE);
        while(*(uint32_t *)apb_32x16 != STATUS_LOAD_KEY);
        printf("Coprocessor is ready to load key\n");

        for (ii = 0, most_sig_bit = 31, least_sig_bit = 0; ii < 16; ii += 4, most_sig_bit += 32, least_sig_bit += 32){
            printf("Enter aes key[%d:%d] in hexadecimal, to write in location = %x\n", most_sig_bit, least_sig_bit, AES_KEY_BASE + ii);
            scanf("%x", &mem_data);
            apb_32x16 = set_apb_pointer(virtual_base, AES_KEY_BASE + ii);
            *(uint32_t *)apb_32x16 = mem_data;
        }

        // set instruction to load data, wait acknowledge
        apb_32x16 = set_apb_pointer(virtual_base, INSTRUCTION_BASE);
        *(uint32_t *)apb_32x16 = INST_LOADING_DATA;
        apb_32x16 = set_apb_pointer(virtual_base, STATUS_BASE);
        while(*(uint32_t *)apb_32x16 != STATUS_LOAD_DATA);
        printf("Coprocessor is ready to load data\n");

        for (ii = 0, most_sig_bit = 31, least_sig_bit = 0; ii < 16; ii += 4, most_sig_bit += 32, least_sig_bit += 32){
            printf("Enter aes data[%d:%d] in hexadecimal, to write in location = %x\n", most_sig_bit, least_sig_bit, AES_PTEXT_BASE + ii);
            scanf("%x", &mem_data);
            apb_32x16 = set_apb_pointer(virtual_base, AES_PTEXT_BASE + ii);
            *(uint32_t *)apb_32x16 = mem_data;
        }

        // set instruction to start encryption, wait acknowledge
		printf("Changing instruction to encrypt.");
        apb_32x16 = set_apb_pointer(virtual_base, INSTRUCTION_BASE);
        *(uint32_t *)apb_32x16 = INST_START_ENCRYPTION;
        apb_32x16 = set_apb_pointer(virtual_base, STATUS_BASE);
		
        //while(*(uint32_t *)apb_32x16 != STATUS_ENCRYPTING);
        printf("Coprocessor has started encryption\n");
        while(*(uint32_t *)apb_32x16 != STATUS_DONE);
        printf("Coprocessor has completed encryption\n");

        printf("Reading encrypted data locations\n");
        for (j = 0, ii = 0; ii < 16; ii += 4, j++){
            apb_32x16 = set_apb_pointer(virtual_base, AES_CTEXT_BASE + ii);
            mem_data = *(uint32_t *)apb_32x16;
            aes_data[j] = mem_data;
            printf("Memory data read [%x]: %08x\n", AES_CTEXT_BASE + ii, mem_data);
        }

        // Print 128-bit encrypted value MSW first
        printf("Encrypted data is:\n");
        for (j = 3; j >= 0; j--){
            printf("%08x ", aes_data[j]);
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