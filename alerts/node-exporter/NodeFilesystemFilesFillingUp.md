# NodeFilesystemFilesFillingUp

## Meaning

This alert indicates that a filesystem is running out of available inodes (file entries) and is predicted to exhaust them:
- Warning: Predicted to run out of inodes within 24 hours and < 40% free
- Critical: Predicted to run out of inodes within 4 hours and < 20% free

## Impact

- Unable to create new files even with available disk space
- Application failures when attempting to create files
- Log rotation failures
- Package management issues

## Diagnosis

1. Check inode usage across filesystems:
```shell
df -i
```

2. Find directories with many small files:
```shell
for i in /*; do echo $i; find $i | wc -l; done
```

3. Identify file types consuming inodes:
```shell
find <mountpoint> -type f | file -f - | sort | uniq -c | sort -nr
```

4. Check for temporary file accumulation:
```shell
find /tmp -type f | wc -l
```

## Mitigation

1. Immediate actions:
   - Remove temporary and cache files
   - Clean package manager caches
   - Remove old log files

2. For container environments:
   - Clean up old container layers
   - Remove unused images and containers
   - Check for stuck builds creating temporary files

3. Long-term solutions:
   - Increase inode count during filesystem creation
   - Implement regular cleanup jobs
   - Monitor applications creating many small files
   - Consider using appropriate filesystem types

## Additional Notes

- Inode exhaustion can occur even with plenty of disk space
- Common with applications creating many small files
- Consider filesystem types (like XFS) that don't need pre-allocated inodes 