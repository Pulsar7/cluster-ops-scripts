# Search for orphaned datasets

A simple chores-script to search for datasets without corresponding PVs in the cluster.

> [!NOTE]
> This script will **NOT** edit/remove any dataset or PV. The script only reads, filters the output of `zfs list` and `kubectl get pv` and
> prints out the suspected orphaned datasets.
