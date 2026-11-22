-- Phase 3: Query & Report Development (SQLite)
-- Run after schema.sql (tables + demo data are loaded).

-- Report 1: Monthly lost/found summary
SELECT strftime('%Y-%m', event_date)                        AS month,
       SUM(type = 'lost')                                   AS lost_reports,
       SUM(type = 'found')                                  AS found_reports,
       SUM(status IN ('claimed','returned'))                AS resolved,
       SUM(status = 'rejected')                             AS rejected,
       COUNT(*)                                             AS total
FROM items
GROUP BY month
ORDER BY month;

-- Report 2: Claim slip for one student (change the student_id)
SELECT p.student_id, p.full_name, i.title AS item, i.type,
       c.status AS claim_status, c.created_at AS claimed_on,
       c.reviewed_at, COALESCE(c.admin_note, '-') AS admin_note
FROM claims c
JOIN student_profiles p ON p.user_id = c.claimant_id
JOIN items i            ON i.id = c.item_id
WHERE p.student_id = 'CS2601'
ORDER BY c.created_at;

-- Report 3: Unclaimed items older than 30 days (needs follow-up by admin)
SELECT i.id, i.title, i.type, c.name AS category, l.name AS location, i.event_date,
       CAST(julianday('now') - julianday(i.event_date) AS INTEGER) AS days_old
FROM items i
JOIN categories c ON c.id = i.category_id
JOIN locations  l ON l.id = i.location_id
WHERE i.status = 'approved'
  AND julianday('now') - julianday(i.event_date) > 30
ORDER BY days_old DESC;

-- Report 4: Recovery rate per category
SELECT c.name AS category,
       COUNT(*) AS total_reports,
       SUM(i.status IN ('claimed','returned')) AS recovered,
       ROUND(100.0 * SUM(i.status IN ('claimed','returned')) / COUNT(*), 1) AS recovery_pct
FROM items i JOIN categories c ON c.id = i.category_id
GROUP BY c.name
ORDER BY recovery_pct DESC;

-- Report 5: Using the view
SELECT * FROM v_item_details WHERE status = 'approved' ORDER BY event_date DESC LIMIT 10;
