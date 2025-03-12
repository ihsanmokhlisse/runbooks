# NodeFilesystemAlmostOutOfSpace

## Meaning

This alert indicates that a filesystem on an OpenShift worker node (RHCOS) has reached a critical threshold of available space:
- Warning: Less than 5% space available
- Critical: Less than 3% space available

## Impact

- Immediate risk of service disruption for pods on the affected worker node
- CRI-O runtime may fail to create new containers
- OpenShift deployments to the node may fail
- Container image pulls may fail
- Control plane functions may be impacted if the affected node is a master

## Diagnosis

1. Identify the affected node and filesystem from alert labels:
```shell
oc get nodes <NODE_NAME> -o wide
```

2. Examine filesystem usage on the node:
```shell
oc debug node/<NODE_NAME> -- chroot /host df -h | sort -k 5 -r | head -n 5
```

3. Inspect container storage usage:
```shell
oc debug node/<NODE_NAME> -- chroot /host du -h -d1 /var/lib/containers /var/lib/kubelet | sort -hr
```

4. Check for deleted but still-open files:
```shell
oc debug node/<NODE_NAME> -- chroot /host lsof | grep deleted
```

5. Check CRI-O storage status:
```shell
oc debug node/<NODE_NAME> -- chroot /host crictl info | grep -A8 storage
```

## Mitigation

1. Emergency actions:
   - Clean up container images on the node:
   ```shell
   oc debug node/<NODE_NAME> -- chroot /host crictl rmi --prune
   ```
   
   - Remove exited containers:
   ```shell
   oc debug node/<NODE_NAME> -- chroot /host crictl rm $(crictl ps -a -q --state exited)
   ```
   
   - Clean up systemd journal:
   ```shell
   oc debug node/<NODE_NAME> -- chroot /host journalctl --vacuum-size=100M
   ```

2. OpenShift-specific actions:
   - Cordon the node to prevent new workloads:
   ```shell
   oc adm cordon <NODE_NAME>
   ```
   
   - For non-critical workloads, consider evacuation:
   ```shell
   oc adm drain <NODE_NAME> --ignore-daemonsets --delete-emptydir-data
   ```
   
   - If necessary, restart CRI-O to release held deleted files:
   ```shell
   oc debug node/<NODE_NAME> -- chroot /host systemctl restart crio
   ```

3. Long-term remediation:
   - Implement proper image pruning in the cluster:
   ```shell
   oc adm prune images --keep-tag-revisions=3 --keep-younger-than=24h
   ```
   
   - Create a MachineConfig to expand filesystem partitions
   - Configure namespace resource quotas to prevent excessive storage usage
   - Implement image pull policies to prevent storing unused images

## Additional Notes

- RHCOS has an immutable filesystem design; most system directories cannot be modified at runtime
- The `/var` directory contains most runtime data and is the common location for space issues
- Automatic pruning of images via the ImagePruner custom resource is recommended
- Node cordoning may be necessary to prevent new pods until space is reclaimed
- Consider setting up the Cluster Resource Override Operator to limit PVC sizes 