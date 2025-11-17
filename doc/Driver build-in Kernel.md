
# GPIO-PWM Kconfig

```
config PWM_GPIO
    tristate "PWM GPIO support"
    depends on GPIOLIB
    help
      Say Y here to enable support for PWM output via GPIO toggling.

      This is a software-emulated PWM using GPIO. Useful for simple devices
      without hardware PWM.

      To compile this driver as a module, choose M here: the module
      will be called pwm-gpio.
```
	
# GPIO-PWM Makefile

```
obj-$(CONFIG_PWM_GPIO) += pwm-gpio.o
```


# edac Kconfig

```
config EDAC_PHYTIUM_MM
    tristate "Phytium MM memory controller EDAC support"
    depends on EDAC && ARM64
    help
      Support for ECC error detection on Phytium memory controller.

      If unsure, say N.
    
```

# edac Makefile


```
obj-$(CONFIG_EDAC_PHYTIUM_MM) += phytium_mm_edac.o
```
