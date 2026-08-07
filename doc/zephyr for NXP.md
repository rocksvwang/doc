
> **Abstract**  This document is applicable to the NXP RT118x platform.

# Kit Board

[FRDM-iMXRT1186 — Zephyr Project Documentation](https://docs.zephyrproject.org/latest/boards/nxp/frdm_imxrt1186/doc/index.html)

# Build VS-Code development environment

 [Working with Zephyr](https://mcuxpresso.nxp.com/mcux-vscode/latest/html/Working-with-Zephyr.html)
# Porject base line

![[Pasted image 20260723093642.png]]
# Debug

We need to support dual-core debugging, so we modified the configuration.

[lanunch.json](../NXP/launch.json)

The debugging steps are as follows:
**Step1：

![[Pasted image 20260723094542.png]]

**Step2

![[Pasted image 20260723095235.png|340]]

**Step3 ：Debug master core

![[Pasted image 20260723095923.png]]

**Step4： Debug second core

![[Pasted image 20260723100422.png]]


# Device-Tree

![[Pasted image 20260723102355.png]]




# CM7 core image loading flowchart

The CM33 core loads the CM7 image and then wakes up the CM7 core. The main implementation is located in soc.c.

 1. soc/nxp/imxrt/imxrt118x/soc.c
```c
#Segment 7 LMA sections
	
build/remote/zephyr/include/public/zephyr_image_info.h:7:#define SEGMENT_LMA_ADDRESS_0 0x4731c7c
build/remote/zephyr/include/public/zephyr_image_info.h:11:#define SEGMENT_LMA_ADDRESS_1 0x4720000
build/remote/zephyr/include/public/zephyr_image_info.h:15:#define SEGMENT_LMA_ADDRESS_2 0x4732ab0
build/remote/zephyr/include/public/zephyr_image_info.h:19:#define SEGMENT_LMA_ADDRESS_3 0x4740000
build/remote/zephyr/include/public/zephyr_image_info.h:23:#define SEGMENT_LMA_ADDRESS_4 0x4740ca8
build/remote/zephyr/include/public/zephyr_image_info.h:27:#define SEGMENT_LMA_ADDRESS_5 0x24720ca8
build/remote/zephyr/include/public/zephyr_image_info.h:31:#define SEGMENT_LMA_ADDRESS_6 0x4732aac
```

The CM7 image location in NOR Flash is determined by the linker script.

 1.  link script：linker.cmd

How to change LMA offset address of cm7 image ?

1. nxp,m7-partition = &slot1_partition;       /* in zephyr\boards\nxp\frdm_imxrt1186\frdm_imxrt1186_mimxrt1186_cm7.dts:26 

2. Key-Section
 ```shell
 
D:\RT1189\mbox\__repo__\zephyr\boards\nxp\mimxrt1180_evk\Kconfig.defconfig

# KEY section:
 
DT_CHOSEN_IMAGE_M7 = nxp,m7-partition

DT_CHOSEN_ZEPHYR_FLASH = zephyr,flash


# Only adjust LMA if running from RAM

if !CM7_BOOT_FROM_FLASH


# Adjust the offset of the output image if building for RT118x SOC in RAM

FLEXSPI_BASE := $(dt_nodelabel_reg_addr_hex,flexspi,1)

M7_CODE_BASE := $(dt_chosen_reg_addr_hex,$(DT_CHOSEN_ZEPHYR_FLASH))

IMAGE_M7_ADDR := $(dt_chosen_reg_addr_hex,$(DT_CHOSEN_IMAGE_M7))

  

config BUILD_OUTPUT_ADJUST_LMA

    default "($(IMAGE_M7_ADDR) + $(FLEXSPI_BASE) - $(M7_CODE_BASE))"
	  
 ```

3. The main conversion file is `CMakeLists.txt` in the Zephyr directory.
```

if(CONFIG_BUILD_OUTPUT_ADJUST_LMA)
  math(EXPR adjustment "${CONFIG_BUILD_OUTPUT_ADJUST_LMA}" OUTPUT_FORMAT DECIMAL)
  set(args_adjustment ${CONFIG_BUILD_OUTPUT_ADJUST_LMA_SECTIONS})
  list(TRANSFORM args_adjustment PREPEND $<TARGET_PROPERTY:bintools,elfconvert_flag_lma_adjust>)
  list(TRANSFORM args_adjustment APPEND +${adjustment})
  list(APPEND
    post_build_commands
    COMMAND $<TARGET_PROPERTY:bintools,elfconvert_command>
            $<TARGET_PROPERTY:bintools,elfconvert_flag_final>
            ${args_adjustment}
            $<TARGET_PROPERTY:bintools,elfconvert_flag_infile>${KERNEL_ELF_NAME}
            $<TARGET_PROPERTY:bintools,elfconvert_flag_outfile>${KERNEL_ELF_NAME}
    )
endif()
```

