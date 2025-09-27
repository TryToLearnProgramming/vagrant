#!/usr/bin/env bash

echo "⚙️  Setting worker node(s) > 'node-role.kubernetes.io/worker=worker'"

# Get list of nodes, run through the workers
kub_nodes_json=`kubectl get nodes -o json`
for node_name in `echo ${kub_nodes_json} | jq -r '.items[] | select(.metadata.name | startswith("worker")) | .metadata.name'` ; do
     echo "⚙️  set worker node role for '${node_name}'"
     kubectl label --overwrite node ${node_name} node-role.kubernetes.io/worker=worker >/dev/null
done

echo ""
echo "🔍 Cluster nodes and roles:"
echo "---------------------------"
kubectl get nodes
echo ""
