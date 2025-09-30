#!/usr/bin/env bash

#
# Script to Initialize the Control Plane
#
# There is a lot in this script. If you're learning, don't be put off
# look below for "SCRIPT ESSENTIALS" and it shows the small set of
# important functions, which are:
#
# 1. Grab the kubernetes service images
# 2. Init the service, specifying the base CIDR
# 3. Copy the kube config to the user directory
# 4. Install the CNI service
#
# Unicode Character icons (https://www.compart.com/en/unicode) for pretty scripts
#
# 😄 Generic Info
# ☸️ Kubernetes
# ✨ Perform Magic
# ⚙️ Setting something
# 🚜 Image pull
# 🛠 Tools / Install
# 🔍 Get Info or Data or Config
# ✅ Good Result
# ❌ Bad Result
# ⬆ Up Arrow
# ⬇ Down Arrow
# ❓ Question / Unknown
# 🤷 Something missing
# 🔥 Creating something
# 👍 Startup
# ⏳ Waiting
# 🔄 Restarting
#

# These variables define the Heart of the Cluster: CP ID and IP base for Pods
#
# Strip off errant 'localhost-y' reference that get created via vagrant
API_SERVER_IP=$(echo $(hostname -i | sed -E 's/127\.0\.[0-9]+\.[0-9]+//g'))
POD_BASE_CIDR=10.244.0.0 # Base address for pods

# Hey, howzitgoing
function welcome_msg {
    echo "Kubernetes Control Plane / Cluster Init"
    echo ""
    echo "POD_BASE_CIDR: '${POD_BASE_CIDR}'"
    echo "API_SERVER_IP: '${API_SERVER_IP}'"
    echo ""
}


# Quick check to see if Kubernetes utilities are installed
function kube_sanity_check {
    # Are Kubernetes tools installed?
    echo "🔍 Check for kubernetes tools on the machine"

    kube_tools="kubelet kubeadm kubectl"
    for ktool in $(echo ${kube_tools}); do
        if ! command -v ${ktool} >/dev/null 2>&1; then
            echo "🤷 utility '${ktool}' not found"
            ktoolmissing=y
        fi
    done

    if [ "${ktoolmissing}" == "y" ] ; then
        echo "❌ one ore more kubernetes utilities missing; install before continuing"
        exit 1
    fi
}


