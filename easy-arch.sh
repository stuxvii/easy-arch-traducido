#!/usr/bin/env -S bash -e

# Fixing annoying issue that breaks GitHub Actions
# shellcheck disable=SC2001

# Cleaning the TTY.
clear

# Cosmetics (colours for text).
BOLD='\e[1m'
BRED='\e[91m'
BBLUE='\e[34m'  
BGREEN='\e[92m'
BYELLOW='\e[93m'
RESET='\e[0m'

# Pretty print (function).
info_print () {
    echo -e "${BOLD}${BGREEN}[ ${BYELLOW}•${BGREEN} ] $1${RESET}"
}

# Pretty print for input (function).
input_print () {
    echo -ne "${BOLD}${BYELLOW}[ ${BGREEN}•${BYELLOW} ] $1${RESET}"
}

# Alert user of bad input (function).
error_print () {
    echo -e "${BOLD}${BRED}[ ${BBLUE}•${BRED} ] $1${RESET}"
}

# Virtualization check (function).
virt_check () {
    hypervisor=$(systemd-detect-virt)
    case $hypervisor in
        kvm )   info_print "KVM ha sido detectado, configurando adiciónes del invitado."
                pacstrap /mnt qemu-guest-agent &>/dev/null
                systemctl enable qemu-guest-agent --root=/mnt &>/dev/null
                ;;
        vmware  )   info_print "VMWare Workstation/ESXi ha sido detectado, configurando adiciónes del invitado."
                    pacstrap /mnt open-vm-tools >/dev/null
                    systemctl enable vmtoolsd --root=/mnt &>/dev/null
                    systemctl enable vmware-vmblock-fuse --root=/mnt &>/dev/null
                    ;;
        oracle )    info_print "VirtualBox ha sido detectado, configurando adiciónes del invitado."
                    pacstrap /mnt virtualbox-guest-utils &>/dev/null
                    systemctl enable vboxservice --root=/mnt &>/dev/null
                    ;;
        microsoft ) info_print "Hyper-V ha sido detectado, configurando adiciónes del invitado."
                    pacstrap /mnt hyperv &>/dev/null
                    systemctl enable hv_fcopy_daemon --root=/mnt &>/dev/null
                    systemctl enable hv_kvp_daemon --root=/mnt &>/dev/null
                    systemctl enable hv_vss_daemon --root=/mnt &>/dev/null
                    ;;
    esac
}

# Selecting a kernel to install (function).
kernel_selector () {
    info_print "Lista de kernels:"
    info_print "1) Estable: Kernel Linux vanilla con unos parches especificos de Arch Linux aplicados"
    info_print "2) Hardened: Un kernel de Linux enfocado en la seguridad"
    info_print "3) Largo-Plazo: Kernel de Linux con soporte a largo plazo (Long-Term Support LTS)"
    info_print "4) Kernel Zen: Un kernel de Linux optimizado para el uso habitual"
    info_print "Por favor, elija un kernel (e.g. 1): " 
    input_print ""
    read -r -e kernel_choice
    case $kernel_choice in
        1 ) kernel="linux"
            return 0;;
        2 ) kernel="linux-hardened"
            return 0;;
        3 ) kernel="linux-lts"
            return 0;;
        4 ) kernel="linux-zen"
            return 0;;
        * ) error_print "Elije una opcion valida, intenta otra vez."
            return 1
    esac
}

# Selecting a way to handle internet connection (function).
network_selector () {
    info_print "Utilidades de conexión:"
    info_print "1) IWD: Utilidad para conectarse a redes inalámbricas, escrito por Intel (Solo WiFi, con un cliente DHCP integrado)"
    info_print "2) NetworkManager: Utilidad de conexión universal (WiFi y Ethernet, recomendado)"
    info_print "3) wpa_supplicant: Utilidad con soporte para WEP y WPA/WPA2 (Solo WiFi, DHCPCD sera instalado automaticamente)"
    info_print "4) dhcpcd: Cliente DHCP basico (Conecciones por Ethernet o Maquinas virtuales)"
    info_print "5) Configurare esto por mi cuenta (Usuarios avanzados)"
    info_print "Por favor seleccione una opcion para su conexión. (e.g. 1): "
    input_print ""
    read -r -e network_choice
    if ! ((1 <= network_choice <= 5)); then
        error_print "Elije una opcion valida, intenta otra vez."
        return 1
    fi
    return 0
}

