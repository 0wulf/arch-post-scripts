# Arch Post Scripts

This repository contains scripts to automate the post-installation configuration of an Arch Linux environment.

## Project Structure

- `env.sh`: Contains environment variables necessary for script execution.
- `install.sh`: Main script for module installation.
- `test_install.sh`: Script to test installation in a virtual machine.
- `config/`: Directory for configuration dotfiles.
- `install.d/`: Contains installation modules organized by example categories:
  - `00-base.sh`: Base configuration.
  - `01-user.sh`: User configuration.
  - `10-network.sh`: Network configuration.
  - `20-wm.sh`: Window manager configuration.
  - `30-terminal.sh`: Terminal configuration.
  - `40-editor.sh`: Editor configuration.
  - `50-apps.sh`: Application installation.
  - `90-services.sh`: Service configuration.
  - `99-post.sh`: Post-installation tasks.

## Execution

1. Clone the repository:
   ```bash
   git clone <repository-URL>
   cd dotfiles
   ```

2. Run the installation script inside the machine to be installed:
   ```bash
   bash install.sh
   ```

3. To test the installation in a development machine, run:
   ```bash
   sudo bash test_install.sh
   ```

## Testing

The `test_install.sh` script performs the following actions:
- Verifies the existence of the virtual machine and its snapshot.
- Creates a new virtual machine if it does not exist.
- Waits for the virtual machine to be ready for testing.

Before starting, make sure to have the following packages installed:

```bash
sudo pacman -Syu
sudo pacman -S qemu libvirt virt-manager virt-install virt-viewer dnsmasq edk2-ovmf sshpass
sudo systemctl enable --now libvirtd
```

and modify `env.sh` to use the directory where you want to store the VM volume.

## Considerations

- If you cannot find the `tun` device, restart the system after updating the kernel.

## Improvements

- Use `sudo` only for necessary operations.
- Python testing script for greater robustness.