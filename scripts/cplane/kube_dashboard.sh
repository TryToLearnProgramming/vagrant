#!/usr/bin/env bash

# Strip off errant 'localhost-y' reference that get created via vagrant
CPLANE_IP=$(echo $(hostname -i | sed -E 's/127\.0\.[0-9]+\.[0-9]+//g'))

# Kubernetes Dashboard Parameters
NAMESPACE="kubernetes-dashboard"
SERVICE="kubernetes-dashboard"
DASHBOARD_PORT=32443
DASHBOARD_SESSION_TIMEOUT=3600 # (60 x 60 Seconds; 1 hour)

function help_msg {
    echo ""
    echo "usage: ${0} [worker|cplane|token], where:"
    echo "    worker - Deploy dashboard on any worker node"
    echo "    cplane - Deploy dashboard on the control plane"
    echo "    token  - Show the dashboard credentials token"
    echo ""
}


# Quick check to see if Helm is installed, as
# It is used for service deployments on the Control Plane
function helm_sanity_check {
    # Is Helm installed?
    echo "🔍 Check for Helm tool on the machine"
    if ! command -v helm >/dev/null 2>&1; then
        echo "❌ Helm not found; install helm before continuing"
        exit 1
    fi
}


# Is the dashboard service up and running?
function dashboard_sanity_check {
    echo "🔍 Checking if Service '${SERVICE}' exists in namespace '${NAMESPACE}'..."
    if ! kubectl get svc -n "${NAMESPACE}" "${SERVICE}" >/dev/null 2>&1; then
        echo "❌ Service ${SERVICE} NOT found in namespace ${NAMESPACE}"
        exit 1
    else
        echo "✅ Service ${SERVICE} found in namespace ${NAMESPACE}"
    fi
}


# Configure the control plane to be the home of the Kubernetes Dashboard
# This is just fine for a small deployment for development, however proper
# HA configuration should be used for a larger cluster
function dashboard_on_control_plane {
    echo "⚙️  Configuring Control Plane to host the dashboard (as opposed to a worker)"
    echo "🔍 Current Control Plane restrictions (Taints) - likely only 'NoSchedule'"

    # should see "Taints: node-role.kubernetes.io/control-plane:NoSchedule"
    kubectl describe node cplane | grep Taints

    # remove taint for the dashboard (only):
    echo "⚙️  Relaxing restriction (taint) on the control plane for '${SERVICE}'"
    kubectl -n ${NAMESPACE} patch deployment ${SERVICE} \
        --type='json' \
        -p='[{"op":"add","path":"/spec/template/spec/tolerations","value":[{"key":"node-role.kubernetes.io/control-plane","effect":"NoSchedule"}]}]'

    echo "🔍 Updated Control Plane restrictions (Taints)"
    # should see "Taints: node-role.kubernetes.io/control-plane:NoSchedule"
    kubectl describe node cplane | grep Taints
    echo ""
}


# Install of Kubernetes Dashboard via the Helm Chart
# (Which is now the official deployment method)
function helm_dashboard_install {
    echo "⚙️  Installing Kubernetes Dashboard (via helm)"
    echo "⚙️  Add kubernetes-dashboard Helm repository"
    helm repo add kubernetes-dashboard https://kubernetes.github.io/dashboard/

    echo "⚙️  Deploy 'kubernetes-dashboard' Helm chart"
    helm upgrade --install ${SERVICE} kubernetes-dashboard/kubernetes-dashboard --create-namespace --namespace ${NAMESPACE}

    echo "⚙️  Apply recommended manifests from the upstream project:"
    kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.7.0/aio/deploy/recommended.yaml
}


# Create RBAC credential to access / admin via dashboard
function dashboard_user_create {
    echo "⚙️  Create user credentials for dashboard"
    echo "⚙️  First, YAML file to create dashboard admin user"

    #
    # This creates the yaml file to instruct k8s in creating the dashboard space and the rbac access
    # Do NOT modify or change the spacing between these lines!
    #
    # ----------------------------------------------
    cat > dashboard-adminuser.yaml << EOF
apiVersion: v1
kind: ServiceAccount
metadata:
  name: admin-user
  namespace: ${NAMESPACE}
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: admin-user-binding
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin
subjects:
- kind: ServiceAccount
  name: admin-user
  namespace: ${NAMESPACE}
EOF
# ----------------------------------------------
#
    echo "⚙️  Apply user create yaml to k8s"
    kubectl apply -f dashboard-adminuser.yaml
    rm -rf dashboard-adminuser.yaml
}


