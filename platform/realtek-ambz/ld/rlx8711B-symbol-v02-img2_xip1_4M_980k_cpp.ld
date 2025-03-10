

ENTRY(Reset_Handler)

INCLUDE "export-rom_symbol_v01.txt"

GROUP (
  libgcc.a
  libc.a
  libg.a
  libm.a
  libnosys.a
)

MEMORY
{
	ROM (rx) : 			ORIGIN = 0x00000000, LENGTH = 0x80000	/* ROM: 512k */
	ROMBSS_RAM (rw)  : 		ORIGIN = 0x10000000, LENGTH = 0x2000	/* ROM BSS RAM: 8K */
	BOOTLOADER_RAM (rwx)  : 	ORIGIN = 0x10002000, LENGTH = 0x3000	/* BOOT Loader RAM: 12K */
	BD_RAM (rwx)  : 		ORIGIN = 0x10005000, LENGTH = 0x38000	/* MAIN RAM: 224k */
	ROM_BSS_RAM (rwx)  : 		ORIGIN = 0x1003D000, LENGTH = 0x1000	/* ROM BSS RAM: 4K */
	MSP_RAM (wx)  : 		ORIGIN = 0x1003E000, LENGTH = 0x1000	/* MSP RAM: 4k */
	RDP_RAM (wx)  : 		ORIGIN = 0x1003F000, LENGTH = 0xFF0	/* RDP RAM: 4k-0x10 */

	XIPBOOT (rx)  :			ORIGIN = 0x08000000+0x20, LENGTH = 0x04000-0x20	/* XIPBOOT: 16k, 32 Bytes resvd for header*/
	XIPSYS (r) :			ORIGIN = 0x08009000, LENGTH = 0x1000	/* XIPSYS: 4K system data in flash */
	XIPCAL (r) :			ORIGIN = 0x0800A000, LENGTH = 0x1000	/* XIPCAL: 4K calibration data in flash */
	XIP1 (rx)  : 			ORIGIN = 0x0800B000+0x20, LENGTH = 0xF5000-0x20	/* XIP1: 980k, 32 Bytes resvd for header */
	XIP2 (rx)  : 			ORIGIN = 0x08100000+0x20, LENGTH = 0xF5000-0x20	/* XIP2: 980k, 32 Bytes resvd for header */
}



