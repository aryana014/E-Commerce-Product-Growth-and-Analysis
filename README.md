# 📊 E-Commerce Product Growth & Retention Analysis

> Analyzed **100K+ real e-commerce transactions** from Olist (Brazil's largest marketplace connector) using SQL to uncover actionable product and growth insights — the kind of analysis a PM or Growth Lead does on Day 1 to understand business health, retention levers, and strategic risks.

---

## 🎯 Why This Analysis?

Every marketplace faces the same fundamental questions: *Are customers coming back? What drives satisfaction? Where is revenue concentrated? Which bets should we double down on?* This project answers all of them with data, and translates each finding into a concrete product recommendation.

---

## 📦 Dataset

| Detail | Info |
|--------|------|
| **Source** | [Brazilian E-Commerce Public Dataset by Olist](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce) |
| **Size** | 100K+ orders across 8 relational tables |
| **Period** | September 2016 — August 2018 |
| **Scope** | Orders, payments, reviews, products, sellers, geolocation |

### Data Model

```
customers ──→ orders ──→ order_items ──→ products
                │              │
                │              └──→ sellers
                │
                ├──→ order_payments
                └──→ order_reviews
```

---

## 🔍 Key Findings & Recommendations

### 1. 🔴 Retention Crisis — 97% of Customers Never Return

Only ~3% of customers made a repeat purchase across the entire dataset. Repeat buyers, however, showed **~2.8x higher lifetime value** than one-time buyers, confirming that retention is the single highest-leverage growth opportunity.

Among the small repeat-buyer cohort, most returned within **30-90 days** of their first purchase — defining the critical reactivation window.

**Recommendation:** Implement automated post-purchase email sequences with personalized product recommendations, triggered within 7 days of delivery. Introduce a first-repeat-purchase incentive (e.g., 10% off within 60 days) to convert one-time buyers during the 30-90 day reactivation window.

📄 **Query:** [`queries/01_customer_retention.sql`](queries/01_customer_retention.sql)

---

### 2. 📉 Delivery Time is the #1 Satisfaction Killer

| Delivery Window | Avg Review | % 1-Star | % 5-Star |
|----------------|-----------|----------|----------|
| 0-7 days | ~4.3 ★ | ~5% | ~65% |
| 8-14 days | ~4.0 ★ | ~9% | ~52% |
| 15-21 days | ~3.4 ★ | ~20% | ~35% |
| 22-30 days | ~2.8 ★ | ~33% | ~22% |
| 30+ days | ~2.2 ★ | ~48% | ~15% |

A clear **satisfaction cliff exists between day 14 and day 21** — after which 1-star review rates spike dramatically. States farther from major logistics hubs (São Paulo) experience systematically worse delivery times and lower satisfaction.

**Recommendation:** Set a proactive customer notification trigger at day 12 post-purchase. For orders projected to exceed 21 days, offer an estimated delivery update plus a small credit — preventing a 1-star review is far cheaper than acquiring a new customer.

📄 **Query:** [`queries/02_delivery_vs_satisfaction.sql`](queries/02_delivery_vs_satisfaction.sql)

---

### 3. 💔 Broken Promises Hurt More Than Slow Delivery

On-time deliveries averaged **~4.2★** regardless of absolute speed. Orders that arrived **15+ days late vs. the estimate** crashed to **~1.8★** — and these generated **3x the negative review rate** of on-time orders.

Interestingly, orders that arrived **significantly earlier** than the estimate (8+ days early) scored the highest satisfaction of any cohort, suggesting customers experience genuine delight from exceeded expectations.

**Recommendation:** Pad delivery estimates by 3-5 days to systematically under-promise and over-deliver. The satisfaction boost from "arriving early" far outweighs the marginal cost of quoting a longer window. For orders at risk of missing their estimate, trigger proactive apology communications before the customer notices.

📄 **Query:** [`queries/03_late_delivery_analysis.sql`](queries/03_late_delivery_analysis.sql)

---

### 4. ⚠️ Revenue is Dangerously Concentrated in Top Sellers

| Seller Tier | % of Sellers | % of Platform Revenue |
|-------------|-------------|----------------------|
| Top 1% | ~1% | ~15-20% |
| Top 10% | ~10% | ~55-60% |
| Top 25% | ~25% | ~78-82% |
| Bottom 75% | ~75% | ~18-22% |

The **top 10% of sellers contribute ~58% of total GMV** — a significant platform dependency. Additionally, a notable segment of high-revenue sellers has below-average review scores ("At Risk" sellers), meaning they drive revenue while potentially damaging the platform brand.

**Recommendation:**
1. Launch a tiered seller loyalty program with reduced commission and priority placement for top-quartile sellers to prevent churn.
2. Assign dedicated account managers to the top 50 sellers.
3. For "At Risk" sellers (high revenue + low ratings), mandate quality improvement plans with review-score targets.
4. Actively recruit mid-tier sellers in high-demand categories to dilute concentration risk.

📄 **Query:** [`queries/04_seller_concentration.sql`](queries/04_seller_concentration.sql)

---

### 5. 💎 High-AOV Categories Are Underexplored

Top revenue categories (Bed/Bath/Table, Health/Beauty) dominate by volume but have moderate AOV (~R$100-120). Meanwhile, categories like **Watches, Computers, and Electronics** show **2x+ higher AOV (R$200+)** with comparable or better satisfaction scores — representing underexplored high-margin growth opportunities.

A strategic quadrant analysis reveals:
- **★ High Opportunity:** High AOV + High satisfaction (e.g., Watches) → Invest in seller acquisition
- **⚠ Fix Quality:** High AOV + Low satisfaction (e.g., some electronics) → Investigate fulfillment issues
- **→ Volume Play:** Low AOV + High satisfaction (e.g., Health/Beauty) → Focus on basket-size growth
- **✗ Deprioritize:** Low AOV + Low satisfaction → Reduce investment

**Recommendation:** Increase seller acquisition in "High Opportunity" categories to improve blended margins. For volume categories, introduce "frequently bought together" bundles to increase basket size without requiring new customer acquisition.

📄 **Query:** [`queries/05_category_performance.sql`](queries/05_category_performance.sql)

---

### 6. 📈 Growth is Volume-Driven, Not Value-Driven

The platform grew **~12-15% MoM** during peak periods (2017-2018), but **AOV stayed flat at ~R$150-160** throughout — meaning growth was entirely driven by new customer acquisition rather than extracting more value per transaction.

Credit cards dominate payments (~75%) with an average installment count of ~3-4, signaling price-sensitive buyers. Purchase activity peaks on **weekday afternoons (Mon-Wed)** with a notable weekend dip.

**Recommendation:**
1. Launch cross-sell features (bundles, "customers also bought") and minimum-cart thresholds for free shipping to grow AOV.
2. Introduce weekend-specific flash deals to smooth demand and capture underutilized weekend traffic.
3. Explore BNPL (Buy Now Pay Later) integration to reduce purchase friction given the heavy installment usage.

📄 **Query:** [`queries/06_monthly_trends.sql`](queries/06_monthly_trends.sql)

---

## 🛠️ Tools & SQL Concepts Used

| Category | Details |
|----------|---------|
| **Database** | MySQL 8.0 |
| **Key SQL** | JOINs (INNER, LEFT), CTEs, Window Functions (ROW_NUMBER, LAG, SUM OVER), CASE statements, Subqueries, Date Functions (DATEDIFF, DATE_FORMAT), GROUP BY + HAVING |
| **Visualization** | Power BI |

---

## 📂 Repository Structure

```
├── README.md                                 ← You are here
├── queries/
│   ├── 01_customer_retention.sql             ← Repeat purchase & LTV analysis
│   ├── 02_delivery_vs_satisfaction.sql       ← Delivery speed impact on reviews
│   ├── 03_late_delivery_analysis.sql         ← Promise vs. reality analysis
│   ├── 04_seller_concentration.sql           ← Revenue risk & seller segmentation
│   ├── 05_category_performance.sql           ← Category opportunity mapping
│   └── 06_monthly_trends.sql                 ← Growth trajectory & payment trends
├── setup/
│   ├── 01_create_tables.sql                  ← Database schema
│   └── 02_load_data.sql                      ← CSV import commands
└── visualizations/                           ← Charts and dashboards
```

---

## 🚀 How to Reproduce

1. Download the dataset from [Kaggle](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce)
2. Install MySQL 8.0 and open MySQL Workbench
3. Run `setup/01_create_tables.sql` to create the schema
4. Update file paths in `setup/02_load_data.sql` and run to import CSVs
5. Execute queries in the `queries/` folder sequentially

---

## 📌 If I Were the PM at Olist — Priority Roadmap

Based on the analysis, here's how I'd prioritize:

| Priority | Initiative | Expected Impact | Effort |
|----------|-----------|----------------|--------|
| **P0** | Proactive delay notifications at day 12 | Reduce 1-star reviews by ~20-30% | Low |
| **P0** | Pad delivery estimates by 3-5 days | Increase "arrived early" delight rate | Low |
| **P1** | Post-purchase reactivation email flow | Target 3% → 8% repeat purchase rate | Medium |
| **P1** | Seller quality improvement for "At Risk" sellers | Improve platform NPS | Medium |
| **P2** | Cross-sell bundles and cart-size incentives | Increase AOV from R$155 → R$185+ | Medium |
| **P2** | Seller acquisition in high-AOV categories | Improve blended margin | High |
| **P3** | Weekend flash deal program | +10-15% weekend order volume | Low |

---

*Built by [Aryan Agrawal](https://github.com/aryana014) as a product analytics case study.*
