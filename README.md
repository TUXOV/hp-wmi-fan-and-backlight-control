## hp-wmi manual fan + keyboard RGB control

This is an Initial module for manual fan control and keyboard RGB for devices that support it. Single‑zone RGB works now; I plan to add 4‑zone but I need testers.

Please star the repo if this driver works for you. Thanks!

> [!NOTE]
> **HP Victus 15:** For some reason, HP didnt mark manual fan control supported on HP Victus 15 laptops, even though the hardware supports it. So by default manual fan control is not enabled in this module. But if you want to turn it on, load the module with the `force_fan_control_support=true` parameter.
>
> ```bash
> sudo insmod hp-wmi.ko force_fan_control_support=true
> ```

### GUI
There's a gui for this driver, it's not feature complete. I plan to rewrite it when i have free time but it should be enough for now. see [victus-control](https://github.com/Vilez0/victus-control)

### Installation:

Dkms:
```
git clone https://github.com/Vilez0/hp-wmi-fan-and-backlight-control
cd hp-wmi-fan-and-backlight-control
make
sudo make install-dkms
```

Arch package:
```
git clone https://github.com/Vilez0/hp-wmi-fan-and-backlight-control
cd hp-wmi-fan-and-backlight-control
make install-arch
```

or if you just want to test the module (not permanent):
```bash
git clone https://github.com/Vilez0/hp-wmi-fan-and-backlight-control
cd hp-wmi-fan-and-backlight-control/
make
sudo rmmod hp-wmi
sudo modprobe led_class_multicolor
sudo insmod hp-wmi.ko
```

### Usage 
- Keyboard (single‑zone RGB): control under `/sys/class/leds/hp::kbd_backlight`.
  - Use the multicolor interface attribute `multi_intensity` which accepts `R G B` (0–255 each).
  - Example:
    ```bash
    echo "255 0 0" | sudo tee /sys/class/leds/hp::kbd_backlight/multi_intensity # Set to red
    echo 128 | sudo tee /sys/class/leds/hp::kbd_backlight/brightness # Change brightness to 50% (0-255)
    ```

- Fans: control via `fanX_target` files (check fanX_max for the max values. Anything above the max values will return -EINVAL).
    ```bash
    echo 5500 | sudo tee /sys/devices/platform/hp-wmi/hwmon/hwmon*/fan1_target  # will set fan1 to 5500 rpm
    echo 5200 | sudo tee /sys/devices/platform/hp-wmi/hwmon/hwmon*/fan2_target # will set fan2 to 5200 rpm
    ```

- Fn+P Shortcut: On laptops that support it, the Fn+P shortcut for switching performance profiles should work OOTB. You can verify if its working by monitoring the `/sys/firmware/acpi/platform_profile` file.

### Tested on:
- Victus 16‑s1 (9Z791EA) — tested by me.
- I need testers to report which models it works on or not. see https://github.com/Vilez0/hp-wmi-fan-and-backlight-control/issues/1

### Disclaimer
USE IT AT YOUR OWN RISK. I DO NOT ACCEPT ANY RESPONSIBILITY.