SECTIONS
{
	.rom.text : { } > ROM
	.rom.rodata : { } > ROM
	.ARM.exidx :
	{
		__exidx_start = .;
	    *(.ARM.exidx*)
	    *(.gnu.linkonce.armexidx.*)
		__exidx_end = .;
	} > ROM
	.hal.rom.bss : { } > ROMBSS_RAM

	/* image1 entry, this section should in RAM and fixed address for ROM */
	.ram_image1.entry :
	{
		__ram_image1_text_start__ = .;
		__ram_start_table_start__ = .;
		KEEP(*(SORT(.image1.entry.data*)))
		__ram_start_table_end__ = .;

		__image1_validate_code__ = .;
		KEEP(*(.image1.validate.rodata*))
		KEEP(*(.image1.export.symb*))
	} > BOOTLOADER_RAM

	/*  Add . to assign the start address of the section */
	/*  to prevent the change of the start address by ld doing section alignment */
	.ram_image1.text . :
	{
		/* image1 text */
		*(.boot.ram.text*)
		*(.boot.rodata*)
	} > BOOTLOADER_RAM

	.ram_image1.data . :
	{
		__ram_image1_data_start__ = .;
		KEEP(*(.boot.ram.data*))
		__ram_image1_data_end__ = .;

		__ram_image1_text_end__ = .;
	} > BOOTLOADER_RAM

	.ram_image1.bss . :
	{
		__image1_bss_start__ = .;
		KEEP(*(.boot.ram.bss*))
		KEEP(*(.boot.ram.end.bss*))
		__image1_bss_end__ = .;
	} > BOOTLOADER_RAM

	.ram_image2.entry :
	{
		__ram_image2_text_start__ = .;
		__image2_entry_func__ = .;
		KEEP(*(SORT(.image2.entry.data*)))

		__image2_validate_code__ = .;
		KEEP(*(.image2.validate.rodata*))

	} > BD_RAM

	.ram_image2.text :
	{
	  KEEP(*(.image2.ram.text*))
	} > BD_RAM

	.ram_image2.data :
	{
		__data_start__ = .;
		*(.data*)
		__data_end__ = .;
		__ram_image2_text_end__ = .;
		. = ALIGN(16);
	} > BD_RAM

	.ram_image2.bss :
	{
		__bss_start__ = .;
		*(.bss*)
		*(COMMON)
	} > BD_RAM

	.ram_image2.skb.bss :
	{
		*(.bdsram.data*)
		__bss_end__ = .;
	} > BD_RAM

	.ram_heap.data :
	{
		*(.bfsram.data*)
	} > BD_RAM

	. = ALIGN(8);
	PROVIDE(heap_start    	  = .);
	PROVIDE(heap_end    	  = 0x1003CFFF);
	PROVIDE(heap_len    	  = heap_end - heap_start);

	.rom.bss :
	{
		*(.heap.stdlib*)
	} > ROM_BSS_RAM

	.ram_rdp.text :
	{
		__rom_top_4k_start_ = .;
		__rdp_text_start__ = .;
		KEEP(*(.rdp.ram.text*))
		KEEP(*(.rdp.ram.data*))
		__rdp_text_end__ = .;
		. = ALIGN(16);

	} > RDP_RAM

	.xip_image1.text :
	{
		__flash_boot_text_start__ = .;

		*(.flashboot.text*)

		__flash_boot_text_end__ = .;

		. = ALIGN(16);
	} > XIPBOOT

	.xip_image2.text :
	{
		__flash_text_start__ = .;

		*(.img2_custom_signature*)
		*(.text)
		*(.text*)
		*(.rodata)
		*(.rodata*)
		*(.debug_trace*)

		/* https://www.embedded.com/building-bare-metal-arm-systems-with-gnu-part-3/ */
		KEEP(*crtbegin.o(.ctors))
		KEEP(*(EXCLUDE_FILE (*ctrend.o) .ctors))
		KEEP(*(SORT(.ctors.*)))
		KEEP(*crtend.o(.ctors))
		KEEP(*crtbegin.o(.dtors))
		KEEP(*(EXCLUDE_FILE (*crtend.o) .dtors))
		KEEP(*(SORT(.dtors.*)))
		KEEP(*crtend.o(.dtors))
		*(.rodata .rodata.* .gnu.linkonce.r.*)

		/* Add This for C++ support */
		/* ambd_arduino/Arduino_package/hardware/variants/rtl8720dn_bw16/linker_scripts/gcc/rlx8721d_img2_is_arduino.ld */
		. = ALIGN(4);
		__preinit_array_start = .;
		KEEP(*(.preinit_array))
		__preinit_array_end = .;
		. = ALIGN(4);
		__init_array_start = .;
		KEEP(*(SORT(.init_array.*)))
		KEEP(*(.init_array))
		__init_array_end = .;
		. = ALIGN(4);
		__fini_array_start = .;
		KEEP(*(SORT(.fini_array.*)))
		KEEP(*(.fini_array))
		__fini_array_end = .;
		/*-----------------*/

		. = ALIGN (4);
		__cmd_table_start__ = .;
		KEEP(*(.cmd.table.data*))
		__cmd_table_end__ = .;

		/* https://community.silabs.com/s/article/understand-the-gnu-linker-script-of-cortex-m4?language=en_US */
		KEEP(*(.init))
		KEEP(*(.fini))
		*(.init)
		*(.fini)

		__flash_text_end__ = .;

		. = ALIGN (16);
	} > XIP1
}

SECTIONS
{
	/* Bootloader symbol list */
  boot_export_symbol = 0x10002020;
}
