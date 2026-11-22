-- Phase 4: Test cases (SQLite). Run each block separately and note the result.
PRAGMA foreign_keys = ON;

-- T1 duplicate claim by same student on same item  -> EXPECT: UNIQUE constraint failed
INSERT INTO claims(item_id, claimant_id, proof) VALUES (5, 3, 'duplicate test proof');

-- T2 invalid role  -> EXPECT: CHECK constraint failed
INSERT INTO users(email, password_hash, role) VALUES ('x@campus.edu', 'h', 'superuser');

-- T3 invalid item status  -> EXPECT: CHECK constraint failed
UPDATE items SET status = 'deleted' WHERE id = 1;

-- T4 item with non-existent category  -> EXPECT: FOREIGN KEY constraint failed
INSERT INTO items(type,title,description,category_id,location_id,event_date,reported_by)
VALUES ('lost','Test','Test',999,1,'2026-11-01',3);

-- T5 delete a category that is in use  -> EXPECT: FOREIGN KEY constraint failed (ON DELETE RESTRICT)
DELETE FROM categories WHERE id = 1;

-- T6 duplicate email  -> EXPECT: UNIQUE constraint failed
INSERT INTO users(email, password_hash) VALUES ('jiya.gupta@campus.edu', 'h');

-- T7 trigger: approving a pending report creates a notification  -> EXPECT: 1 new row for user 13
BEGIN;
UPDATE items SET status = 'approved', admin_note = 'Verified' WHERE id = 3;
SELECT user_id, title, message FROM notifications ORDER BY id DESC LIMIT 1;
ROLLBACK;

-- T8 cascade delete: removing a student removes their reports -> EXPECT: count becomes 0, then ROLLBACK restores
BEGIN;
SELECT COUNT(*) AS reports_before FROM items WHERE reported_by = 3;
DELETE FROM users WHERE id = 3;
SELECT COUNT(*) AS reports_after FROM items WHERE reported_by = 3;
ROLLBACK;
SELECT COUNT(*) AS reports_after_rollback FROM items WHERE reported_by = 3;

-- T9 transaction: approve a claim and mark item claimed together, then ROLLBACK
-- EXPECT: inside the transaction both change; after ROLLBACK both are back to old values
BEGIN;
UPDATE claims SET status = 'approved', reviewed_at = CURRENT_TIMESTAMP WHERE id = 1;
UPDATE items  SET status = 'claimed' WHERE id = 1;
SELECT c.status AS claim_status, i.status AS item_status FROM claims c JOIN items i ON i.id=c.item_id WHERE c.id = 1;
ROLLBACK;
SELECT c.status AS claim_status, i.status AS item_status FROM claims c JOIN items i ON i.id=c.item_id WHERE c.id = 1;
