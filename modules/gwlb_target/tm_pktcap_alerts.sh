#!/bin/bash

# Send TCP Dump PCAP files to S3
echo "Packet Capture service alert..."
LOG_LOCATION="/home/ec2-user"
exec > $LOG_LOCATION/tm_pktcap_alerts_log.txt 2>&1

# Get instance id
TOKEN=`curl -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600"`
INSTANCE_ID=`curl http://169.254.169.254/latest/meta-data/instance-id -H "X-aws-ec2-metadata-token: $TOKEN"`
echo $INSTANCE_ID

TCPDUMP_SVC_ALERTS_SNS_ARN="$1";
echo $TCPDUMP_SVC_ALERTS_SNS_ARN

EC2_AVAIL_ZONE=`curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone -H "X-aws-ec2-metadata-token: $TOKEN"`
EC2_REGION="`echo \"$EC2_AVAIL_ZONE\" | sed 's/[a-z]$//'`"
echo $EC2_REGION

sleep 60
TCPDUMP_SVC_STATUS="$(systemctl is-active trafficmirror-tcpdump.service)"

if [ "${TCPDUMP_SVC_STATUS}" = "active" ]; then
    aws sns publish --region $EC2_REGION --topic-arn $TCPDUMP_SVC_ALERTS_SNS_ARN --message "TCP Dump service is successfully running on Traffic Mirror agent $INSTANCE_ID."
else 
    aws sns publish --region $EC2_REGION --topic-arn $TCPDUMP_SVC_ALERTS_SNS_ARN --message "TCP Dump service ran into an issue in the Traffic Mirror agent $INSTANCE_ID. Please login to the instance and resolve it soon."
fi

