#!/bin/bash

ETCD_VERSION=2.2.0
K8S_VERSION=v1.1.2
DNS_IP=10.0.0.10
DNS_DOMAIN=cluster.local

########## ETCD ##########

docker create -v /var/etcd/data --name etcd-data busybox true

docker run \
  --net=host \
  -d \
  --name=etcd \
  --restart=always \
  --volumes-from etcd-data \
  quay.io/coreos/etcd:v${ETCD_VERSION} \
    --addr=127.0.0.1:4001 \
    --bind-addr=0.0.0.0:4001 \
    --data-dir=/var/etcd/data

########## KUBELET ##########

docker run \
  --net=host \
  --volume=/:/rootfs:ro \
  --volume=/sys:/sys:ro \
  --volume=/dev:/dev \
  --volume=/var/lib/docker/:/var/lib/docker:rw \
  --volume=/var/lib/kubelet/:/var/lib/kubelet:rw \
  --volume=/var/run:/var/run:rw \
  --name=kubelet \
  --pid=host \
  --privileged=true \
  --detach \
  --restart=always \
  gcr.io/google_containers/hyperkube:${K8S_VERSION} /hyperkube \
  kubelet \
    --api_servers=http://127.0.0.1:8080 \
    --v=1 \
    --address=0.0.0.0 \
    --containerized \
    --hostname_override=127.0.0.1 \
    --allow_privileged=true \
    --logtostderr=true \
    --cluster_dns=${DNS_IP} \
    --cluster_domain=${DNS_DOMAIN}

########## KUBE-APISERVER ##########

docker run \
  --net=host \
  --name=kube-apiserver \
  --restart=always \
  -d \
  gcr.io/google_containers/hyperkube:${K8S_VERSION} /hyperkube \
  apiserver \
    --runtime-config=extensions/v1beta1/daemonsets=true \
    --service-cluster-ip-range=10.0.0.0/16 \
    --insecure_bind_address=0.0.0.0 \
    --insecure_port=8080 \
    --etcd_servers=http://127.0.0.1:4001 \
    --cluster_name=kubernetes \
    --v=1 \
    --allow_privileged=true \
    --logtostderr=true

########## KUBE-CONTROLLER-MANAGER ##########

docker run \
  --net=host \
  --name=kube-controller-manager \
  --restart=always \
  -d \
  gcr.io/google_containers/hyperkube:${K8S_VERSION} /hyperkube \
  controller-manager \
    --master=127.0.0.1:8080 \
    --v=1 \
    --logtostderr=true

########## KUBE-SCHEDULER ##########

docker run \
  --net=host \
  --name=kube-scheduler \
  --restart=always \
  -d \
  gcr.io/google_containers/hyperkube:${K8S_VERSION} /hyperkube \
  scheduler \
    --master=127.0.0.1:8080 \
    --v=1 \
    --logtostderr=true

########## KUBE-PROXY ##########

docker run \
  --net=host \
  --privileged \
  --name=kube-proxy \
  --restart=always \
  -d \
  gcr.io/google_containers/hyperkube:${K8S_VERSION} /hyperkube \
  proxy \
    --master=127.0.0.1:8080 \
    --v=1 \
    --logtostderr=true
