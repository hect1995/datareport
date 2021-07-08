#!/bin/bash

TICKET_ID=000110010

################## DATA IN MASTER #####################
ssh ocp3mst1.ocp3.rhbcnconsulting.com << EOF
  install sos -y
  yum update sos
  sosreport --ticket-number $TICKET_ID
EOF

SOSREPORT_MASTER=$(ssh ocp3mst1.ocp3.rhbcnconsulting.com "ls -t /var/tmp | grep sos | head -n1")
mkdir /root/sosreport
scp ocp3mst1.ocp3.rhbcnconsulting.com:/var/tmp/${SOSREPORT_MASTER} /root/sosreport/${SOSREPORT_MASTER}

ssh ocp3mst1.ocp3.rhbcnconsulting.com "oc get node,hostsubnet -o wide" > ${TICKET_ID}_node-hostsubnet.txt
ssh ocp3mst1.ocp3.rhbcnconsulting.com "oc describe nodes" > ${TICKET_ID}_describe-nodes.txt
ssh ocp3mst1.ocp3.rhbcnconsulting.com "oc get all,events  -o wide -n default" > ${TICKET_ID}_events-and-all.txt
ssh ocp3mst1.ocp3.rhbcnconsulting.com "oc get --raw /metrics --server https://ocp3mst1.ocp3.rhbcnconsulting.com   --config=/etc/origin/master/admin.kubeconfig" > ${TICKET_ID}_metrics-master.txt
ssh ocp3mst1.ocp3.rhbcnconsulting.com "oc get --raw /metrics --server https://ocp3mst1.ocp3.rhbcnconsulting.com:8444   --config=/etc/origin/master/admin.kubeconfig" > ${TICKET_ID}_more-metrics-master.txt

################# DATA IN NODES #######################
for NODE in ocp3inf1.ocp3.rhbcnconsulting.com ocp3inf2.ocp3.rhbcnconsulting.com ocp3inf3.ocp3.rhbcnconsulting.com
do
  echo "BITCCHHHH"
  ssh ${NODE} "yum install sos -y; yum update sos; sosreport --ticket-number ${TICKET_ID}"
  echo "HOOOOLLLLA"
  SOSREPORT_NODE=$(ssh ${NODE} "ls -t /var/tmp | grep sos | head -n1")
  scp ${NODE}:/var/tmp/${SOSREPORT_NODE} /root/sosreport/${TICKET_ID}_${SOSREPORT_NODE}
  ssh ocp3mst1.ocp3.rhbcnconsulting.com "oc get --raw /metrics --server https://{NODE}:10250  --config=/etc/origin/master/admin.kubeconfig" > ${TICKET_ID}_metrics-${NODE}.txt
  ssh ocp3mst1.ocp3.rhbcnconsulting.com "oc get --raw /metrics/cadvisor --server https://{NODE}:10250 --config=/etc/origin/master/admin.kubeconfig" > ${TICKET_ID}_metrics-cadvisor-${NODE}.txt
  ssh ocp3mst1.ocp3.rhbcnconsulting.com "oc describe node ${NODE}" > ${TICKET_ID}_describe-node-${NODE}.txt
done
