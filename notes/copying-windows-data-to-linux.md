# Mounting the Windows drive

This mounts the drive as readonly.
```shell
sudo mkdir /mnt/win
sudo mount -t ntfs3 -o ro,uid=1000,gid=1000,umask=0022 /dev/sd* /mnt/win
sudo umount /mnt/win
```