# Specific the specific port for the Dashboard
# NodePort will otherwise choose a random port
function dashboard_port_forward {
    echo "⚙️  Setting up dashboard access via NodePort, port ${DASHBOARD_PORT}"
    kubectl -n ${NAMESPACE} patch svc ${SERVICE} --type='json' -p="[
        {\"op\":\"replace\",\"path\":\"/spec/type\",\"value\":\"NodePort\"},
        {\"op\":\"replace\",\"path\":\"/spec/ports/0/nodePort\",\"value\":$((DASHBOARD_PORT))}
    ]"

    if [ ${?} -eq 0 ]; then
        echo "✅ Dashboard is now exposed at: https://${CPLANE_IP}:${DASHBOARD_PORT}/"
    else
        echo "❌ Failed to patch the Service"
        exit 1
    fi

    echo "🔍 New Assigned NodePort:"
    kubectl -n ${NAMESPACE} get svc ${SERVICE}
}


# Adjust the session timeout (which is quite short)
function dashboard_session_timeout {
    echo "⚙️  Adjusting Kubernetes Dashboard session timeout (${DASHBOARD_SESSION_TIMEOUT} seconds)"

    kubectl -n ${NAMESPACE} patch deployment ${SERVICE} --type='json' -p="[
       {\"op\":\"add\",\"path\":\"/spec/template/spec/containers/0/args/-\",\"value\":\"--token-ttl=${DASHBOARD_SESSION_TIMEOUT}\"}
    ]"

    if  [ $? -eq 0 ]; then
        echo "✅ Patch Applied"
    else
        echo "❌ Failed to patch the Deployment"
        exit 1
    fi
}

# Verify Kubernetes Dashboard available
function verify_kube_dashboard {
    # Verify that CNI service is running
    timeout=60 # 2 minutes = 120 seconds
    interval=10 # check every 10 seconds
    elapsed=0

    # Repeat loop until time runs out
    while [ ${elapsed} -lt ${timeout} ]; do
        echo -n "🔍 Verify Kubernetes Dashboard running"
        if [ ${elapsed} -gt 0 ]; then
            echo " (trying for $((timeout - elapsed)) more seconds)"
        else
            echo ""
        fi

        # If the dashboard is running correctly then it will report back the pods list
	dashboard_state=$(kubectl get pods -n ${NAMESPACE} -o json 2>/dev/null | jq -r '.items[] | select(.metadata.name | match("kubernetes-dashboard-[0-9a-f]{10}-[0-9a-f]")) | .status.phase')

        elapsed=$((elapsed + interval))
        if [ "${dashboard_state}" == "Running" ]; then
            break
        elif [ ${elapsed} -lt ${timeout} ]; then
            sleep ${interval}
        fi
    done

    if [ ${dashboard_state} == "Running" ]; then
        echo "✅ Kubernetes Dashboard is running"
    else
        echo "❌ Timed out during check - Kubernetes Dashboard is NOT running"
        exit 1
    fi
}


# Retrieve and display the dashboard credentials
# And the url for login
function dashboard_user_token {
    echo "🔍 Retrieving the dashboard login token from k8s"
    echo "⚙️  Copy and paste this to the 'Enter token *' field on the dashboard login"
    echo "--------------------------------------------------"
    kubectl -n ${NAMESPACE} create token admin-user
    echo "--------------------------------------------------"
    echo "Dashboard is at: https://${CPLANE_IP}:${DASHBOARD_PORT}"
    echo ""
}


#
# Main Execution Loop
#
# Grab the command parameter
param_str="${1,,}"
if ! [[ ${param_str} = @(worker|cplane|token) ]]; then
   echo "invalid parameter"
   help_msg

   exit 1
fi

if [[ ${param_str} = @(worker|cplane) ]]; then
    helm_sanity_check
    helm_dashboard_install
    dashboard_sanity_check

    # cplane only
    if [ "${param_str}" == "cplane" ]; then
        dashboard_on_control_plane
    fi

    dashboard_user_create
    dashboard_port_forward
    dashboard_session_timeout
    verify_kube_dashboard
fi

# Always show the user token
dashboard_user_token
