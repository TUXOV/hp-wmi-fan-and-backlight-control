## hp-wmi manual fan + keyboard RGB control

This module adds manual fan control and zoned keyboard RGB control for HP Omen/Victus laptops that support it.

It is based on the in-kernel `drivers/platform/x86/hp/hp-wmi.c` driver, rebased on the latest upstream version, and works on kernels both older and newer than 6.14.

Please star the repo if this driver works for you. Thanks!

### GUI
There's a gui for this driver. I plan to rewrite it when i have free time but it should be enough for now. see [victus-control](https://github.com/Vilez0/victus-control)

### Installation:

Dkms:
```
git clone https://github.com/TUXOV/hp-wmi-fan-and-backlight-control
cd hp-wmi-fan-and-backlight-control
make
sudo make install-dkms
```

Arch package:
```
git clone https://github.com/TUXOV/hp-wmi-fan-and-backlight-control
cd hp-wmi-fan-and-backlight-control
make install-arch
```

NixOS module:

In your system flake, add the repo as an input and enable the module:
```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    hp-wmi-control.url = "github:TUXOV/hp-wmi-fan-and-backlight-control"; # or a local path
  };
  outputs = { self, nixpkgs, hp-wmi-control, ... }: {
    nixosConfigurations.myhost = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        ./configuration.nix
        hp-wmi-control.nixosModules.default
        {
          hardware.hp-wmi-control = {
            enable = true;
            # victus-15-support.enable = true; # To add optional Victus 15 support
          };
        }
      ];
    };
  };
}
```

or if you just want to test the module (not permanent):
```bash
git clone https://github.com/TUXOV/hp-wmi-fan-and-backlight-control
cd hp-wmi-fan-and-backlight-control/
make
sudo rmmod hp-wmi
sudo modprobe led_class_multicolor
sudo insmod hp-wmi.ko
```

### Usage 
- Keyboard RGB (4-zone): each zone is exposed as a multicolor LED under `/sys/class/leds/`, named after the part of the keyboard it covers (per `Documentation/leds/leds-class.rst`). HP 4-zone keyboards light up the WASD keys plus three vertical thirds of the rest of the keyboard:
  - `/sys/class/leds/hp::kbd_zoned_backlight-left`
  - `/sys/class/leds/hp::kbd_zoned_backlight-center`
  - `/sys/class/leds/hp::kbd_zoned_backlight-right`
  - `/sys/class/leds/hp::kbd_zoned_backlight-wasd`
  - Use the multicolor interface attribute `multi_intensity` which accepts `R G B` (0–255 each).
  - Example:
    ```bash
    echo "255 0 0" | sudo tee /sys/class/leds/hp::kbd_zoned_backlight-left/multi_intensity # Set left zone to red
    echo 128 | sudo tee /sys/class/leds/hp::kbd_zoned_backlight-left/brightness # Change brightness to 50% (0-255)
    ```
  - Brightness changes made with the keyboard backlight hotkey (Fn+F4) are reported to userspace via the LED class `brightness_hw_changed` uevent.

- Keyboard RGB (single-zone): `/sys/class/leds/hp::kbd_backlight`, same `multi_intensity`/`brightness` attributes as above.

- Fans: standard hwmon interface via `pwmX_enable`, `pwmX` and `fanX_input` (see Documentation/ABI/testing/sysfs-class-hwmon):
    ```bash
    # switch fan1 to manual mode
    echo 1 | sudo tee /sys/devices/platform/hp-wmi/hwmon/hwmon*/pwm1_enable
    # set fan1 speed (0-255, maps linearly to 0-max rpm)
    echo 180 | sudo tee /sys/devices/platform/hp-wmi/hwmon/hwmon*/pwm1
    # read current fan1 speed in rpm
    cat /sys/devices/platform/hwmon/hwmon*/fan1_input
    # back to automatic mode
    echo 2 | sudo tee /sys/devices/platform/hp-wmi/hwmon/hwmon*/pwm1_enable
    ```
  `pwmX_enable` values: `2` = automatic, `1` = manual, `0` = max/full speed.
  The driver refreshes the firmware periodically so the EC does not reset manual fan mode.

- Fn+P Shortcut: On laptops that support it, the Fn+P shortcut for switching performance profiles should work OOTB. You can verify if its working by monitoring the `/sys/firmware/acpi/platform_profile` file.

### Tested on:
- Victus 16‑s1 (9Z791EA) — tested by me.
- I need testers to report which models it works on or not. see https://github.com/TUXOV/hp-wmi-fan-and-backlight-control/issues/1

### Disclaimer
USE IT AT YOUR OWN RISK. I DO NOT ACCEPT ANY RESPONSIBILITY.
