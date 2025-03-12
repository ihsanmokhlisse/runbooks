# NodeFilesystemAlmostOutOfSpace

## Meaning

This alert indicates that a filesystem has reached a critical threshold of available space:
- Warning: Less than 5% space available
- Critical: Less than 3% space available

## Impact

- Immediate risk of service disruption
- Applications may fail to write new data
- System services may become unstable
- Database operations might fail

## Diagnosis

1. Identify the critical filesystem:
```shell
df -h | sort -k 5 -r | head -n 5
```

2. List largest files and directories:
```shell
ncdu <mountpoint>
# or
du -ah <mountpoint> | sort -hr | head -n 20
```

3. Check for deleted but open files:
```shell
lsof | grep deleted
```

4. Identify processes writing large amounts of data:
```shell
iostat -p ALL 1
```

## Mitigation

1. Emergency actions:
   - Clear known safe caches: `rm -rf /var/cache/*`
   - Remove old log files: `find /var/log -type f -mtime +30 -delete`
   - Clear temporary files: `rm -rf /tmp/*`
   - Restart services holding deleted files

2. If running containers:
   - Remove unused containers: `podman rm $(podman ps -aq)`
   - Remove unused images: `podman rmi $(podman images -aq)`
   - Clean build cache: `podman builder prune`

3. Long-term remediation:
   - Implement automated cleanup jobs
   - Add monitoring for specific directories
   - Review application logging patterns
   - Consider filesystem expansion

## Additional Notes

- This is a more severe condition than NodeFilesystemSpaceFillingUp
- Requires immediate attention to prevent service disruption
- Consider setting up automated cleanup procedures to prevent recurrence 