# Installing the chosen networking method to the system (function).
network_installer () {
    case $network_choice in
        1 ) info_print "Instalando y habilitando IWD."
            pacstrap /mnt iwd >/dev/null
            systemctl enable iwd --root=/mnt &>/dev/null
            ;;
        2 ) info_print "Instalando y habilitando NetworkManager."
            pacstrap /mnt networkmanager >/dev/null
            systemctl enable NetworkManager --root=/mnt &>/dev/null
            ;;
        3 ) info_print "Instalando y habilitando wpa_supplicant y dhcpcd."
            pacstrap /mnt wpa_supplicant dhcpcd >/dev/null
            systemctl enable wpa_supplicant --root=/mnt &>/dev/null
            systemctl enable dhcpcd --root=/mnt &>/dev/null
            ;;
        4 ) info_print "Instalando dhcpcd."
            pacstrap /mnt dhcpcd >/dev/null
            systemctl enable dhcpcd --root=/mnt &>/dev/null
    esac
}

# User enters a password for the LUKS Container (function).
lukspass_selector () {
    info_print "Por favor inserte una contraseña para encriptar tu disco con LUKS (Tu clave estara oculta para tu privacidad.): "
    input_print ""
    read -r -e -s password
    if [[ -z "$password" ]]; then
        echo
        error_print "Necesitas crear una contraseña para LUKS. Intenta de nuevo."
        return 1
    fi
    echo
    info_print "Confirmar tu contraseña de nuevo (Tu clave no se mostrara directamente para protejer tu privacidad.): "
    input_print ""
    read -r -e -s password2
    echo
    if [[ "$password" != "$password2" ]]; then
        error_print "Las contraseñas no coinciden. Intenta otra vez."
        return 1
    fi
    return 0
}

# Setting up a password for the user account (function).
userpass_selector () {
    info_print "Crea un nombre de usuario (Deja este campo vacio para no crear ningun usuario): "
    input_print ""
    read -r -e username
    if [[ -z "$username" ]]; then
        return 0
    fi
    info_print "Crea una contraseña para el usuario $username (Tu clave no se mostrara directamente para protejer tu privacidad.): "
    input_print ""
    read -r -e -s userpass
    if [[ -z "$userpass" ]]; then
        echo
        error_print "Necesitas insertar una contraseña para $username, please try again."
        return 1
    fi
    echo
    info_print "Por favor inserta la contraseña otra vez. (Tu clave no se mostrara directamente para protejer tu privacidad.): " 
    input_print ""
    read -r -e -s userpass2
    echo
    if [[ "$userpass" != "$userpass2" ]]; then
        echo
        error_print "Las claves no coinciden, intenta de nuevo."
        return 1
    fi
    return 0
}

# Setting up a password for the root account (function).
rootpass_selector () {
    info_print "Por favor crear una contraseña para el usuario root (Tu clave no se mostrara directamente para protejer tu privacidad.): "
    input_print ""
    read -r -e -s rootpass
    if [[ -z "$rootpass" ]]; then
        echo
        error_print "Necesitas crear una contraseña para el usuario root."
        return 1
    fi
    echo
    info_print "Por favor inserta la contraseña otra vez. (Tu clave no se mostrara directamente para protejer tu privacidad.): " 
    input_print ""
    read -r -e -s rootpass2
    echo
    if [[ "$rootpass" != "$rootpass2" ]]; then
        error_print "Las claves no coinciden, intenta de nuevo."
        return 1
    fi
    return 0
}

# Microcode detector (function).
microcode_detector () {
    CPU=$(grep vendor_id /proc/cpuinfo)
    if [[ "$CPU" == *"AuthenticAMD"* ]]; then
        info_print "Un CPU de AMD ha sido detectado, los parches microcode para AMD seran instalados."
        microcode="amd-ucode"
    else
        info_print "Un CPU de Intel ha sido detectado, los parches microcode para Intel seran instalados."
        microcode="intel-ucode"
    fi
}

