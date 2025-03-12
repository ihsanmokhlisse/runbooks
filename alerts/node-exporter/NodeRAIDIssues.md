# Node RAID Issues (NodeRAIDDegraded and NodeRAIDDiskFailure)

## Meaning

These alerts indicate problems with RAID arrays:
- NodeRAIDDegraded: RAID array is in degraded state
- NodeRAIDDiskFailure: One or more disks in RAID array have failed

## Impact

- Reduced redundancy
- Potential data loss risk
- Degraded I/O performance
- System vulnerability to additional failures

## Diagnosis

1. Check RAID status:
```shell
cat /proc/mdstat
mdadm --detail /dev/md*
```

2. Identify failed disks:
```shell
mdadm --examine /dev/sd*
```

3. Check disk health:
```shell
smartctl -a /dev/sd*
```

## Mitigation

1. Immediate actions:
   - Identify failed disk
   - Check for hot spare activation
   - Monitor rebuild progress

2. Hardware replacement:
   - Replace failed disks
   - Verify disk compatibility
   - Update firmware if needed

3. Recovery steps:
   - Add new disk to array
   - Monitor rebuild process
   - Verify array health

## Additional Notes

- Keep spare disks available
- Regular RAID health checks
- Document array configurations
- Monitor rebuild times 