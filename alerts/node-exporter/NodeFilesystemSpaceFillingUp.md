# NodeFilesystemSpaceFillingUp

## Meaning

This alert indicates that a filesystem is running out of space and is predicted to be full within a specific timeframe:
- Warning: predicted to run out of space within 24 hours and current usage > 60%
- Critical: predicted to run out of space within 4 hours and current usage > 85%

## Impact

- Potential service disruptions when filesystem becomes full
- Degraded performance as filesystem utilization increases
- Applications may fail to write data or crash when no space is available
- System processes may fail to create temporary files

## Diagnosis

1. Identify the affected filesystem:
```shell
df -h | grep -v tmpfs
```

2. Check which directories are consuming the most space:
```shell
du -h --max-depth=1 <mountpoint> | sort -hr
```

3. Check for large files:
```shell
find <mountpoint> -type f -size +100M -exec ls -lh {} \;
```

4. Check for rapid growth patterns:
```shell
prometheus_query 'rate(node_filesystem_avail_bytes{instance="$instance",mountpoint="$mountpoint"}[1h])'
```

## Mitigation

1. Immediate actions:
   - Remove unnecessary files (logs, temporary files, old backups)
   - Clean package manager caches (e.g., `dnf clean all`)
   - Rotate and compress logs if needed

2. Long-term solutions:
   - Implement log rotation if not present
   - Consider filesystem expansion if available
   - Move data to a separate volume
   - Implement monitoring for directory sizes
   - Review application logging patterns

3. If using container platform:
   - Clean up unused images: `podman system prune` or `docker system prune`
   - Review persistent volume claims
   - Consider implementing quotas

## Additional Notes

- The alert uses linear prediction based on the last 6 hours of data
- False positives may occur with periodic cleanup jobs
- Consider reviewing filesystem sizing in capacity planning 