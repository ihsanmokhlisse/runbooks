# Node RAID Issues (NodeRAIDDegraded and NodeRAIDDiskFailure)

## Meaning

These alerts indicate problems with RAID arrays on an OpenShift worker node (RHCOS):
- NodeRAIDDegraded: RAID array is in degraded state
- NodeRAIDDiskFailure: One or more disks in RAID array have failed

## Impact

- Reduced storage redundancy on the affected node
- Potential data loss risk for locally stored data
- Degraded I/O performance affecting container workloads
- Increased risk of node failure if additional disks fail
- Possible impact on local persistent volumes

## Diagnosis

1. Identify the affected node from the alert labels:
```shell
oc get nodes <NODE_NAME> -o wide
```

2. Check RAID status on the node:
```shell
oc debug node/<NODE_NAME> -- chroot /host cat /proc/mdstat
```

3. Get detailed information about the RAID array:
```shell
oc debug node/<NODE_NAME> -- chroot /host mdadm --detail /dev/md*
```

4. Identify failed disks:
```shell
oc debug node/<NODE_NAME> -- chroot /host mdadm --examine /dev/sd*
```

5. Check disk health via SMART:
```shell
oc debug node/<NODE_NAME> -- chroot /host smartctl -a /dev/sd*
```

6. Check if the node is using local storage for OpenShift resources:
```shell
oc get pv -o wide | grep <NODE_NAME>
```

## Mitigation

1. First response actions:
   - Mark the node as potentially problematic:
   ```shell
   oc adm cordon <NODE_NAME>
   ```
   
   - Evaluate if workloads need to be evacuated:
   ```shell
   oc adm drain <NODE_NAME> --ignore-daemonsets
   ```

2. For infrastructure administrators:
   - Contact your hardware provider about disk replacement
   - For on-premises deployments, replace failed disks following your hardware maintenance procedures
   - After hardware maintenance, verify RAID rebuild:
   ```shell
   oc debug node/<NODE_NAME> -- chroot /host cat /proc/mdstat
   ```

3. For OpenShift administrators:
   - If local volumes were affected, check persistent volume status:
   ```shell
   oc get pv | grep <NODE_NAME>
   ```
   
   - If the node was using Local Storage Operator, reconcile storage:
   ```shell
   oc -n openshift-local-storage logs -l app=local-storage-operator
   ```

4. After maintenance is complete:
   - Uncordon the node:
   ```shell
   oc adm uncordon <NODE_NAME>
   ```
   
   - Verify node status:
   ```shell
   oc get nodes <NODE_NAME> -o wide
   ```

## Additional Notes

- RHCOS nodes may be using software RAID (md) for system disks
- Hardware RAID issues may not be detectable through the standard Linux interfaces
- Local storage for containers might be affected by RAID issues
- Consider using OpenShift Data Foundation for resilient storage rather than local disks
- For baremetal deployments, connect with your infrastructure team to establish disk replacement procedures 