# NodeFilesystemFilesFillingUp

## Meaning

This alert indicates that a filesystem on an OpenShift worker node (RHCOS) is running out of available inodes (file entries) and is predicted to exhaust them:
- Warning: Predicted to run out of inodes within 24 hours and < 40% free
- Critical: Predicted to run out of inodes within 4 hours and < 20% free

## Impact

- Unable to create new files on the node even with available disk space
- Pod failures when attempting to create container files
- CRI-O failures when creating container runtime files
- Image pull failures
- OpenShift node health check failures

## Diagnosis

1. Identify the affected node from the alert labels:
```shell
oc get nodes <NODE_NAME> -o wide
```

2. Check inode usage on the node:
```shell
oc debug node/<NODE_NAME> -- chroot /host df -i
```

3. Examine system directories with many small files:
```shell
oc debug node/<NODE_NAME> -- chroot /host find /var/lib/containers -type d -exec sh -c 'echo $(find "$0" -type f | wc -l) "$0"' {} \; | sort -nr | head -n 10
```

4. Check for OpenShift-specific directories that might create many files:
```shell
oc debug node/<NODE_NAME> -- chroot /host find /var/lib/kubelet /var/lib/containers/storage -type d -exec sh -c 'echo $(find "$0" -type f | wc -l) "$0"' {} \; | sort -nr | head -n 10
```

5. Look for rapidly growing file directories:
```shell
oc debug node/<NODE_NAME> -- chroot /host find /var/log -maxdepth 2 -type d -exec sh -c 'echo $(find "$0" -type f | wc -l) "$0"' {} \; | sort -nr
```

## Mitigation

1. For container-related inode usage:
   - Remove container sandboxes:
   ```shell
   oc debug node/<NODE_NAME> -- chroot /host crictl rmp $(crictl pods -q --state NotReady)
   ```
   
   - Clean up old container images:
   ```shell
   oc debug node/<NODE_NAME> -- chroot /host crictl rmi --prune
   ```
   
   - Remove temporary container files:
   ```shell
   oc debug node/<NODE_NAME> -- chroot /host rm -rf /var/lib/containers/storage/tmp/*
   ```

2. For log file accumulation:
   - Clear old journal logs:
   ```shell
   oc debug node/<NODE_NAME> -- chroot /host journalctl --vacuum-files=50
   ```
   
   - Restart CRI-O to release held files:
   ```shell
   oc debug node/<NODE_NAME> -- chroot /host systemctl restart crio
   ```

3. For critical cases:
   - Cordon the node to prevent new pods:
   ```shell
   oc adm cordon <NODE_NAME>
   ```
   
   - Consider draining the node if excessive inode usage detected:
   ```shell
   oc adm drain <NODE_NAME> --ignore-daemonsets
   ```

4. Long-term solutions:
   - Modify MachineConfig to create filesystems with more inodes
   - Configure proper log rotation in the OpenShift logging stack
   - Implement regular image pruning policies
   - Use namespace quotas to limit excessive file creation

## Additional Notes

- RHCOS uses XFS as the default filesystem which has dynamic inode allocation
- Most inode issues occur in container storage and temporary directories
- The overlay2 storage driver used by CRI-O can create many small files
- Regular monitoring of inode usage should be part of cluster health checks
- Consider MachineConfig updates to adjust filesystem parameters for production workloads 