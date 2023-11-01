#!/usr/bin/env bash

sleep 60
sudo tcpdump --version

mount_s3_download_link="https://s3.amazonaws.com/mountpoint-s3-release/latest/x86_64/mount-s3.rpm"
sudo wget $mount_s3_download_link
sudo yum install mount-s3.rpm -y
sudo mount-s3 --version
sudo mkdir /home/ec2-user/packet-captures
sudo mount-s3 ${TCPDUMP_STORAGE_S3_BUCKET} /home/ec2-user/packet-captures/ --prefix "packet-captures/" --dir-mode 0777

sudo mkdir /home/ec2-user/scripts

aws s3 cp ${TCPDUMP_RUN_SCRIPT_PATH} /home/ec2-user/scripts/run_tcpdump.sh
cd /home/ec2-user/scripts
chmod +x run_tcpdump.sh

aws s3 cp ${TCPDUMP_SVC_ALERTS_SCRIPT_PATH} /home/ec2-user/scripts/tm_pktcap_alerts.sh
cd /home/ec2-user/scripts
chmod +x tm_pktcap_alerts.sh

sudo -i
sudo cat << EOF >> /lib/systemd/system/trafficmirror-tcpdump.service
[Unit]
Description=TCP Dump service for Traffic Mirroring
StartLimitIntervalSec=30
StartLimitBurst=2
OnFailure=trafficmirror-svc-alerts.service

[Service]
ExecStart=/usr/bin/bash /home/ec2-user/scripts/run_tcpdump.sh
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF


sudo cat << EOF >> /lib/systemd/system/trafficmirror-svc-alerts.service
[Unit]
Description=Alerts service if there are issues related to trafficmirror-tcpdump.service
Requires=trafficmirror-tcpdump.service

[Service]
Type=oneshot
ExecStart=/usr/bin/bash /home/ec2-user/scripts/tm_pktcap_alerts.sh ${TCPDUMP_SVC_ALERTS_SNS_ARN}
EOF


sudo chmod 644 /lib/systemd/system/trafficmirror-tcpdump.service
sudo chmod 644 /lib/systemd/system/trafficmirror-svc-alerts.service

sudo systemctl daemon-reload

sudo systemctl enable trafficmirror-tcpdump.service
sudo systemctl enable trafficmirror-svc-alerts.service

sudo systemctl start trafficmirror-tcpdump.service
sudo systemctl start trafficmirror-svc-alerts.service

sudo systemctl status trafficmirror-tcpdump.service
sudo systemctl status trafficmirror-svc-alerts.service
