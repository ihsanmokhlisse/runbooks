# NodeHighNumberConntrackEntriesUsed

## Meaning

This alert indicates that an OpenShift worker node (RHCOS) is using a high percentage (>75%) of its connection tracking table entries, which could lead to network connectivity issues for pods if exhausted.

## Impact

- Potential pod connectivity failures
- Service disruptions for applications with high connection volumes
- API server connection issues
- Service mesh communication failures
- Ingress controller connectivity problems
- Node-to-node communication issues affecting cluster operations

## Diagnosis

1. Identify the affected node from the alert labels:
```shell
oc get nodes <NODE_NAME> -o wide
```

2. Check current conntrack usage on the node:
```shell
oc debug node/<NODE_NAME> -- chroot /host sysctl net.netfilter.nf_conntrack_count net.netfilter.nf_conntrack_max
```

3. View connection tracking statistics:
```shell
oc debug node/<NODE_NAME> -- chroot /host cat /proc/net/nf_conntrack | wc -l
```

4. Analyze connection types and sources:
```shell
oc debug node/<NODE_NAME> -- chroot /host cat /proc/net/nf_conntrack | grep -v ESTABLISHED | sort | uniq -c | sort -nr | head -n 20
```

5. Identify pods with most connections on the node:
```shell
oc debug node/<NODE_NAME> -- chroot /host crictl ps -o json | grep -B4 network
```

6. Check pod networking details:
```shell
oc get pods --all-namespaces -o wide | grep <NODE_NAME>
```

## Mitigation

1. Short-term system configuration:
   - Increase conntrack table size on the node:
   ```shell
   oc debug node/<NODE_NAME> -- chroot /host sysctl -w net.netfilter.nf_conntrack_max=<higher_value>
   ```
   
   - Reduce conntrack timeouts:
   ```shell
   oc debug node/<NODE_NAME> -- chroot /host sysctl -w net.netfilter.nf_conntrack_tcp_timeout_established=43200
   ```

2. Long-term MachineConfig solution:
   - Create a MachineConfig to set conntrack parameters:
   ```yaml
   apiVersion: machineconfiguration.openshift.io/v1
   kind: MachineConfig
   metadata:
     labels:
       machineconfiguration.openshift.io/role: worker
     name: worker-conntrack-settings
   spec:
     config:
       ignition:
         version: 3.2.0
       storage:
         files:
         - contents:
             source: data:,net.netfilter.nf_conntrack_max=1048576%0Anet.netfilter.nf_conntrack_tcp_timeout_established=43200
           mode: 0644
           path: /etc/sysctl.d/90-conntrack.conf
   ```

3. Workload optimization:
   - Identify pods creating excessive connections:
   ```shell
   oc top pods --containers=true --use-protocol-buffers -n <NAMESPACE>
   ```
   
   - Consider moving high-connection workloads to dedicated nodes:
   ```shell
   oc label node <NODE_NAME> node-role.kubernetes.io/networking=true
   ```
   
   - Apply appropriate NetworkPolicy objects to limit unnecessary connections

4. For critical situations:
   - Restart affected networking components:
   ```shell
   oc delete pod -n openshift-sdn $(oc get pods -n openshift-sdn -l app=sdn --field-selector spec.nodeName=<NODE_NAME> -o name)
   ```
   
   - Consider rebooting the node in extreme cases:
   ```shell
   oc adm drain <NODE_NAME> --ignore-daemonsets
   oc debug node/<NODE_NAME> -- chroot /host systemctl reboot
   ```

## Additional Notes

- Connection tracking is essential for OpenShift's network security and routing
- The SDN/OVN implementation in OpenShift relies heavily on conntrack
- High connection volumes are common with microservices architectures
- Consider implementing connection pooling in applications where possible
- Monitor conntrack usage trends to identify abnormal patterns that may indicate security issues
- Persistent conntrack exhaustion may indicate either a misconfiguration or a DoS attack 