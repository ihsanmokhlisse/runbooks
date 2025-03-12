# NodeHighNumberConntrackEntriesUsed

## Meaning

This alert indicates that a node is using a high percentage (>75%) of its connection tracking table entries, which could lead to network connectivity issues if exhausted.

## Impact

- Potential connection failures for new network connections
- Network timeouts in applications
- Degraded network performance
- Service disruptions when the table is completely full

## Diagnosis

1. Check current conntrack usage:
```shell
sysctl net.netfilter.nf_conntrack_count
sysctl net.netfilter.nf_conntrack_max
```

2. View connection tracking statistics:
```shell
cat /proc/net/nf_conntrack | wc -l
```

3. Analyze connection types and sources:
```shell
cat /proc/net/nf_conntrack | grep -v ESTABLISHED | sort | uniq -c | sort -nr | head -n 20
```

4. Identify processes with most connections:
```shell
ss -tnp | awk '{print $6}' | sort | uniq -c | sort -nr | head -n 20
```

## Mitigation

1. Immediate actions:
   - Increase conntrack table size:
     ```shell
     sysctl -w net.netfilter.nf_conntrack_max=<higher_value>
     ```
   - Add to `/etc/sysctl.conf` to persist:
     ```
     net.netfilter.nf_conntrack_max=<higher_value>
     ```

2. Reduce connection timeouts:
   ```shell
   sysctl -w net.netfilter.nf_conntrack_tcp_timeout_established=54000
   ```

3. Long-term solutions:
   - Investigate connection patterns for optimization
   - Adjust application connection handling
   - Consider load balancing to distribute connections
   - Implement connection pooling where appropriate
   - Tune timeout values based on application requirements

## Additional Notes

- Connection tracking is essential for stateful firewall operation
- Common in high-traffic nodes, NAT gateways, load balancers, and proxies
- Modern applications with microservice architectures may create many short-lived connections
- Consider monitoring connection rates to identify potential DoS attacks 