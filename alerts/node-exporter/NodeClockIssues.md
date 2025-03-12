# Node Clock Issues (NodeClockSkewDetected and NodeClockNotSynchronising)

## Meaning

These alerts indicate problems with system time synchronization:
- NodeClockSkewDetected: System clock is offset by more than 300ms
- NodeClockNotSynchronising: System is unable to synchronize its clock

## Impact

- Certificate validation failures
- Authentication issues
- Log correlation problems
- Database transaction issues
- Distributed systems coordination problems

## Diagnosis

1. Check NTP status:
```shell
timedatectl status
chronyc sources
# or
ntpq -p
```

2. Verify NTP configuration:
```shell
cat /etc/chrony.conf
# or
cat /etc/ntp.conf
```

3. Check system logs:
```shell
journalctl -u chronyd
# or
journalctl -u ntpd
```

## Mitigation

1. NTP service issues:
   - Restart NTP service
   - Verify NTP server accessibility
   - Check firewall rules for NTP

2. Configuration fixes:
   - Update NTP server list
   - Adjust polling intervals
   - Check for local NTP server

3. System issues:
   - Verify hardware clock
   - Check for virtualization timing issues
   - Review system load impact

## Additional Notes

- Time synchronization is critical for distributed systems
- Consider using local NTP servers
- Document approved time sources
- Monitor NTP server stratum levels 