# User enters a hostname (function).
hostname_selector () {
    info_print "Por favor, crea un nombre para tu maquina: "
    input_print ""
    read -r -e hostname
    if [[ -z "$hostname" ]]; then
        error_print "Necesitas crear un nombre para tu maquina."
        return 1
    fi
    return 0
}

# User chooses the locale (function).
locale_selector () {
    info_print "Por favor elije un lenguaje (formato: xx_XX. Deja esto vacio para seleccionar en_US (Inglés de Estados Unidos), o introduce \"/\" para buscar lenguajes): " locale
    input_print ""
    read -r -e locale
    case "$locale" in
        '') locale="en_US.UTF-8"
            info_print "$locale será el lenguaje predeterminado."
            return 0;;
        '/') sed -E '/^# +|^#$/d;s/^#| *$//g;s/ .*/ (Charset:&)/' /etc/locale.gen | less -M
                clear
                return 1;;
        *)  if ! grep -q "^#\?$(sed 's/[].*[]/\\&/g' <<< "$locale") " /etc/locale.gen; then
                error_print "El lenguaje que elegiste no existe o no es soportado. Elije otro, porfavor"
                return 1
            fi
            return 0
    esac
}

# User chooses the console keyboard layout (function).
keyboard_selector () {
    info_print "Por favor elije un lenguaje para tu teclado (Deja esto vacio para seleccionar US (Inglés de Estados Unidos), o introduce \"/\" para buscar lenguajes): "
    input_print ""
    read -r -e kblayout
    case "$kblayout" in
        '') kblayout="us"
            info_print "Configurando teclado en idioma Ingles."
            return 0;;
        '/') localectl list-keymaps
             clear
             return 1;;
        *) if ! localectl list-keymaps | grep -Fxq "$kblayout"; then
               error_print "El mapa de teclado especificado no existe. Intente otro."
               return 1
           fi
        info_print "Configurando el teclado para estar en idioma $kblayout."
        loadkeys "$kblayout"
        return 0
    esac
}

# Welcome screen.
echo -ne "${BOLD}${BYELLOW}
======================================================================
███████╗ █████╗ ███████╗██╗   ██╗      █████╗ ██████╗  ██████╗██╗  ██╗
██╔════╝██╔══██╗██╔════╝╚██╗ ██╔╝     ██╔══██╗██╔══██╗██╔════╝██║  ██║
█████╗  ███████║███████╗ ╚████╔╝█████╗███████║██████╔╝██║     ███████║ traducido por acidbox :p
██╔══╝  ██╔══██║╚════██║  ╚██╔╝ ╚════╝██╔══██║██╔══██╗██║     ██╔══██║ Proyecto original: https://github.com/classy-giraffe/easy-arch 
███████╗██║  ██║███████║   ██║        ██║  ██║██║  ██║╚██████╗██║  ██║
╚══════╝╚═╝  ╚═╝╚══════╝   ╚═╝        ╚═╝  ╚═╝╚═╝  ╚═╝ ╚═════╝╚═╝  ╚═╝
======================================================================
${RESET}"
info_print "Bienvenido a easy-arch, un script hecho para simplificar la instalacion de Arch Linux en equipos con soporte UEFI (2013+)."

# Setting up keyboard layout.
until keyboard_selector; do : ; done

# Choosing the target for the installation.
info_print "Discos disponibles para la instalación:"
PS3="Por favor seleccione una opción (SE SOBRE ESCRIBIRAN TODOS LOS CONTENIDOS DEL DISCO, Y SE PERDERA CUALQUIER DATO EN EL, ASEGURESE DE RESPALDAR TODO LO IMPORTANTE QUE TENGA!!) (e.g. 1): "
select ENTRY in $(lsblk -dpnoNAME|grep -P "/dev/sd|nvme|vd");
do
    DISK="$ENTRY"
    info_print "Arch Linux sera instalado en el disco: $DISK"
    break
done

# Setting up LUKS password.
until lukspass_selector; do : ; done

# Setting up the kernel.
until kernel_selector; do : ; done

# User choses the network.
until network_selector; do : ; done

# User choses the locale.
until locale_selector; do : ; done

# User choses the hostname.
until hostname_selector; do : ; done

# User sets up the user/root passwords.
until userpass_selector; do : ; done
until rootpass_selector; do : ; done

