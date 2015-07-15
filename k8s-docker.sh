#!/bin/bash

ETCD_VERSION=2.0.12
K8S_VERSION=v0.21.2
DNS_IP=10.0.0.10
DNS_DOMAIN=cluster.local

########## ETCD ##########

 docker run \
  --net=host \
  -d \
  --name=etcd \
  --restart=always \
  gcr.io/google_containers/etcd:${ETCD_VERSION} /usr/local/bin/etcd \
    --addr=127.0.0.1:4001 \
    --bind-addr=0.0.0.0:4001 \
    --data-dir=/var/etcd/data

########## KUBELET ##########

docker run \
  --net=host \
  --name=kubelet \
  --restart=always \
  -d \
  -v /var/run/docker.sock:/var/run/docker.sock \
  gcr.io/google_containers/hyperkube:${K8S_VERSION} /hyperkube \
  kubelet \
    --api_servers=http://127.0.0.1:8080 \
    --v=1 \
    --address=0.0.0.0 \
    --enable_server \
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
    --portal_net=10.0.0.0/16 \
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
