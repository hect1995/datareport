#!/bin/bash

################## VARIABLES #########################
TICKET_ID=000110010
MASTER_NODE=ocp3mst1.ocp3.rhbcnconsulting.com
#WORKERS=ocp3inf1.ocp3.rhbcnconsulting.com
declare -a WORKERS
WORKERS=(ocp3inf1.ocp3.rhbcnconsulting.com ocp3inf2.ocp3.rhbcnconsulting.com ocp3inf3.ocp3.rhbcnconsulting.com)

################## DATA IN MASTER #####################
ssh ${MASTER_NODE} << EOF
  install sos -y
  yum update sos
  sosreport --ticket-number $TICKET_ID
EOF

SOSREPORT_MASTER=$(ssh ${MASTER_NODE} "ls -t /var/tmp | grep sosreport | head -n1")
mkdir /root/sosreport
scp ${MASTER_NODE}:/var/tmp/${SOSREPORT_MASTER} /root/sosreport/${SOSREPORT_MASTER}

ssh ${MASTER_NODE} "oc get node,hostsubnet -o wide" > ${TICKET_ID}_node-hostsubnet.txt
ssh ${MASTER_NODE} "oc describe nodes" > ${TICKET_ID}_describe-nodes.txt
ssh ${MASTER_NODE} "oc get all,events  -o wide -n default" > ${TICKET_ID}_events-and-all.txt
ssh ${MASTER_NODE} "oc get --raw /metrics --server https://${MASTER_NODE} --config=/etc/origin/master/admin.kubeconfig" > ${TICKET_ID}_metrics-master.txt
ssh ${MASTER_NODE} "oc get --raw /metrics --server https://${MASTER_NODE}:8444   --config=/etc/origin/master/admin.kubeconfig" > ${TICKET_ID}_more-metrics-master.txt

################# DATA IN NODES #######################
#ssh ${WORKERS} << EOF
#    yum install sos -y
#    yum update sos
#    sosreport --ticket-number ${TICKET_ID}
#EOF
#SOSREPORT_NODE=$(ssh ${WORKERS} "ls -t /var/tmp | grep sosreport | head -n1")
#scp ${WORKERS}:/var/tmp/${SOSREPORT_NODE} /root/sosreport/${TICKET_ID}_${SOSREPORT_NODE}


for NODE in ${WORKERS}
do
  ssh ${NODE} "yum install sos -y; yum update sos; sosreport --ticket-number ${TICKET_ID}"

  SOSREPORT_NODE=$(ssh ${NODE} "ls -t /var/tmp | grep sos | head -n1")
  scp ${NODE}:/var/tmp/${SOSREPORT_NODE} /root/sosreport/${TICKET_ID}_${SOSREPORT_NODE}
  ssh ${MASTER_NODE} "oc get --raw /metrics --server https://${NODE}:10250  --config=/etc/origin/master/admin.kubeconfig" > ${TICKET_ID}_metrics-${NODE}.txt
  ssh ${MASTER_NODE} "oc get --raw /metrics/cadvisor --server https://${NODE}:10250 --config=/etc/origin/master/admin.kubeconfig" > ${TICKET_ID}_metrics-cadvisor-${NODE}.txt
  ssh ${MASTER_NODE} "oc describe node ${NODE}" > ${TICKET_ID}_describe-node-${NODE}.txt
done

