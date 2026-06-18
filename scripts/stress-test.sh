#!/bin/bash
# VaultPay Platform - Stress Test Script
# Simulates high traffic to trigger CloudWatch CPU alarms

ALB_DNS="vaultpay-dev-alb-355929396.us-east-1.elb.amazonaws.com"

echo "=== VaultPay Stress Test ==="
echo "Sending 1000 requests to $ALB_DNS"
echo "Watch CloudWatch alarms fire at 80% CPU"
echo ""

for i in {1..1000}; do
  curl -s "http://$ALB_DNS" > /dev/null &
  if [ $((i % 100)) -eq 0 ]; then
    echo "Sent $i requests..."
  fi
done

wait
echo ""
echo "Stress test complete - check CloudWatch dashboard for CPU spike"