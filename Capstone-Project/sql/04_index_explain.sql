-- Phase 3: Index optimization with before/after query plans (SQLite)
-- Take a screenshot of the output of each EXPLAIN.

-- BEFORE: remove the index
DROP INDEX IF EXISTS idx_items_status_type;
EXPLAIN QUERY PLAN
SELECT id, title FROM items WHERE status = 'approved' AND type = 'lost';
-- Expected: SCAN items (full table scan)

-- AFTER: create the index again
CREATE INDEX idx_items_status_type ON items(status, type);
EXPLAIN QUERY PLAN
SELECT id, title FROM items WHERE status = 'approved' AND type = 'lost';
-- Expected: SEARCH items USING INDEX idx_items_status_type (status=? AND type=?)

-- Second example: notifications
DROP INDEX IF EXISTS idx_notif_user;
EXPLAIN QUERY PLAN SELECT * FROM notifications WHERE user_id = 3 AND is_read = 0;
CREATE INDEX idx_notif_user ON notifications(user_id, is_read);
EXPLAIN QUERY PLAN SELECT * FROM notifications WHERE user_id = 3 AND is_read = 0;
