[English](README.md) | [Русский](README.ru.md)

# gigactl-noctalia-plugin

A plugin for [Noctalia Shell](https://github.com/noctalia-dev/noctalia-shell) that allows you to control cooling profiles and fan speeds on Gigabyte laptops using the [gigactl](https://github.com/smairio/gigactl) utility.

## Features

- Switch between cooling profiles:
  - **Quiet** — quiet operation.
  - **Balanced** — balanced operation.
  - **Performance** — high-performance mode.
  - **MAX** — maximum cooling.
- Manual fan speed control in **Manual** mode.

## Dependencies

### gigactl — required dependency

The plugin requires the **gigactl** utility to be installed separately.

- Repository: [https://github.com/smairio/gigactl](https://github.com/smairio/gigactl)
- The gigactl daemon must be installed and running.
- The system D-Bus service must be available.

The plugin does not control the fans directly. All hardware control operations are handled by gigactl.

**You must install and configure gigactl before installing this plugin.**

### Noctalia Shell

- Noctalia Shell 5.5.0 or later.
- Plugin API 43.

## Usage

1. Install and configure [gigactl](https://github.com/smairio/gigactl).
2. Add the gigactl-noctalia-plugin to Noctalia Shell using this repository's URL.
3. Add the gigactl widget to your panel.

## Acknowledgements

Special thanks to [smairio](https://github.com/smairio) for creating **gigactl**, a utility that provides fan control, cooling profile management, and keyboard backlight control on Gigabyte laptops.

This plugin is an independent integration of gigactl with Noctalia Shell.

## Supported Devices

This plugin is intended for Gigabyte laptops based on the Clevo platform that are supported by [gigactl](https://github.com/smairio/gigactl).

Plugin compatibility depends directly on whether the installed version of gigactl supports the hardware.

**Check the list of supported devices before installing:**

[gigactl — Supported Hardware](https://github.com/smairio/gigactl#supported-hardware)

Pay attention to the device compatibility statuses:

- **Verified** — tested and verified by the gigactl author.
- **Reported working** — reported to be working by users.
- **Expected to work** — expected to be compatible, but not yet tested in practice.

Installation and operation on unsupported hardware are not guaranteed.

## License

This project is distributed under the [MIT License](LICENSE).
