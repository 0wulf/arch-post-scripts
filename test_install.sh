#!/bin/bash
set -e

source ./env.sh

trap "echo '[*] Shutting down VM' && virsh shutdown $VM_NAME" EXIT

wait_for_vm_ready() {
    vm_ip="$1"
    echo "[*] Waiting for the VM to be ready at $vm_ip..."
    while ! sshpass -p "arch" ssh -nq -o StrictHostKeyChecking=no arch@$vm_ip "exit"; do
        sleep 5
    done
}


if ! virsh list --all | grep -q "$VM_NAME" || ! virsh snapshot-list "$VM_NAME" | grep -q "$SNAPSHOT_NAME"; then
    echo "[*] The virtual machine $VM_NAME or the snapshot $SNAPSHOT_NAME does not exist. Creating a new one..."

    echo "[*] Cleaning/Creating virtual machine directory..."
    if [ ! -d "$VM_DIR" ]; then
        mkdir "$VM_DIR"
    else
        rm -rf "$VM_DIR/*"
    fi

    echo "[*] Downloading Arch Linux volume, signatures, and checksums..."
    curl -o "$VM_DIR/$ARCH_QCOW2_FILENAME"            "$ARCH_QCOW2_URL"
    curl -o "$VM_DIR/$ARCH_QCOW2_SIG_FILENAME"        "$ARCH_QCOW2_SIG_URL"
    curl -o "$VM_DIR/$ARCH_QCOW2_SHA256SUM_FILENAME"  "$ARCH_QCOW2_SHA256SUM_URL"

    echo "[*] Verifying volume signature..."
    gpg --keyserver-options auto-key-retrieve --verify "$VM_DIR/$ARCH_QCOW2_SIG_FILENAME" "$VM_DIR/$ARCH_QCOW2_FILENAME"


    echo "[*] Verifying checksums..."
    cd "$VM_DIR"
    sha256sum -c "$ARCH_QCOW2_SHA256SUM_FILENAME"
    cd -

    echo "[*] Creating testing virtual machine..."
    virt-install \
        --name "$VM_NAME" \
        --memory 2048 \
        --vcpus 2 \
        --disk path="$VM_DIR/$ARCH_QCOW2_FILENAME",format=qcow2,bus=virtio \
        --os-variant archlinux \
        --network network=default,model=virtio \
        --graphics spice \
        --video virtio \
        --virt-type kvm \
        --import \
        --noautoconsole

    sleep 15
    vm_ip=$(virsh domifaddr "$VM_NAME" | awk '/ipv4/ {print $4}' | cut -d'/' -f1)
    wait_for_vm_ready "$vm_ip"

    echo "[*] Configuring the virtual machine..."
    echo "[*] Configuring pacman keys..."
    sshpass -p "arch" ssh arch@"$vm_ip" "sudo pacman-key --init && sudo pacman-key --populate archlinux && sudo pacman-key --refresh-keys"

    echo "[*] Creating clean snapshot..."
    virsh snapshot-create-as "$VM_NAME" "$SNAPSHOT_NAME"

else
    echo "[*] The virtual machine $VM_NAME already exists."
        
    echo "[*] Starting the virtual machine..."
    virsh start "$VM_NAME"
    
    echo "[*] Rolling back to the clean snapshot..."
    virsh snapshot-revert "$VM_NAME" "$SNAPSHOT_NAME"

    vm_ip=$(virsh domifaddr "$VM_NAME" | awk '/ipv4/ {print $4}' | cut -d'/' -f1)
    echo "[*] The virtual machine is running at $vm_ip"
    wait_for_vm_ready "$vm_ip"
fi



echo "[*] Mounting the repository inside the VM..."
sshpass -p "arch" ssh arch@"$vm_ip" "if [ -d "./$REPO_NAME" ]; then
        rm -rf "./$REPO_NAME/*"
    fi"
sshpass -p "arch" scp -r "$REPO_DIR" arch@"$vm_ip":.

echo "[*] Running the script inside the VM..."
sshpass -p "arch" ssh arch@"$vm_ip" "cd $REPO_NAME && bash $INSTALL_SCRIPT"

echo "[*] Starting the graphical interface of the virtual machine..."
virt-viewer "$VM_NAME" &

echo "[*] Waiting for confirmation to rollback..."
read -p "Press Enter to rollback to the clean snapshot..."

echo "[*] Stopping the virtual machine..."
virsh shutdown "$VM_NAME"

echo "[*] Rolling back to the clean snapshot..."
virsh snapshot-revert "$VM_NAME" "$SNAPSHOT_NAME"

echo "[*] Testing completed."