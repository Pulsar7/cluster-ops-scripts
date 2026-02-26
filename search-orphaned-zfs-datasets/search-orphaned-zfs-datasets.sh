#!/bin/bash

#
# '-e': Exit immediately if a command exits with a non-zero status.
# '-u': Treat unset variables as an error when substituting.
# '-o pipefail': the return value of a pipeline is the status of 
#                the last command to exit with a non-zero status,
#                or zero if no command exited with a non-zero status
set -euo pipefail
#
# If you want to restrict to a specific pool, set it here (e.g. "tank/k3s")
# Otherwise leave empty to scan all datasets.
ZFS_ROOT="${1:-}"

echo "Collecting existing PV names from Kubernetes..."
PV_LIST="$(kubectl get pv -o jsonpath='{range .items[*]}{.metadata.name}{"\n"}{end}')"

if [[ -z "${PV_LIST}" ]]; then
  echo "No PVs found or kubectl not configured correctly."
  exit 1
fi

echo "Scanning ZFS datasets..."
echo

#
# You can use the -H option to omit the zfs list header from the generated output. 
# With the -H option, all white space is replaced by the Tab character.
# > https://docs.oracle.com/cd/E18752_01/html/819-5461/gazsu.html
if [[ -n "${ZFS_ROOT}" ]]; then
  #
  # use the -r option to recursively display all descendents of that dataset.
  DATASETS=$(zfs list -H -o name -r "${ZFS_ROOT}")
else
  DATASETS=$(zfs list -H -o name)
fi

ORPHANS_FOUND=0

while IFS= read -r DATASET; do
  #
  # Look for pvc-<uuid> pattern inside dataset name
  if [[ "${DATASET}" =~ (pvc-[0-9a-fA-F-]{36}) ]]; then
    PVC_ID="${BASH_REMATCH[1]}"
    #
    # Check if a PV with that exact name exists
    if ! grep -qx "${PVC_ID}" <<< "${PV_LIST}"; then
      echo "Orphaned dataset found:"
      echo "  ZFS dataset: ${DATASET}"
      echo "  Missing PV:  ${PVC_ID}"
      echo
      ORPHANS_FOUND=1
    fi
  fi
done <<< "${DATASETS}"

if [[ "${ORPHANS_FOUND}" -eq 0 ]]; then
  echo "No orphaned ZFS PVC datasets found."
fi
