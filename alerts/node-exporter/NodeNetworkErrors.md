# Node Network Errors (NodeNetworkReceiveErrs and NodeNetworkTransmitErrs)

## Meaning

These alerts indicate that network interfaces on an OpenShift worker node (RHCOS) are experiencing a high rate of errors:
- NodeNetworkReceiveErrs: More than 1% of received packets have errors
- NodeNetworkTransmitErrs: More than 1% of transmitted packets have errors

## Impact

- Degraded pod network communication
- Service mesh disruptions
- OpenShift API server communication issues
- Cluster networking performance degradation
- Service discovery failures
- Possible etcd communication issues

## Diagnosis

1. Identify the affected node and interface from the alert labels:
```shell
oc get nodes <NODE_NAME> -o wide
```

2. Check network interface statistics on the node:
```shell
oc debug node/<NODE_NAME> -- chroot /host ip -s link show
```

3. Examine network driver information:
```shell
oc debug node/<NODE_NAME> -- chroot /host ethtool -i <interface>
```

4. Check for interface errors and other details:
```shell
oc debug node/<NODE_NAME> -- chroot /host ethtool -S <interface> | grep -i error
```

5. Review system logs for network-related messages:
```shell
oc debug node/<NODE_NAME> -- chroot /host journalctl -u NetworkManager -u network
oc debug node/<NODE_NAME> -- chroot /host dmesg | grep -i eth
```

6. Check for SDN/CNI plugin issues:
```shell
oc logs -n openshift-sdn $(oc get pods -n openshift-sdn -l app=sdn -o name | head -1)
```

## Mitigation

1. Connectivity issues:
   - Verify physical network connectivity where possible
   - Check network configuration in OpenShift:
   ```shell
   oc get network.config/cluster -o yaml
   ```
   - Inspect the node's network interfaces:
   ```shell
   oc debug node/<NODE_NAME> -- chroot /host nmcli device show
   ```

2. OpenShift-specific actions:
   - Restart the node's SDN pod:
   ```shell
   SDN_POD=$(oc get pods -n openshift-sdn -l app=sdn --field-selector spec.nodeName=<NODE_NAME> -o name)
   oc delete $SDN_POD -n openshift-sdn
   ```
   - Check for NetworkPolicy issues:
   ```shell
   oc get networkpolicy --all-namespaces
   ```

3. Hardware/driver issues:
   - If driver issues are suspected, contact your infrastructure provider
   - For on-premises clusters, check switch port configurations
   - Consider node replacement if hardware issues persist:
   ```shell
   oc adm cordon <NODE_NAME>
   oc adm drain <NODE_NAME> --ignore-daemonsets
   ```

4. Recovery steps after repairs:
   - If a node was cordoned, uncordon it:
   ```shell
   oc adm uncordon <NODE_NAME>
   ```
   - Verify node status:
   ```shell
   oc get nodes <NODE_NAME> -o wide
   ```

## Additional Notes

- Network errors on RHCOS nodes often relate to physical infrastructure or CNI issues
- The overlay network used in OpenShift adds complexity to troubleshooting
- Cluster network operator logs may provide additional context
- Consider MTU sizing matches across all infrastructure components
- Verify SDN/OVN configuration parameters match your infrastructure requirements 