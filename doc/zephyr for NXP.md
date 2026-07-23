
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

The CM7 image location in NOR Flash is determined by the linker script.

 1.  link script：linker.cmd



