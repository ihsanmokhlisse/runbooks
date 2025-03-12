# NodeFilesystemAlmostOutOfFiles

## Meaning

This alert indicates that a filesystem on an OpenShift worker node (RHCOS) is almost out of available inodes:
- Warning: Less than 5% inodes available
- Critical: Less than 3% inodes available

## Impact

- Immediate risk of node failure for file operations
- CRI-O container creation failures
- Pod deployment failures on the affected node
- Image pull failures
- OpenShift platform services disruption
- Node might become NotReady if critical filesystems are affected

## Diagnosis

1. Identify the affected node from the alert labels:
```shell
oc get nodes <NODE_NAME> -o wide
```

2. Check inode usage across all filesystems on the node:
```shell
oc debug node/<NODE_NAME> -- chroot /host df -i | sort -k5 -r
```

3. Determine which OpenShift component directories are consuming inodes:
```shell
oc debug node/<NODE_NAME> -- chroot /host find /var/lib/containers /var/lib/kubelet -type d -exec sh -c 'echo $(find "$0" -type f | wc -l) "$0"' {} \; | sort -nr | head -n 20
```

4. Check for excessive container ephemeral storage usage:
```shell
oc debug node/<NODE_NAME> -- chroot /host find /var/lib/containers/storage/overlay/ -type d -name "merged" -exec sh -c 'echo $(find "$0" -type f | wc -l) "$0"' {} \; | sort -nr | head
```

5. Look for pods creating excessive files:
```shell
oc get pods --all-namespaces -o wide | grep <NODE_NAME>
```

## Mitigation

1. Immediate actions:
   - Cordon the node to prevent new pods from being scheduled:
   ```shell
   oc adm cordon <NODE_NAME>
   ```
   
   - Clean up terminated container sandboxes:
   ```shell
   oc debug node/<NODE_NAME> -- chroot /host crictl rmp $(crictl pods -q --state NotReady)
   ```
   
   - Remove unused container images:
   ```shell
   oc debug node/<NODE_NAME> -- chroot /host crictl rmi --prune
   ```

2. Container runtime cleanup:
   - Restart CRI-O to clean up stale file handles:
   ```shell
   oc debug node/<NODE_NAME> -- chroot /host systemctl restart crio
   ```
   
   - Clean CRI-O temporary files:
   ```shell
   oc debug node/<NODE_NAME> -- chroot /host rm -rf /var/lib/containers/storage/tmp/*
   ```

3. For critical conditions:
   - Drain the node to relocate workloads:
   ```shell
   oc adm drain <NODE_NAME> --ignore-daemonsets --delete-emptydir-data
   ```
   
   - Consider restarting the node as a last resort:
   ```shell
   oc debug node/<NODE_NAME> -- chroot /host shutdown -r now
   ```

4. Long-term solution:
   - Apply a MachineConfig to modify filesystem parameters
   - Implement OpenShift ImagePruner to regularly clean images
   - Set appropriate resource quotas for namespaces
   - Consider using ephemeral volumes instead of emptyDir for temporary storage
   - Configure node selectors for file-intensive workloads

## Additional Notes

- This is a critical condition requiring immediate intervention
- RHCOS uses XFS for system partitions, which handles inodes dynamically
- The overlay2 storage driver used by CRI-O can create many small files
- Build processes often create many temporary files
- Consider using sidecar containers for log processing to reduce file accumulation 