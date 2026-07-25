# SubSense Scoring System Specification

This document details the scoring algorithm used to calculate the **Financial Health Score** (or **Leak Score**) of a user's subscription profile.

## Core Scoring Formula

The score is calculated out of 100, and clamped between **15 and 98** to align with the visual gauges.

### Parameters & Deductions

1. **Base Score**: `100`
2. **Leakage Ratio Penalty (Max -50 points)**:
   - Calculated as: `50 * (Leakage Amount / Total Subscription Spend)`
   - *Leakage Amount* is the sum of the cost of subscriptions with a recommended action of `Cancel` or `Downgrade`.
3. **Price Hike Penalty**:
   - `-5` points for every subscription that has detected a recent price hike.
4. **Duplicate Subscriptions Penalty**:
   - `-10` points for every set of duplicate subscriptions in the same category (e.g., multiple streaming platforms).
5. **High-Cost Non-Essential Penalty**:
   - `-5` points for each `Cancel`-recommended subscription whose monthly cost is greater than `₹500`.

### Mathematical Representation

$$ \text{Raw Score} = 100 - \text{Leakage Ratio Penalty} - \text{Price Hike Penalties} - \text{Duplicate Penalties} - \text{High Cost Penalties} $$
$$ \text{Final Score} = \text{Clamp}(\text{Raw Score}, 15, 98) $$

---

## Open Questions & Doubts

1. **Calculation Location**:
   - Currently, the dashboard and the Simulator recalculate the score dynamically on the client side when toggling checkboxes.
   - Do you want us to implement this logic purely client-side in the Flutter app (`AnalysisProvider`), or also calculate and return a baseline score from the FastAPI backend?
2. **Deduction Weights**:
   - Are the proposed penalties (e.g. -5 for price hikes, -10 for duplicates) aligned with your expectations, or should we adjust the weights?
3. **UI Cost Breakdown**:
   - Should we add a small visual breakdown of these deductions (e.g., "-10 for duplicates") to the dashboard or Simulator screen, or keep the UI display strictly to the radial gauge?