# Verify that the api server is up and running ?
# or all are down
#
# Param 1 - "up" or "down"
# Param 2 - optional - "retry" for a retry loop, useful
#           for when services are taking time to come up/down
function verify_controlplane_state {
    D_SOC=unix:///var/run/containerd/containerd.sock

    state_check="${1,,}"
    if ! [[ ${state_check} = @(up|down) ]]; then
       echo "❌ Invalid parameter must be 'up' or 'down'"
       exit 1
    fi

    # Option to allow for delayed retries (allow for services to come up/down)
    if [ "${2,,}" == "retry" ]; then
        timeout=60 # 1 minute = 60 seconds
    else
        timeout=0  # No loop; (or, just one iteration)
    fi
    interval=10
    elapsed=0

    # What services are we checking for?
    kube_services="kube-apiserver kube-controller-manager kube-scheduler kube-proxy etcd"

    # Find max svc name length (purely aesthetic)
    maxlen=0
    for kubsvc in $(echo ${kube_services}); do
        [ ${#kubsvc} -gt ${maxlen} ] && maxlen=${#kubsvc}
    done
    maxlen=$((maxlen + 2))

    # Repeat loop until time runs out
    while [ ${elapsed} -lt ${timeout} ]; do
        echo -n "🔍 Verify Kubernetes Services run state is '${state_check}'"
        if [ ${elapsed} -gt 0 ]; then
            echo " (trying for $((timeout - elapsed)) more seconds)"
        else
            echo ""
        fi

        # Clear up/down State Markers
        ksvcup=""
        ksvcdown=""

        # Check state of each service
        for kubsvc in $(echo ${kube_services}); do
            SVC_STATE=$(sudo crictl --runtime-endpoint ${D_SOC} ps -o json --name "${kubsvc}" 2>/dev/null | jq -r ".containers[] | select(.metadata.name == \"${kubsvc}\") | .state")

            # State Icons (actual vs compare) - Up, Down, or Unknown
            # Also to create the "icon state" for each service (up/down and expectation)
            if [ "${SVC_STATE}" == "CONTAINER_RUNNING" ]; then
                ksvcup=y
                state_str="up"
                state_icon=$([ "${state_check}" == "up" ] && echo "⬆ ✅" || echo "⬆ ❌" )
            elif [ "${SVC_STATE}" == "" ]; then
                ksvcdown=y
                state_str="down"
                state_icon=$([ "${state_check}" == "down" ] && echo "⬇ ✅" || echo "⬇ ❌")
            else
                ksvcdown=y
                state_str="down / uncertain (state: '${SVC_STATE}')"
                state_icon="❓ ❌"
            fi

            printf "  %s Service %-*s: %s\n" "${state_icon}" "${maxlen}" "'${kubsvc}'" "${state_str}"
        done

        # Are service states matching expectations?
        # - Going "up" but some services are still down?
        # - Going "down" but some services are still up?
        # - All good - All own or all up, as expected?
        state_check="${1,,}"
        if [ "${state_check}" == "up" ] && [ "${ksvcdown}" == "y" ] ; then
            echo "❌ Expected state is UP but some services are not running"
            exit_state=1
        elif [ "${state_check}" == "down" ] && [ "${ksvcup}" == "y" ] ; then
            echo "❌ Expected state is DOWN but some services are still running"
            exit_state=1
        else
            echo "✅ Kubernetes Services in expected state: '${state_check}'"
            exit_state=0
            retries=0
        fi

        # If there is a retry to be had, notify, delay, and repeat
        # a timeout of 0 means no loop, just break out
        elapsed=$((elapsed + interval))
        if [ "${exit_state}" == "0" ] || [ "${timeout}" == "0" ]; then
            break
        elif [ ${elapsed} -lt ${timeout} ]; then
            echo "⏳ Retry - ${interval} second delay"
            sleep ${interval}
        fi
    done

    # didn't work; exit out
    if [ "${exit_state}" == "1" ] ; then
        exit 1
    fi
}

#
# SCRIPT ESSENTIALS ARE HERE
#
# There are many functions in this script that perform
# a series of sanity checks and "extra" work, which is helpful
# but not strictly necessary
#
# The ESSENTIAL work is right here:
#   controlplane_init  - to start up the Control Plane
#   kubeconf_copy      - to use 'kubectl' properly
#   verify_flannel_cni - to set up cluster communication
#
# If you are trying to learn about Starting up a Kubernetes
# Cluster, these are the essential functions
#
# If you are interested in creating solid service automation
# the rest of the informative or sanity checking is very handy
#

# Initialize the Control Plane Cluster
function controlplane_init {
    # Pull down the Kubernetes images for Control Plane Initialization
    echo "🚜  Pulling Kubernetes execution Images"
    echo "--------------------------------------"
    sudo kubeadm config images pull
    echo "--------------------------------------"

    # Spin up the Control Plane Node (the 'heart' of the Cluster)
    echo "🔄  Initializing Cluster"
    echo "--------------------------------------"
    sudo kubeadm init --pod-network-cidr=${POD_BASE_CIDR}/16 --apiserver-advertise-address=${API_SERVER_IP}
    echo "--------------------------------------"
}


# Copy the k8s admin.conf into the user directory for subsequent use
function kubeconf_copy {
    if [ -f /etc/kubernetes/admin.conf ] ; then
        echo "⚙️  Create local '.kube/config'"
        mkdir -p ${HOME}/.kube
        sudo cp -f /etc/kubernetes/admin.conf ${HOME}/.kube/config
        sudo chown $(id -u):$(id -g) ${HOME}/.kube/config
    fi
}


# Install the Flannel CNI (Container Network Interface)
function install_flannel_cni {
    echo "🚜  Install Flannel CNI Service"

    # The Prepackaged Flannel CNI is hard coded to use CIDR of 10.244.0.0/16
    if ! [ "${POD_BASE_CIDR}" == "10.244.0.0" ]; then
        echo "❌ For Flannel CNI via 'kubectl apply', var 'POD_BASE_CIDR' must be '10.244.0.0'"
        echo "   (POD_BASE_CIDR is currently defined as '${POD_BASE_CIDR}')"
        echo ""
        exit 1
    fi

    # Install Flannel Service
    echo "--------------------------------------"
    kubectl apply -f https://raw.githubusercontent.com/flannel-io/flannel/master/Documentation/kube-flannel.yml --validate=false
    echo "--------------------------------------"

    # Restart the kubelet
    sudo service kubelet restart
}


# Verify the Flannel CNI Installation
function verify_flannel_cni {
    echo "🔍 Verify Flannel CNI Service Install"

    # Verify that CNI service is running
    timeout=60 # 1 minute = 60 seconds
    interval=10 # check every 10 seconds
    elapsed=0

    # Repeat loop until time runs out
    while [ ${elapsed} -lt ${timeout} ]; do
        echo -n "🔍 Verify Flannel Service running"
        if [ ${elapsed} -gt 0 ]; then
            echo " (trying for $((timeout - elapsed)) more seconds)"
        else
            echo ""
        fi

        # If Flannel is running correctly then it will report back the pods list
        flannel_state=$(kubectl get pods -n kube-flannel -o json 2>/dev/null | jq -r '.items[] | select(.metadata.name | startswith("kube-flannel-")) | .status.phase')

        elapsed=$((elapsed + interval))
        if [ ${flannel_state} == "Running" ]; then
            break
        elif [ ${elapsed} -lt ${timeout} ]; then
            echo "⏳ Current State: '${flannel_state}', sleep and retry"
            sleep ${interval}
        fi
    done

    if [ ${flannel_state} == "Running" ]; then
        echo "✅ Flannel CNI Service is running"
    else
        echo "❌ Timed out during check - Flannel CNI service is NOT running"
        exit 1
    fi
}


# Install the Weave CNI (Container Network Interface)
# NOTE: Weave Project was Shuttered in June 2024 and no longer supported
function install_weave_cni {
    echo "🚜  Install Weave CNI Service"
    echo "--------------------------------------"
    kubectl apply -f https://github.com/weaveworks/weave/releases/download/v2.8.1/weave-daemonset-k8s.yaml --validate=false
    echo "--------------------------------------"
}


# Verify the Weave CNI Installation
function verify_weave_cni {
    echo "🔍 Verify Weave CNI Service Install"

    # Verify that CNI service is running
    timeout=60 # 2 minutes = 120 seconds
    interval=10 # check every 10 seconds
    elapsed=0

    # Repeat loop until time runs out
    while [ ${elapsed} -lt ${timeout} ]; do
        echo -n "🔍 Verify Weave Service running"
        if [ ${elapsed} -gt 0 ]; then
            echo " (trying for $((timeout - elapsed)) more seconds)"
        else
            echo ""
        fi

        # If Weave is running correctly then it will report back the pods list
        weave_count=$(kubectl get pods -n kube-system -o json 2>/dev/null | jq -r '.items[] | select(.metadata.name | startswith("weave-net-")) | .metadata.name' | wc -l)
        elapsed=$((elapsed + interval))
        if [ ${weave_count} -gt 0 ]; then
            break
        elif [ ${elapsed} -lt ${timeout} ]; then
            sleep ${interval}
        fi
    done

    if [ ${weave_count} -gt 0 ]; then
        echo "✅ Weave CNI Service is running"
    else
        echo "❌ Timed out during check - Weave CNI service is NOT running"
        exit 1
    fi
}


# Install the Rancher LocalPath StorageClass implementation
function install_localpath_storageclass {
    echo "🚜  Install Rancher 'local-path' StorageClass"
    echo "--------------------------------------"
    kubectl apply -f https://raw.githubusercontent.com/rancher/local-path-provisioner/v0.0.32/deploy/local-path-storage.yaml --validate=false
    echo "--------------------------------------"
}


#
# Main Execution Loop
#
welcome_msg
kube_sanity_check
verify_controlplane_state down
controlplane_init
kubeconf_copy
verify_controlplane_state up retry
install_flannel_cni
verify_flannel_cni
#install_weave_cni
#verify_weave_cni
install_localpath_storageclass
