# 🚨 Problem Statement 1

# Hidden Subscription & Recurring Payment Leak Detector

## Background

Most people are quietly losing money every month due to subscriptions they forgot about, price hikes they never noticed, and services they no longer use—buried inside cluttered bank statements, SMS alerts, and email inboxes that no one has time to review line by line.

---

## Objective

Build a system that scans a user's transaction history (bank statements, SMS alerts, or email notifications) to automatically detect every recurring subscription or payment.

The system should:

- Detect every recurring subscription or payment.
- Flag silent price increases over time.
- Identify subscriptions that have gone unused.
- Present a clear **Leak Score**.
- Provide a concrete action plan for each subscription:
  - ❌ Cancel
  - ⬇️ Downgrade
  - 🤝 Renegotiate

---

## Suggested Focus Areas

- **Recurring Transaction Detection**
  - Detect recurring transactions from unstructured bank statement, SMS, and email data.

- **Price Increase & Anomaly Detection**
  - Identify silent price hikes and anomalies over time.

- **Leak Score**
  - Calculate a leak score with category-wise cost visualization.

- **Actionable Recommendations**
  - Provide per-subscription cancellation, downgrade, or renegotiation guidance.

---