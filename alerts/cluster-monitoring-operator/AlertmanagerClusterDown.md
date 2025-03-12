# AlertmanagerClusterDown

## Meaning

The alert `AlertmanagerClusterDown` is triggered when half or more of the Alertmanager instances within the same cluster have been down for a significant period. This indicates a critical problem that could affect the entire alerting system.

## Impact

- Severe degradation or complete loss of alert delivery capability
- Critical alerts may not be delivered to the intended recipients
- No notifications will be sent for ongoing incidents
- Reduced or lost high-availability of the alerting system

## Diagnosis

1. Check the status of Alertmanager pods:

   ```console
   $ oc -n openshift-monitoring get pods -l alertmanager=main
   ```

2. View recent events related to Alertmanager:

   ```console
   $ oc -n openshift-monitoring get events | grep alertmanager
   ```

3. Examine the logs of any running Alertmanager pods:

   ```console
   $ oc -n openshift-monitoring logs -l alertmanager=main
   ```

4. If pods are in a crash state, describe them to understand why:

   ```console
   $ oc -n openshift-monitoring describe pod -l alertmanager=main
   ```

5. Check the status of the Alertmanager StatefulSet:

   ```console
   $ oc -n openshift-monitoring describe statefulset alertmanager-main
   ```

6. Verify the resource usage of the Alertmanager pods:

   ```console
   $ oc -n openshift-monitoring adm top pod -l alertmanager=main
   ```

## Mitigation

1. If pods are in a failing or CrashLoopBackOff state, review the logs to determine the cause:

   ```console
   $ oc -n openshift-monitoring logs alertmanager-main-0 --previous
   ```

2. Check for resource constraints and adjust if necessary:

   ```console
   $ oc -n openshift-monitoring get cm cluster-monitoring-config -o yaml
   ```

3. If Alertmanager is unable to start due to configuration issues, examine and correct the configuration:

   ```console
   $ oc -n openshift-monitoring get secret alertmanager-main -o jsonpath='{.data.alertmanager\.yaml}' | base64 -d
   ```

4. For persistent issues, you may need to restart the Cluster Monitoring Operator:

   ```console
   $ oc -n openshift-monitoring delete pod -l app=cluster-monitoring-operator
   ```

5. Ensure that node resource issues aren't causing the pods to be evicted:

   ```console
   $ oc get nodes
   $ oc describe node <node-name>
   ```

6. If needed, you can force a recreate of the Alertmanager pods:

   ```console
   $ oc -n openshift-monitoring delete pod -l alertmanager=main
   ```

The alert should resolve once more than half of the Alertmanager instances are up and running correctly. 