# Node Network Errors (NodeNetworkReceiveErrs and NodeNetworkTransmitErrs)

## Meaning

These alerts indicate that network interfaces are experiencing a high rate of errors:
- NodeNetworkReceiveErrs: More than 1% of received packets have errors
- NodeNetworkTransmitErrs: More than 1% of transmitted packets have errors

## Impact

- Degraded network performance
- Application timeouts
- Increased latency
- Potential packet loss and retransmissions

## Diagnosis

1. Check network interface statistics:
```shell
ip -s link show
ethtool -S <interface>
```

2. Monitor real-time errors:
```shell
watch -n1 'ip -s link show'
```

3. Check physical connection:
```shell
ethtool <interface>
```

4. Review system logs:
```shell
journalctl -u NetworkManager
dmesg | grep -i eth
```

## Mitigation

1. Hardware issues:
   - Check cable connections
   - Replace faulty cables
   - Verify switch port configuration
   - Test alternative network ports

2. Driver issues:
   - Update network driver
   - Check for known bugs
   - Consider driver parameters tuning

3. Configuration:
   - Verify duplex and speed settings
   - Check MTU configuration
   - Review NIC offloading settings

## Additional Notes

- Network errors above 1% indicate significant issues
- Consider environmental factors (EMI, cable length)
- Document baseline error rates for comparison 