# NodeFilesystemAlmostOutOfFiles

## Meaning

This alert indicates that a filesystem is almost out of available inodes:
- Warning: Less than 5% inodes available
- Critical: Less than 3% inodes available

## Impact

- Unable to create new files even with available disk space
- Application failures
- System service disruptions
- Log rotation failures
- Package management issues

## Diagnosis

1. Check inode usage across filesystems:
```shell
df -i
```

2. Identify the filesystem with low inode count:
```shell
df -i | sort -k 5 -r | head -n 5
```

3. Find directories with the most files:
```shell
find <mountpoint> -xdev -type d -exec sh -c 'echo $(find "$0" -maxdepth 1 -type f | wc -l) "$0"' {} \; | sort -nr | head -n 20
```

4. Identify file count by user:
```shell
find <mountpoint> -xdev -type f -printf "%u\n" | sort | uniq -c | sort -nr | head -n 10
```

## Mitigation

1. Immediate actions:
   - Remove temporary files: `find /tmp -type f -mtime +2 -delete`
   - Clean package caches: `dnf clean all` or `apt clean`
   - Remove unnecessary log files

2. User-specific actions:
   - Contact users with excessive file counts
   - Implement quota systems
   - Archive and compress old files

3. Long-term solutions:
   - Recreate filesystem with more inodes
   - Migrate to filesystems without fixed inode limits (like XFS)
   - Implement monitoring and alerts at lower thresholds
   - Create automated cleanup jobs

## Additional Notes

- This alert indicates an immediate problem, not just a prediction
- Similar to NodeFilesystemFilesFillingUp but requires more urgent action
- Different from space-based alerts - disk space may be plentiful
- Applications rarely check for inode availability before creating files 