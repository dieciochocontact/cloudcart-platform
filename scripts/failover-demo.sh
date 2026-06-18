#!/bin/bash
# VaultPay Platform - Failover Demo Script
# Stops one instance and shows ALB continues serving traffic

ALB_DNS="vaultpay-dev-alb-355929396.us-east-1.elb.amazonaws.com"
TG_ARN=$(aws elbv2 describe-target-groups --names vaultpay-dev-tg --query 'TargetGroups[0].TargetGroupArn' --output text)

echo "=== VaultPay Failover Demo ==="
echo ""
echo "Step 1: All instances healthy"
aws elbv2 describe-target-health --target-group-arn $TG_ARN \
  --query 'TargetHealthDescriptions[*].[Target.Id,TargetHealth.State]' --output table

echo ""
echo "Step 2: Stopping first instance to simulate failure..."
INSTANCE_1=$(aws elbv2 describe-target-health --target-group-arn $TG_ARN \
  --query 'TargetHealthDescriptions[0].Target.Id' --output text)
aws ec2 stop-instances --instance-ids $INSTANCE_1 > /dev/null
echo "Instance $INSTANCE_1 stopped"

echo ""
echo "Step 3: ALB still serving traffic (no downtime)..."
sleep 5
for i in {1..5}; do
  echo -n "Request $i: "
  curl -s "http://$ALB_DNS/health" | python3 -c "import sys,json; d=json.load(sys.stdin); print(f'Instance {d[\"instance\"]} - {d[\"az\"]}')"
done

echo ""
echo "Step 4: Checking target health (one should be unhealthy)..."
sleep 30
aws elbv2 describe-target-health --target-group-arn $TG_ARN \
  --query 'TargetHealthDescriptions[*].[Target.Id,TargetHealth.State]' --output table

echo ""
echo "Step 5: Restarting instance..."
aws ec2 start-instances --instance-ids $INSTANCE_1 > /dev/null
echo "Instance $INSTANCE_1 restarting..."
echo ""
echo "Failover demo complete! ALB served traffic throughout the failure."