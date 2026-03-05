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
 
int main() { 
 
    void *virtual_base; 
    int fd; 
    //int loop_count; 
    //int led_direction; 
    //int led_mask; 
    //void *h2p_lw_led_addr; 
    //void *h2p_lw_coproc_addr;
	void *pio_fpga_inst;
	void *pio_fpga_status;
	void *h2p_lw_coproc_addr_memory;
     
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
    /* 
    h2p_lw_led_addr = virtual_base + ((unsigned long)(ALT_LWFPGASLVS_OFST + PIO_LED_BASE) & 
        (unsigned long)(HW_REGS_MASK)); 

    h2p_lw_coproc_addr = virtual_base + ((unsigned long)(ALT_LWFPGASLVS_OFST + COPROCESSOR_BASE) & 
        (unsigned long)(HW_REGS_MASK)); 
	*/	
	pio_fpga_inst = virtual_base + ((unsigned long)(ALT_LWFPGASLVS_OFST + PIO_FPGA_INST_BASE) & 
        (unsigned long)(HW_REGS_MASK)); 
		
	pio_fpga_status = virtual_base + ((unsigned long)(ALT_LWFPGASLVS_OFST + PIO_FPGA_STATUS_BASE) & 
        (unsigned long)(HW_REGS_MASK));
	
	h2p_lw_coproc_addr_memory = virtual_base + ((unsigned long)(ALT_LWFPGASLVS_OFST + MY_AES_IP_0_BASE) & 
        (unsigned long)(HW_REGS_MASK));
         
    /*/ toggle the LEDs a bit 
 
    loop_count = 0; 
    led_mask = 0x01; 
    led_direction = 0; // 0: left to right direction 
    printf("Starting while loop, base address: %p, virtual_base = %p\n", h2p_lw_led_addr, virtual_base); 
    while(loop_count < 2) { 
        printf("In Loop, loop_count:%d, led_mask:%d, led_direction:%d\n", loop_count, led_mask, led_direction); 
        // control led 
        *(uint32_t *)h2p_lw_led_addr = ~led_mask;  
 
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
	*/
    int mem_data, mm_reg, ii;
    

    for (ii = 0; ii < 16; ii = ii + 4){
        printf("Enter coprocessor memory data in hexadecimal, to write in location = %x\n", ii);
        mm_reg = ii;
        scanf("%x", &mem_data);
        h2p_lw_coproc_addr_memory = virtual_base + ((unsigned long)(ALT_LWFPGASLVS_OFST + MY_AES_IP_0_BASE + mm_reg) &
            (unsigned long)(HW_REGS_MASK));
        printf("Writing coprocessor memory address = %p\n", h2p_lw_coproc_addr_memory);
        *(uint32_t *)h2p_lw_coproc_addr_memory = mem_data;
    }

    printf("Reading memory locations\n");
    for (ii = 0; ii < 16; ii = ii + 4){
        mm_reg = ii;
        h2p_lw_coproc_addr_memory = virtual_base + ((unsigned long)(ALT_LWFPGASLVS_OFST + MY_AES_IP_0_BASE + mm_reg) &
            (unsigned long)(HW_REGS_MASK));
        printf("Reading coprocessor memory address = %p\n", h2p_lw_coproc_addr_memory);
        mem_data = *(uint32_t *)h2p_lw_coproc_addr_memory;
        printf("Memory data read: %x\n", mem_data);
    }

    // int instruction;
    // int rv;
    // while (true)
    // {
    //     printf("Enter Instruction\n> ");
    //     rv = scanf("%x", &instruction);
    //     if (rv != 1) // scanf returns number of items it converted, we expect it to convert 1 thing
    //     {
    //         printf("Exiting loop\n");
    //         break;
    //     }

    //     int operation = (instruction >> 16);
    //     int r1 = (instruction >> 8) & 0xFF;
    //     int r2 = (instruction & 0xFF);
    //     int result = 0xDEADBEEF;
    //     printf("Operation=%x, r1=%x, r2=%x\n", operation, r1, r2);
    //     switch (operation)
    //     {
    //     case 0b00: // and
    //         result = r1 & r2;
    //         break;
    //     case 0b01: // or
    //         result = r1 | r2;
    //         break;
    //     case 0b10: // xor
    //         result = r1 ^ r2;
    //         break;
    //     case 0b11: // xnor
    //         result = ~(r1 ^ r2);
    //         break;
    //     default:
    //         printf("We have an unknown instruction:%x\n", operation);
    //         break;
    //     }
    //     printf("result=%x\n", result);
    //     printf("Sending %x, as the instruction\n", instruction);
    //     *(uint32_t *)h2p_lw_coproc_addr = instruction;
    //     printf("Memory Address=%p, value=%x\n", h2p_lw_coproc_addr, *(uint32_t *)h2p_lw_coproc_addr);
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