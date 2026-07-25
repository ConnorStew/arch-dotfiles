# Checking Disk Health

`smartd` is enabled by `system/tasks/smartd.yml` and pops a desktop notification
if anything changes, so this is for checking on demand.

## Commands

Health, attributes and error log, all disks:

```bash
for d in /dev/sd?; do echo "===== $d"; sudo smartctl -H -A -l error "$d"; done
```

Identify a disk (kernel names move between reboots):

```bash
sudo smartctl -i /dev/sdX          # model, serial, firmware
lsblk -o NAME,SIZE,MODEL,MOUNTPOINTS
```

Self-tests — non-destructive, run on the drive itself, safe to keep using the
machine:

```bash
sudo smartctl -t short /dev/sdX     # ~2 min
sudo smartctl -t long  /dev/sdX     # hours on a big HDD
sudo smartctl -l selftest /dev/sdX  # results
```

Errors the kernel already hit:

```bash
journalctl -k -p warning --no-pager | grep -iE 'I/O error|medium error|UNC|ata[0-9]'
```

## What failure looks like

**`PASSED` is not a clean bill of health.** It flips to FAILED only when a
Pre-fail attribute's normalised VALUE hits its THRESH — typically long after
real damage. A drive can have hundreds of dead blocks and thousands of failed
reads and still say PASSED. Read the attributes instead.

Non-zero in any of these means start planning a replacement:

| ID | Name | Meaning |
|----|------|---------|
| 5 | `Reallocated_Sector_Ct` | Sectors already remapped to spares |
| 197 | `Current_Pending_Sector` | Unreadable, waiting to be remapped |
| 198 | `Offline_Uncorrectable` | Unreadable and unrecoverable |
| 187 | `Reported_Uncorrect` / `Uncorrectable_Error_Cnt` | Reads the ECC could not recover — **data loss** |
| 199 | `UDMA_CRC_Error_Count` | Bad SATA cable, not a failing drive |

SSD wear — separate from failure, a drive can be damaged with barely any wear:

| ID | Name | Meaning |
|----|------|---------|
| 177 | `Wear_Leveling_Count` | Normalised: starts at 100, counts *down* |
| 241 | `Total_LBAs_Written` | Host writes, `raw × 512` bytes |