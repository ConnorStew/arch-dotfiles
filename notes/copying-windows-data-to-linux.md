# Mounting the Windows drive

Get your disk info:
```shell
lsblk -o NAME,SIZE,MODEL,MOUNTPOINTS,LABEL
```

Mounts the drive as readonly:
```shell
sudo mkdir -p /mnt/win
sudo mount -t ntfs3 -o ro,uid=1000,gid=1000,umask=0022 /dev/sd** /mnt/win
```

Unmount the drive:
```shell
sudo umount /mnt/win
```