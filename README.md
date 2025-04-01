![](https://img.shields.io/github/license/classy-giraffe/easy-arch?label=License)
![](https://img.shields.io/github/stars/stuxvii/easy-arch-traducido?label=Stars)
![](https://img.shields.io/github/forks/stuxvii/easy-arch-traducido?label=Forks)

[easy-arch](https://github.com/stuxvii/easy-arch-traducido) es un **script escrito en bash** que instala [Arch Linux](https://archlinux.org/) desde un medio de instalación, con ajustes determinados para ser prácticos y aptos para usos del mundo real.

- **Snapshots BTRFS**: Tendrás una configuración resistente que automáticamente tomara copias de seguridad de tus volumenes en una base semanal.
- **Cifrado LUKS2**: Tus datos se almacenaran en una particion cifrada con LUKS2.
- **ZRAM**: Se configurará el uso de ZRAM, el cual es una alternativa mucho mas optimizada a usar SWAP.
- **systemd-oomd**: systemd-oomd se hará cargo de situaciones tipo OOM (Out Of Memory, Fuera De Memoria traducido al español), a nivel de usuario, a cambio de a nivel de kernel, haciendo tu sistema menos vulnerable a crasheos repentinos.
- **Adiciones de Invitado VM**: Este script proveerá con integraciones de sistema invitado en el caso de que se detecte el uso de VMWare Workstation, VirtualBox, QEMU-KVM o Hyper-V.
- **Configuración del usuario**: Puede añadirse un usuario con permisos de administrador usando este script para evitar dificultad.
- **Revisiones de CI**: ShellChecker revisara cada PR periodicamente para corregir errores de ortografía en bash, practicas de programación ineficientes, etc... 

## Descargar el original en ingles

### `bash <(curl -sL bit.ly/easy-arch)`

## Descargar la versión traducida

```bash 
wget -O easy-arch.sh https://raw.githubusercontent.com/stuxvii/easy-arch-traducido/main/easy-arch.sh
chmod +x easy-arch.sh
bash easy-arch.sh
```

## Esquema de particiones

El **esquema de particiones** es simple y solo constituye de dos volumenes:
1. Una partición **FAT32** de 1GiB, montada en `/boot/` como ESP.
2. Un **volúmen encriptado LUKS2**, el cual ocupa el espacio restante, montado en `/` como root.

| Número de Partición | Nombre    | Tamaño            | Ubicación      | Formato                  |
|---------------------|-----------|-------------------|----------------|--------------------------|
| 1                   | ESP       | 1 GiB             | /boot/         | FAT32                    |
| 2                   | Cryptroot | Resto del disco   | /              | BTRFS encriptado (LUKS2) |

## Esquema de subvolúmenes BTRFS

El **Esquema de subvolúmenes BTRFS** obedece el esquema tradicional sugerido que utiliza **Snapper**, lo puedes encontrar [aquí](https://wiki.archlinux.org/index.php/Snapper#Suggested_filesystem_layout) (Enlace en Ingles).

| Número del Subvolúmen | Nombre del subvolúmen | Ubicación                     |
|-----------------------|-----------------------|-------------------------------|
| 1                     | @                     | /                             |
| 2                     | @home                 | /home                         |
| 3                     | @root                 | /root                         |
| 4                     | @srv                  | /srv                          |
| 5                     | @snapshots            | /.snapshots                   |
| 6                     | @var_log              | /var/log                      |
| 7                     | @var_pkgs             | /var/cache/pacman/pkg         |