# Warn user about deletion of old partition scheme.
info_print "Se esta por eliminar la tabla de particiones en $DISK. Quieres continuar? (Y=SI, N=NO) (Ultima advertencia, elegir 'Y' borrara TODOS los datos en el disco) [y/N]?: "
input_print ""
read -r -e disk_response
if ! [[ "${disk_response,,}" =~ ^(yes|y)$ ]]; then
    error_print "Cerrando..."
    exit
fi
info_print "Formateando $DISK."
wipefs -af "$DISK" &>/dev/null
sgdisk -Zo "$DISK" &>/dev/null

# Creating a new partition scheme.
info_print "Creando particiones en $DISK."
parted -s "$DISK" \
    mklabel gpt \
    mkpart ESP fat32 1MiB 1025MiB \
    set 1 esp on \
    mkpart CRYPTROOT 1025MiB 100% \

ESP="/dev/disk/by-partlabel/ESP"
CRYPTROOT="/dev/disk/by-partlabel/CRYPTROOT"

# Informing the Kernel of the changes.
info_print "Informando al kernel de los cambios."
partprobe "$DISK"

# Formatting the ESP as FAT32.
info_print "Formateando la partición EFI como FAT32."
mkfs.fat -F 32 "$ESP" &>/dev/null

# Creating a LUKS Container for the root partition.
info_print "Creando contenedor LUKS para la partición root."
echo -n "$password" | cryptsetup luksFormat "$CRYPTROOT" -d - &>/dev/null
echo -n "$password" | cryptsetup open "$CRYPTROOT" cryptroot -d - 
BTRFS="/dev/mapper/cryptroot"

# Formatting the LUKS Container as BTRFS.
info_print "Formateando el contenenedor LUKS con tipo BTRFS."
mkfs.btrfs "$BTRFS" &>/dev/null
mount "$BTRFS" /mnt

# Creating BTRFS subvolumes.
info_print "Creando subvolumenes BTRFS."
subvols=(snapshots var_pkgs var_log home root srv)
for subvol in '' "${subvols[@]}"; do
    btrfs su cr /mnt/@"$subvol" &>/dev/null
done

# Mounting the newly created subvolumes.
umount /mnt
info_print "Montando subvolumenes recientementes creados."
mountopts="ssd,noatime,compress-force=zstd:3,discard=async"
mount -o "$mountopts",subvol=@ "$BTRFS" /mnt
mkdir -p /mnt/{home,root,srv,.snapshots,var/{log,cache/pacman/pkg},boot}
for subvol in "${subvols[@]:2}"; do
    mount -o "$mountopts",subvol=@"$subvol" "$BTRFS" /mnt/"${subvol//_//}"
done
chmod 750 /mnt/root
mount -o "$mountopts",subvol=@snapshots "$BTRFS" /mnt/.snapshots
mount -o "$mountopts",subvol=@var_pkgs "$BTRFS" /mnt/var/cache/pacman/pkg
chattr +C /mnt/var/log
mount "$ESP" /mnt/boot/

# Checking the microcode to install.
microcode_detector

# Pacstrap (setting up a base sytem onto the new root).
info_print "Instalando el sistema base (Tomara un largo rato, ve a preparate una taza de té.)."
pacstrap -K /mnt base "$kernel" "$microcode" linux-firmware "$kernel"-headers btrfs-progs grub grub-btrfs rsync efibootmgr lightdm lightdm-slick-greeter plasma-desktop snapper reflector snap-pac zram-generator sudo &>/dev/null

# Setting up the hostname.
echo "$hostname" > /mnt/etc/hostname

# Generating /etc/fstab.
info_print "Generando el fstab."
genfstab -U /mnt >> /mnt/etc/fstab

# Configure selected locale and console keymap
sed -i "/^#$locale/s/^#//" /mnt/etc/locale.gen
echo "LANG=$locale" > /mnt/etc/locale.conf
echo "KEYMAP=$kblayout" > /mnt/etc/vconsole.conf

# Setting hosts file.
info_print "Modificando nombre de equipo."
cat > /mnt/etc/hosts <<EOF
127.0.0.1   localhost
::1         localhost
127.0.1.1   $hostname.localdomain   $hostname
EOF

# Virtualization check.
virt_check

