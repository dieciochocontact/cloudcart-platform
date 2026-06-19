# Demo Script - VaultPay Platform

## Presentation Flow (15 minutes)

1. Title & Introduction (1 min)
2. Agenda (30 sec)
3. Problem / Solution (1.5 min)
4. Architecture Diagram (2 min)
5. Request Lifecycle (1.5 min)
6. [Live demo placeholder slide - narrate at the end]
7. Security Deep Dive (2 min)
8. Monitoring Deep Dive (1.5 min)
9. CI/CD Deep Dive (1.5 min)
10. Challenges & Lessons Learned (2 min)
11. Results & Costs (1.5 min)
12. Closing & Roadmap (1 min)
13. Live Demo (3 min)
14. Q&A (3 min)

## Live Demo Steps

1. Open browser to: http://vaultpay-dev-alb-355929396.us-east-1.elb.amazonaws.com
2. Click "Health Check" -> show instance ID and AZ
3. Click "Database Status" -> show live RDS PostgreSQL connection
4. Click "Live Metrics" -> show real-time CPU and alarm states from CloudWatch
5. (If time allows) Run ./scripts/stress-test.sh from terminal, click "Live Metrics" again to show CPU rising
6. (Optional) Show GitHub Actions pipeline (green build)
7. (Optional) Show AWS Console: CloudWatch Dashboard, Auto Scaling Group, Security Hub

## Backup Plan

If the live demo fails (network issues, AWS console unavailable):
- Use screenshots in screenshots/ folder: vaultpay-web-demo.png
- Walk through the architecture diagram instead and explain what each button would show

## Full Narration Script

See README.md and ARCHITECTURE.md for technical reference during Q&A.

The complete slide-by-slide spoken script is maintained separately and delivered in English, simple sentence structure, designed for a 15-minute talk.