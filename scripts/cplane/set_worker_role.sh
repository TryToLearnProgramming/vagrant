#!/usr/bin/env bash

echo "⚙️  Setting worker node(s) role to 'worker'"

# Get list of nodes, look through the workers
kub_nodes_json=`kubectl get nodes -o json`
for node_name in `echo ${kub_nodes_json} | jq -r '.items[] | select(.metadata.name | startswith("worker")) | .metadata.name'` ; do

    # Get the current role (if any) set for the worker node
    node_role=`echo ${kub_nodes_json} | jq -r '.items[] | select(.metadata.name | startswith("worker")) | select(.metadata.name == "worker1") | .metadata.labels | to_entries[] | select(.key | startswith("node-role.kubernetes.io/worker")) | .value'`

    # Only set the role if it's not already in place
    echo "🔍 node role for '${node_name}': '${node_role}'"

    if [ ! "${node_role}" == "worker" ] ; then
        echo "⚙️  set worker node role for '${node_name}'"
        kubectl label --overwrite node ${node_name} node-role.kubernetes.io/worker=worker >/dev/null
   else
        echo "  role 'worker' already set for node '${node_name}'"
   fi
done

echo ""
echo "🔍 k8s nodes with roles:"
echo "---------------------"
kubectl get nodes