# Setting up the network.
network_installer

# Configuring /etc/mkinitcpio.conf.
info_print "Configurando /etc/mkinitcpio.conf."
cat > /mnt/etc/mkinitcpio.conf <<EOF
HOOKS=(systemd autodetect keyboard sd-vconsole modconf block sd-encrypt filesystems)
EOF

# Setting up LUKS2 encryption in grub.
info_print "Configurando la configuración en grub."
UUID=$(blkid -s UUID -o value $CRYPTROOT)
sed -i "\,^GRUB_CMDLINE_LINUX=\"\",s,\",&rd.luks.name=$UUID=cryptroot root=$BTRFS," /mnt/etc/default/grub

# Configuring the system.
info_print "Configurando el sistema (timezone, system clock, initramfs, Snapper, GRUB)."
arch-chroot /mnt /bin/bash -e <<EOF

    # Setting up timezone.
    ln -sf /usr/share/zoneinfo/$(curl -s http://ip-api.com/line?fields=timezone) /etc/localtime &>/dev/null

    # Setting up clock.
    hwclock --systohc

    # Generating locales.
    locale-gen &>/dev/null

    # Generating a new initramfs.
    mkinitcpio -P &>/dev/null

    # Snapper configuration.
    umount /.snapshots
    rm -r /.snapshots
    snapper --no-dbus -c root create-config /
    btrfs subvolume delete /.snapshots &>/dev/null
    mkdir /.snapshots
    mount -a &>/dev/null
    chmod 750 /.snapshots

    # Installing GRUB.
    grub-install --target=x86_64-efi --efi-directory=/boot/ --bootloader-id=GRUB &>/dev/null

    # Creating grub config file.
    grub-mkconfig -o /boot/grub/grub.cfg &>/dev/null

EOF

# Setting root password.
info_print "Configurando contraseña root."
echo "root:$rootpass" | arch-chroot /mnt chpasswd

# Setting user password.
if [[ -n "$username" ]]; then
    echo "%wheel ALL=(ALL:ALL) ALL" > /mnt/etc/sudoers.d/wheel
    info_print "Añadiendo el usuario $username al sistema con permisos de administrador."
    arch-chroot /mnt useradd -m -G wheel -s /bin/bash "$username"
    info_print "Configurando contraseña para $username."
    echo "$username:$userpass" | arch-chroot /mnt chpasswd
fi

# Boot backup hook.
info_print "Configurando respaldo en /boot para cuando las transacciones de pacman se realizan."
mkdir /mnt/etc/pacman.d/hooks
cat > /mnt/etc/pacman.d/hooks/50-bootbackup.hook <<EOF
[Trigger]
Operation = Upgrade
Operation = Install
Operation = Remove
Type = Path
Target = usr/lib/modules/*/vmlinuz

[Action]
Depends = rsync
Description = Backing up /boot...
When = PostTransaction
Exec = /usr/bin/rsync -a --delete /boot /.bootbackup
EOF

# ZRAM configuration.
info_print "Configurando ZRAM."
cat > /mnt/etc/systemd/zram-generator.conf <<EOF
[zram0]
zram-size = min(ram, 8192)
EOF

# Pacman eye-candy features.
info_print "Habilitando colores, animaciones, y descargas paralelas para pacman."
sed -Ei 's/^#(Color)$/\1\nILoveCandy/;s/^#(ParallelDownloads).*/\1 = 10/' /mnt/etc/pacman.conf

# Enabling various services.
info_print "Habilitando Reflector, snapshots del sistema automaticos, scrubbing BTRFS y systemd-oomd."
services=(reflector.timer snapper-timeline.timer snapper-cleanup.timer btrfs-scrub@-.timer btrfs-scrub@home.timer btrfs-scrub@var-log.timer btrfs-scrub@\\x2esnapshots.timer grub-btrfsd.service systemd-oomd)
for service in "${services[@]}"; do
    systemctl enable "$service" --root=/mnt &>/dev/null
done

# Finishing up. 
info_print "Terminado sin errores! Puedes proceder a tu nuevo sistema Arch Linux desconectando tu medio de instalación y reiniciando. (Puedes realizar mas cambios en este entorno si lo deseas, no hay apuro.)"

exit
