#!/usr/bin/env bash

echo "k8s worker join command (requires sudo):"
echo ""
echo "--------------------------------------------------"
echo -n "sudo "
sudo kubeadm token create --print-join-command
echo "--------------------------------------------------"
echo ""

