-- Q6: How much is owed to each partner per event, and in total?
-- share: what each partner earned per event from their designs
-- paid:  what has been paid to them per event
WITH share AS (
    SELECT pa.partner_id,
           o.event_id,
           SUM(oi.quantity)                                                      AS units_sold,
           ROUND(SUM(oi.quantity * (oi.unit_price - c.avg_unit_cost)), 2)        AS profit_on_designs,
           ROUND(SUM(oi.quantity * (oi.unit_price - c.avg_unit_cost)
                     * pa.share_pct / 100), 2)                                   AS share_earned
    FROM order_items oi
    JOIN orders o           USING (order_id)
    JOIN products p         USING (product_id)
    JOIN v_type_avg_cost c  USING (product_type_id)
    JOIN partners pa        USING (partner_id)
    GROUP BY pa.partner_id, o.event_id
),
paid AS (
    SELECT partner_id, event_id, SUM(amount) AS paid
    FROM partner_payments
    GROUP BY partner_id, event_id
)
SELECT pa.name                                          AS partner,
       e.name                                           AS event,
       COALESCE(s.units_sold, 0)                        AS units_sold,
       COALESCE(s.profit_on_designs, 0)                 AS profit_on_designs,
       COALESCE(s.share_earned, 0)                      AS share_earned,
       COALESCE(pd.paid, 0)                             AS paid,
       COALESCE(s.share_earned, 0) - COALESCE(pd.paid, 0) AS balance_owed
FROM partners pa
CROSS JOIN events e                                  -- every partner x every event
LEFT JOIN share s ON s.partner_id = pa.partner_id AND s.event_id = e.event_id
LEFT JOIN paid pd ON pd.partner_id = pa.partner_id AND pd.event_id = e.event_id
ORDER BY pa.name, e.start_date;

-- Q6b: Total owed to each partner across everything (includes payments not tied to an event).
SELECT pa.name                                                  AS partner,
       COALESCE(s.earned, 0)                                    AS total_earned,
       COALESCE(pd.paid, 0)                                     AS total_paid,
       COALESCE(s.earned, 0) - COALESCE(pd.paid, 0)             AS balance_owed
FROM partners pa
LEFT JOIN (SELECT p.partner_id,
                  ROUND(SUM(oi.quantity * (oi.unit_price - c.avg_unit_cost) * pa2.share_pct / 100), 2) AS earned
           FROM order_items oi
           JOIN products p         USING (product_id)
           JOIN v_type_avg_cost c  USING (product_type_id)
           JOIN partners pa2       USING (partner_id)
           GROUP BY p.partner_id) s USING (partner_id)
LEFT JOIN (SELECT partner_id, SUM(amount) AS paid
           FROM partner_payments GROUP BY partner_id) pd USING (partner_id)
ORDER BY pa.name;