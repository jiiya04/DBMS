DROP DATABASE IF EXISTS campus_lost_found;
CREATE DATABASE campus_lost_found CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE campus_lost_found;

CREATE TABLE users (
  id INT AUTO_INCREMENT PRIMARY KEY,
  email VARCHAR(120) NOT NULL UNIQUE,
  password_hash VARCHAR(200) NOT NULL,
  role ENUM('student','admin') NOT NULL DEFAULT 'student',
  status ENUM('active','suspended') NOT NULL DEFAULT 'active',
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);
CREATE TABLE student_profiles (
  user_id INT PRIMARY KEY,
  student_id VARCHAR(20) NOT NULL UNIQUE,
  full_name VARCHAR(100) NOT NULL,
  department VARCHAR(80),
  year_of_study TINYINT,
  phone VARCHAR(20),
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);
CREATE TABLE categories (
  id INT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(60) NOT NULL UNIQUE,
  description VARCHAR(255)
);
CREATE TABLE locations (
  id INT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(80) NOT NULL UNIQUE,
  description VARCHAR(255)
);
CREATE TABLE items (
  id INT AUTO_INCREMENT PRIMARY KEY,
  type ENUM('lost','found') NOT NULL,
  title VARCHAR(120) NOT NULL,
  description TEXT NOT NULL,
  category_id INT NOT NULL,
  location_id INT NOT NULL,
  event_date DATE NOT NULL,
  status ENUM('pending','approved','rejected','claimed','returned') NOT NULL DEFAULT 'pending',
  admin_note VARCHAR(255),
  reported_by INT NOT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (category_id) REFERENCES categories(id) ON DELETE RESTRICT,
  FOREIGN KEY (location_id) REFERENCES locations(id) ON DELETE RESTRICT,
  FOREIGN KEY (reported_by) REFERENCES users(id) ON DELETE CASCADE,
  INDEX idx_status_type (status, type),
  INDEX idx_category (category_id),
  INDEX idx_location (location_id),
  FULLTEXT INDEX ft_items (title, description)
);
CREATE TABLE item_images (
  id INT AUTO_INCREMENT PRIMARY KEY,
  item_id INT NOT NULL,
  image_url VARCHAR(500) NOT NULL,
  FOREIGN KEY (item_id) REFERENCES items(id) ON DELETE CASCADE
);
CREATE TABLE claims (
  id INT AUTO_INCREMENT PRIMARY KEY,
  item_id INT NOT NULL,
  claimant_id INT NOT NULL,
  proof TEXT NOT NULL,
  status ENUM('pending','approved','rejected') NOT NULL DEFAULT 'pending',
  admin_note VARCHAR(255),
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  reviewed_at TIMESTAMP NULL,
  UNIQUE KEY uq_claim (item_id, claimant_id),
  FOREIGN KEY (item_id) REFERENCES items(id) ON DELETE CASCADE,
  FOREIGN KEY (claimant_id) REFERENCES users(id) ON DELETE CASCADE
);
CREATE TABLE notifications (
  id INT AUTO_INCREMENT PRIMARY KEY,
  user_id INT NOT NULL,
  title VARCHAR(120) NOT NULL,
  message VARCHAR(500) NOT NULL,
  is_read TINYINT(1) NOT NULL DEFAULT 0,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  INDEX idx_user_read (user_id, is_read)
);
CREATE TABLE announcements (
  id INT AUTO_INCREMENT PRIMARY KEY,
  title VARCHAR(150) NOT NULL,
  body TEXT NOT NULL,
  created_by INT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE SET NULL
);
CREATE TABLE activity_logs (
  id INT AUTO_INCREMENT PRIMARY KEY,
  user_id INT NULL,
  action VARCHAR(60) NOT NULL,
  details VARCHAR(255),
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE SET NULL,
  INDEX idx_created (created_at)
);

-- View: item details joined with category, location and reporter
CREATE VIEW v_item_details AS
SELECT i.id, i.type, i.title, i.status, i.event_date, c.name AS category, l.name AS location, p.full_name AS reporter
FROM items i JOIN categories c ON c.id=i.category_id JOIN locations l ON l.id=i.location_id JOIN student_profiles p ON p.user_id=i.reported_by;

-- Trigger: notify the reporter automatically when an admin approves/rejects a pending report
DELIMITER $$
CREATE TRIGGER trg_item_review AFTER UPDATE ON items FOR EACH ROW
BEGIN
  IF OLD.status='pending' AND NEW.status IN ('approved','rejected') THEN
    INSERT INTO notifications(user_id,title,message)
    VALUES (NEW.reported_by, CONCAT('Report ',NEW.status),
      CONCAT('Your ',NEW.type,' report "',NEW.title,'" was ',NEW.status,'.',IFNULL(CONCAT(' Note: ',NEW.admin_note),'')));
  END IF;
END$$
DELIMITER ;

-- Demo data. Admin: sunita.rao@campus.edu / Admin@123 | Student: jiya.gupta@campus.edu / Student@123
USE campus_lost_found;

INSERT INTO categories(name,description) VALUES
('Electronics','Phones, laptops, chargers, earbuds'),
('Books & Stationery','Books, notebooks, calculators'),
('Clothing & Accessories','Jackets, caps, scarves, glasses'),
('ID & Cards','Student ID, library and bank cards'),
('Keys','Keys and key chains'),
('Bags & Wallets','Backpacks, purses, wallets'),
('Sports Equipment','Bats, rackets, bottles, shoes'),
('Other','Anything else');

INSERT INTO locations(name,description) VALUES
('Main Library','Reading halls and stacks'),
('Student Cafeteria','Food court and seating'),
('Engineering Block','Lecture halls and labs'),
('Science Block','Physics, chemistry and biology labs'),
('Sports Complex','Courts, gym and ground'),
('Auditorium','Events and seminars'),
('Hostel Gate','Main hostel entrance'),
('Computer Lab','Central computing facility'),
('Admin Building','Offices and reception'),
('Parking Area','Two-wheeler and car parking');

INSERT INTO users(email,password_hash,role,status,created_at) VALUES
('sunita.rao@campus.edu','dd4ac814232cfacdc32197e96916a19c:546c074c158754ffc7cb1e12fbc43ba0faa502434c0d236d11d46da06b3b03e7','admin','active','2026-08-01 09:00:00'),
('anil.kumar@campus.edu','c8f06a7b480e323002834146369f41be:e20c7ebab4ae4f22918678b7b58f7c62417c6b802844248a3a55b10bfd685f20','admin','active','2026-08-01 09:00:00'),
('jiya.gupta@campus.edu','848de32d31ef9198b494a7d00049cf83:8b6e4286e2ec38284f808da363c0c317d78815dc6067348fdad5bfe952022838','student','active','2026-08-03 10:00:00'),
('ananya.iyer@campus.edu','7ba640dbbe49553fddba2a8ce55b65e4:79973606a52a98b175765e543362c130a2e70a1a7daeb3000e932e6c82cd941a','student','active','2026-08-04 10:00:00'),
('kabir.malhotra@campus.edu','d5a647d74475afbbdc64f7fc41a15dfa:6bd7da12d5229cfa7bedbe1930a24a3cf639d27caf2ac7fc84d88be89688d18d','student','active','2026-08-05 10:00:00'),
('priya.nair@campus.edu','3d11383ce4b616461a91650fd4d7ed6e:aa3af8d20ed2acc3d5b08f29dd9626ba71514b8bd715df8c95ab731c49f85a89','student','active','2026-08-06 10:00:00'),
('vikram.singh@campus.edu','1fd144e87dc71b3a58c6bcdfbca720bf:398bbbef84e70cba2a78ab2d2a163f326e137e4bdf6802911821aeda5ebc0156','student','active','2026-08-07 10:00:00'),
('sneha.kulkarni@campus.edu','0268aad04339cf493388bae7841c3a0d:75963e599ff28e57d19ae0491434d61e734f1516e7602e3b7590f8e6c6e0443c','student','active','2026-08-08 10:00:00'),
('aditya.verma@campus.edu','db2f6ca3b74cdb69c3cd788e81eaeebe:37e2ab4f77a08265c146e08e20e3e9b8b6a26302df757e3914b998918b0c851b','student','active','2026-08-09 10:00:00'),
('neha.gupta@campus.edu','5b5b7723786eab25078a55940174f488:dc301a92f6dccfb15c0f95a7df4ec4ec5c7a72dc3e5ce5b2e0aa93e250b06d31','student','active','2026-08-10 10:00:00'),
('rahul.mehta@campus.edu','860bd62674f46b56fa1ba1f9915148af:15f1d0608cb994c55fd90554518450209da8dfdc287859c3a4a8ab61aaef72c3','student','active','2026-08-11 10:00:00'),
('pooja.reddy@campus.edu','97a6987a1e55b6ed44383a0497c050b9:8b21bc85f510498727fda950ac89c71e4978c4555874508de38fa20b1f85636d','student','active','2026-08-12 10:00:00'),
('karan.kapoor@campus.edu','4bfaf546b9f6640582269177b3854837:cf63da09a1689725ea51ec45c150db4acc458f7966ec2daf2a57b17aeb40f27a','student','active','2026-08-13 10:00:00'),
('divya.menon@campus.edu','e1d4fb411d135c1d507659b4eb2657b8:ad3f1d5aa795d82fb9955c66d03c443504a77522d23ff154df3793c9289c70bb','student','active','2026-08-14 10:00:00'),
('siddharth.joshi@campus.edu','b1bdc294592f9025ff9413fb538b41e1:b6b0d35d906d0d50b917c28822fe704bc90b2a379e1e27bffa9de1ebed7e6eb9','student','active','2026-08-15 10:00:00'),
('meera.pillai@campus.edu','68614de26ee8e416b5c1794f9d39d9e3:7b00cc505dc7081ffa0e6ce46d1dc92d497606eb741dafc3f38f929f2cfb3ef8','student','active','2026-08-16 10:00:00'),
('harsh.agarwal@campus.edu','31adc4c52d3b1f297093382a4552fa54:a63dbe596296197ebce6fd81d8cfd6dc12b673a4af1fdfb3710cdb1337a75a4e','student','active','2026-08-17 10:00:00'),
('tanvi.deshmukh@campus.edu','9191007816b0a78054476f8e0fdd104c:d61d1ca12966952f0a519c353a58ed32d157235cfd21aad55a2946e0102bbf84','student','active','2026-08-18 10:00:00'),
('nikhil.bansal@campus.edu','afe6bef6c3d6c9b22d85d602cd3482b3:a088c2b74cf732a1ba938656ce359880c1e858ec96444ea2f64a4a47fa387c78','student','active','2026-08-19 10:00:00'),
('ishita.chatterjee@campus.edu','d296ff451ef2deb6a8b01588f40393bb:5e642b8cd970099ed043c9f095de50c7dddc8db58bd565d8445a04971017381e','student','active','2026-08-20 10:00:00'),
('manish.yadav@campus.edu','cf33e41579feb4a437fd34c37c0d6f01:48d96109511afd47ac23b72a710e95ef563753135ac1ab35bc838102b4d9bd20','student','active','2026-08-21 10:00:00'),
('simran.kaur@campus.edu','689a0a2561506fb093627b5669c38240:59131954d2537a860939dd97cf40566cffac96e4b902dc25b1c66d495d32f783','student','active','2026-08-22 10:00:00'),
('varun.choudhary@campus.edu','111e9877a0012b36581b6b1138416d07:450720824409f5ce5fa7918f44b1f6e86acc0942ad38062536730ec5a8573824','student','active','2026-08-23 10:00:00'),
('riya.banerjee@campus.edu','39a3037278ad0d0faf158050b5c71351:0d810b1252ef205c83fb0c2f47150a283c2b5f73233a0efd9cbe90456ded2ff8','student','active','2026-08-24 10:00:00'),
('yash.patel@campus.edu','e10264ef4630ae3a56ec177bd3c9a49d:ea5a820eab089e41137049c2c61de52c8fc5a5627a74e62b26a5c8ddf4f0c489','student','active','2026-08-25 10:00:00'),
('aisha.khan@campus.edu','83d732def81d411fb1724ca441dfc4fa:61f38142226b9f8353e8dbbef744523b5b8ab49e953c95ebbec3dea8d8013577','student','suspended','2026-08-26 10:00:00');

INSERT INTO student_profiles(user_id,student_id,full_name,department,year_of_study,phone) VALUES
('1','ADM-01','Sunita Rao','Administration',NULL,'9000000000'),
('2','ADM-02','Anil Kumar','Administration',NULL,'9000000000'),
('3','CS2601','Jiya Gupta','Mechanical Engineering','2','9800000001'),
('4','CS2602','Ananya Iyer','Electronics','3','9800000002'),
('5','CS2603','Kabir Malhotra','Civil Engineering','4','9800000003'),
('6','CS2604','Priya Nair','Business Administration','1','9800000004'),
('7','CS2605','Vikram Singh','Physics','2','9800000005'),
('8','CS2606','Sneha Kulkarni','Computer Science','3','9800000006'),
('9','CS2607','Aditya Verma','Mechanical Engineering','4','9800000007'),
('10','CS2608','Neha Gupta','Electronics','1','9800000008'),
('11','CS2609','Rahul Mehta','Civil Engineering','2','9800000009'),
('12','CS2610','Pooja Reddy','Business Administration','3','9800000010'),
('13','CS2611','Karan Kapoor','Physics','4','9800000011'),
('14','CS2612','Divya Menon','Computer Science','1','9800000012'),
('15','CS2613','Siddharth Joshi','Mechanical Engineering','2','9800000013'),
('16','CS2614','Meera Pillai','Electronics','3','9800000014'),
('17','CS2615','Harsh Agarwal','Civil Engineering','4','9800000015'),
('18','CS2616','Tanvi Deshmukh','Business Administration','1','9800000016'),
('19','CS2617','Nikhil Bansal','Physics','2','9800000017'),
('20','CS2618','Ishita Chatterjee','Computer Science','3','9800000018'),
('21','CS2619','Manish Yadav','Mechanical Engineering','4','9800000019'),
('22','CS2620','Simran Kaur','Electronics','1','9800000020'),
('23','CS2621','Varun Choudhary','Civil Engineering','2','9800000021'),
('24','CS2622','Riya Banerjee','Business Administration','3','9800000022'),
('25','CS2623','Yash Patel','Physics','4','9800000023'),
('26','CS2624','Aisha Khan','Computer Science','1','9800000024');

INSERT INTO items(type,title,description,category_id,location_id,event_date,status,admin_note,reported_by,created_at) VALUES
('lost','Black wireless earbuds case','Black charging case with a small scratch on the lid.','1','3','2026-10-01','approved',NULL,'3','2026-10-01 12:00:00'),
('found','Blue water bottle','Blue steel bottle with a sticker on the side.','7','5','2026-10-02','approved',NULL,'8','2026-10-02 12:00:00'),
('lost','Student ID card','University student ID card in a clear holder.','4','1','2026-10-03','pending',NULL,'13','2026-10-03 12:00:00'),
('found','Set of keys','Three keys on a red key ring with a small tag.','5','7','2026-10-04','approved',NULL,'18','2026-10-04 12:00:00'),
('lost','Scientific calculator','Grey scientific calculator with a cracked cover.','2','4','2026-10-05','claimed',NULL,'23','2026-10-05 12:00:00'),
('found','Grey hoodie','Medium grey hoodie with a zipper.','3','2','2026-10-06','rejected','Insufficient details provided','4','2026-10-06 12:00:00'),
('lost','Laptop charger','65W charger with a white cable.','1','8','2026-10-07','approved',NULL,'9','2026-10-07 12:00:00'),
('found','Brown leather wallet','Brown wallet containing a few cards and papers.','6','2','2026-10-08','returned',NULL,'14','2026-10-08 12:00:00'),
('lost','Data Structures textbook','Hardcover textbook with handwritten notes.','2','1','2026-10-09','approved',NULL,'19','2026-10-09 12:00:00'),
('found','Black backpack','Black backpack with a blue zipper pull.','6','10','2026-10-10','approved',NULL,'24','2026-10-10 12:00:00'),
('lost','Prescription glasses','Round black-framed glasses in a soft case.','3','6','2026-10-11','pending',NULL,'5','2026-10-11 12:00:00'),
('found','USB flash drive 64GB','Silver USB drive with a lanyard.','1','8','2026-10-12','approved',NULL,'10','2026-10-12 12:00:00'),
('lost','Badminton racket','Red racket with a black grip.','7','5','2026-10-13','claimed',NULL,'15','2026-10-13 12:00:00'),
('found','Library card','Library membership card, slightly bent.','4','1','2026-10-14','rejected','Insufficient details provided','20','2026-10-14 12:00:00'),
('lost','Bike key','Single bike key with a rubber cover.','5','10','2026-10-15','approved',NULL,'25','2026-10-15 12:00:00'),
('found','Smartwatch','Black smartwatch with a fitness band.','1','3','2026-10-16','returned',NULL,'6','2026-10-16 12:00:00'),
('lost','Umbrella','Dark green foldable umbrella.','8','9','2026-10-17','approved',NULL,'11','2026-10-17 12:00:00'),
('found','Notebook (Physics)','Spiral notebook with a blue cover.','2','4','2026-10-18','approved',NULL,'16','2026-10-18 12:00:00'),
('lost','Wristwatch','Analog watch with a brown strap.','3','6','2026-10-19','pending',NULL,'21','2026-10-19 12:00:00'),
('found','Power bank','10000mAh white power bank.','1','2','2026-10-20','approved',NULL,'26','2026-10-20 12:00:00'),
('lost','Black wireless earbuds case','Black charging case with a small scratch on the lid.','1','3','2026-10-21','claimed',NULL,'7','2026-10-21 12:00:00'),
('found','Blue water bottle','Blue steel bottle with a sticker on the side.','7','5','2026-10-22','rejected','Insufficient details provided','12','2026-10-22 12:00:00'),
('lost','Student ID card','University student ID card in a clear holder.','4','1','2026-10-23','approved',NULL,'17','2026-10-23 12:00:00'),
('found','Set of keys','Three keys on a red key ring with a small tag.','5','7','2026-10-24','returned',NULL,'22','2026-10-24 12:00:00'),
('lost','Scientific calculator','Grey scientific calculator with a cracked cover.','2','4','2026-10-25','approved',NULL,'3','2026-10-25 12:00:00'),
('found','Grey hoodie','Medium grey hoodie with a zipper.','3','2','2026-10-26','approved',NULL,'8','2026-10-26 12:00:00'),
('lost','Laptop charger','65W charger with a white cable.','1','8','2026-10-27','pending',NULL,'13','2026-10-27 12:00:00'),
('found','Brown leather wallet','Brown wallet containing a few cards and papers.','6','2','2026-10-28','approved',NULL,'18','2026-10-28 12:00:00'),
('lost','Data Structures textbook','Hardcover textbook with handwritten notes.','2','1','2026-10-29','claimed',NULL,'23','2026-10-29 12:00:00'),
('found','Black backpack','Black backpack with a blue zipper pull.','6','10','2026-10-30','rejected','Insufficient details provided','4','2026-10-30 12:00:00'),
('lost','Prescription glasses','Round black-framed glasses in a soft case.','3','6','2026-10-31','approved',NULL,'9','2026-10-31 12:00:00'),
('found','USB flash drive 64GB','Silver USB drive with a lanyard.','1','8','2026-11-01','returned',NULL,'14','2026-11-01 12:00:00'),
('lost','Badminton racket','Red racket with a black grip.','7','5','2026-11-02','approved',NULL,'19','2026-11-02 12:00:00'),
('found','Library card','Library membership card, slightly bent.','4','1','2026-11-03','approved',NULL,'24','2026-11-03 12:00:00'),
('lost','Bike key','Single bike key with a rubber cover.','5','10','2026-11-04','pending',NULL,'5','2026-11-04 12:00:00'),
('found','Smartwatch','Black smartwatch with a fitness band.','1','3','2026-11-05','approved',NULL,'10','2026-11-05 12:00:00'),
('lost','Umbrella','Dark green foldable umbrella.','8','9','2026-11-06','claimed',NULL,'15','2026-11-06 12:00:00'),
('found','Notebook (Physics)','Spiral notebook with a blue cover.','2','4','2026-11-07','rejected','Insufficient details provided','20','2026-11-07 12:00:00'),
('lost','Wristwatch','Analog watch with a brown strap.','3','6','2026-11-08','approved',NULL,'25','2026-11-08 12:00:00'),
('found','Power bank','10000mAh white power bank.','1','2','2026-11-09','returned',NULL,'6','2026-11-09 12:00:00');

INSERT INTO claims(item_id,claimant_id,proof,status,admin_note,created_at,reviewed_at) VALUES
('1','7','It has my initials scratched inside; I lost it on the same day.','pending',NULL,'2026-10-01 17:00:00',NULL),
('5','3','I can describe unique marks and the exact contents of this item.','approved','Ownership verified at Admin Building','2026-10-05 15:00:00','2026-11-05 11:00:00'),
('5','8','I think this belongs to me, it looks like mine.','rejected','Could not verify ownership','2026-10-05 16:00:00','2026-11-05 11:30:00'),
('8','18','I can describe unique marks and the exact contents of this item.','approved','Ownership verified at Admin Building','2026-10-08 15:00:00','2026-11-08 11:00:00'),
('8','23','I think this belongs to me, it looks like mine.','rejected','Could not verify ownership','2026-10-08 16:00:00','2026-11-08 11:30:00'),
('9','23','It has my initials scratched inside; I lost it on the same day.','pending',NULL,'2026-10-09 17:00:00',NULL),
('13','19','I can describe unique marks and the exact contents of this item.','approved','Ownership verified at Admin Building','2026-10-13 15:00:00','2026-11-05 11:00:00'),
('13','24','I think this belongs to me, it looks like mine.','rejected','Could not verify ownership','2026-10-13 16:00:00','2026-11-05 11:30:00'),
('16','10','I can describe unique marks and the exact contents of this item.','approved','Ownership verified at Admin Building','2026-10-16 15:00:00','2026-11-08 11:00:00'),
('16','15','I think this belongs to me, it looks like mine.','rejected','Could not verify ownership','2026-10-16 16:00:00','2026-11-08 11:30:00'),
('17','15','It has my initials scratched inside; I lost it on the same day.','pending',NULL,'2026-10-17 17:00:00',NULL),
('21','11','I can describe unique marks and the exact contents of this item.','approved','Ownership verified at Admin Building','2026-10-21 15:00:00','2026-11-05 11:00:00'),
('21','16','I think this belongs to me, it looks like mine.','rejected','Could not verify ownership','2026-10-21 16:00:00','2026-11-05 11:30:00'),
('24','26','I can describe unique marks and the exact contents of this item.','approved','Ownership verified at Admin Building','2026-10-24 15:00:00','2026-11-08 11:00:00'),
('24','7','I think this belongs to me, it looks like mine.','rejected','Could not verify ownership','2026-10-24 16:00:00','2026-11-08 11:30:00'),
('25','7','It has my initials scratched inside; I lost it on the same day.','pending',NULL,'2026-10-25 17:00:00',NULL),
('29','3','I can describe unique marks and the exact contents of this item.','approved','Ownership verified at Admin Building','2026-10-29 15:00:00','2026-11-05 11:00:00'),
('29','8','I think this belongs to me, it looks like mine.','rejected','Could not verify ownership','2026-10-29 16:00:00','2026-11-05 11:30:00'),
('32','18','I can describe unique marks and the exact contents of this item.','approved','Ownership verified at Admin Building','2026-11-01 15:00:00','2026-11-08 11:00:00'),
('32','23','I think this belongs to me, it looks like mine.','rejected','Could not verify ownership','2026-11-01 16:00:00','2026-11-08 11:30:00'),
('33','23','It has my initials scratched inside; I lost it on the same day.','pending',NULL,'2026-11-02 17:00:00',NULL),
('37','19','I can describe unique marks and the exact contents of this item.','approved','Ownership verified at Admin Building','2026-11-06 15:00:00','2026-11-05 11:00:00'),
('37','24','I think this belongs to me, it looks like mine.','rejected','Could not verify ownership','2026-11-06 16:00:00','2026-11-05 11:30:00'),
('40','10','I can describe unique marks and the exact contents of this item.','approved','Ownership verified at Admin Building','2026-11-09 15:00:00','2026-11-08 11:00:00'),
('40','15','I think this belongs to me, it looks like mine.','rejected','Could not verify ownership','2026-11-09 16:00:00','2026-11-08 11:30:00');

INSERT INTO notifications(user_id,title,message,is_read,created_at) VALUES
('3','Welcome','Welcome to Campus Lost & Found!','1','2026-10-01 09:00:00'),
('3','Claim update','One of your claims has been reviewed. Check My Claims.','0','2026-11-05 10:00:00'),
('4','Welcome','Welcome to Campus Lost & Found!','1','2026-10-01 09:00:00'),
('4','Report approved','Your report was approved and is now visible to everyone.','0','2026-11-06 10:00:00'),
('5','Welcome','Welcome to Campus Lost & Found!','1','2026-10-01 09:00:00'),
('6','Welcome','Welcome to Campus Lost & Found!','1','2026-10-01 09:00:00'),
('6','Claim update','One of your claims has been reviewed. Check My Claims.','0','2026-11-05 10:00:00'),
('7','Welcome','Welcome to Campus Lost & Found!','1','2026-10-01 09:00:00'),
('8','Welcome','Welcome to Campus Lost & Found!','1','2026-10-01 09:00:00'),
('8','Report approved','Your report was approved and is now visible to everyone.','0','2026-11-06 10:00:00'),
('9','Welcome','Welcome to Campus Lost & Found!','1','2026-10-01 09:00:00'),
('9','Claim update','One of your claims has been reviewed. Check My Claims.','0','2026-11-05 10:00:00'),
('10','Welcome','Welcome to Campus Lost & Found!','1','2026-10-01 09:00:00'),
('11','Welcome','Welcome to Campus Lost & Found!','1','2026-10-01 09:00:00'),
('12','Welcome','Welcome to Campus Lost & Found!','1','2026-10-01 09:00:00'),
('12','Claim update','One of your claims has been reviewed. Check My Claims.','0','2026-11-05 10:00:00'),
('12','Report approved','Your report was approved and is now visible to everyone.','0','2026-11-06 10:00:00'),
('13','Welcome','Welcome to Campus Lost & Found!','1','2026-10-01 09:00:00'),
('14','Welcome','Welcome to Campus Lost & Found!','1','2026-10-01 09:00:00'),
('15','Welcome','Welcome to Campus Lost & Found!','1','2026-10-01 09:00:00'),
('15','Claim update','One of your claims has been reviewed. Check My Claims.','0','2026-11-05 10:00:00'),
('16','Welcome','Welcome to Campus Lost & Found!','1','2026-10-01 09:00:00'),
('16','Report approved','Your report was approved and is now visible to everyone.','0','2026-11-06 10:00:00'),
('17','Welcome','Welcome to Campus Lost & Found!','1','2026-10-01 09:00:00'),
('18','Welcome','Welcome to Campus Lost & Found!','1','2026-10-01 09:00:00'),
('18','Claim update','One of your claims has been reviewed. Check My Claims.','0','2026-11-05 10:00:00'),
('19','Welcome','Welcome to Campus Lost & Found!','1','2026-10-01 09:00:00'),
('20','Welcome','Welcome to Campus Lost & Found!','1','2026-10-01 09:00:00'),
('20','Report approved','Your report was approved and is now visible to everyone.','0','2026-11-06 10:00:00'),
('21','Welcome','Welcome to Campus Lost & Found!','1','2026-10-01 09:00:00'),
('21','Claim update','One of your claims has been reviewed. Check My Claims.','0','2026-11-05 10:00:00'),
('22','Welcome','Welcome to Campus Lost & Found!','1','2026-10-01 09:00:00'),
('23','Welcome','Welcome to Campus Lost & Found!','1','2026-10-01 09:00:00'),
('24','Welcome','Welcome to Campus Lost & Found!','1','2026-10-01 09:00:00'),
('24','Claim update','One of your claims has been reviewed. Check My Claims.','0','2026-11-05 10:00:00'),
('24','Report approved','Your report was approved and is now visible to everyone.','0','2026-11-06 10:00:00'),
('25','Welcome','Welcome to Campus Lost & Found!','1','2026-10-01 09:00:00'),
('26','Welcome','Welcome to Campus Lost & Found!','1','2026-10-01 09:00:00');

INSERT INTO announcements(title,body,created_by,created_at) VALUES
('Lost & Found desk timings','The physical desk in the Admin Building is open 9 AM to 5 PM on working days.','1','2026-10-02 09:00:00'),
('Always carry your ID','Please keep your student ID with you. Report lost cards immediately.','1','2026-10-15 09:00:00'),
('Unclaimed items policy','Items unclaimed for 60 days are handed over to the campus security office.','2','2026-11-01 09:00:00'),
('Exam week reminder','Do not leave electronics unattended in the library during exam week.','1','2026-11-10 09:00:00');

INSERT INTO activity_logs(user_id,action,details,created_at) VALUES
('3','LOGIN','Signed in','2026-11-01 8:15:00'),
('4','REPORT_ITEM','Submitted a report','2026-11-02 9:15:00'),
('5','CLAIM_SUBMIT','Submitted a claim','2026-11-03 10:15:00'),
('2','ITEM_REVIEW','Reviewed an item report','2026-11-04 11:15:00'),
('1','CLAIM_REVIEW','Reviewed an ownership claim','2026-11-05 12:15:00'),
('8','LOGIN','Signed in','2026-11-06 13:15:00'),
('9','REPORT_ITEM','Submitted a report','2026-11-07 14:15:00'),
('10','CLAIM_SUBMIT','Submitted a claim','2026-11-08 15:15:00'),
('1','ITEM_REVIEW','Reviewed an item report','2026-11-09 16:15:00'),
('2','CLAIM_REVIEW','Reviewed an ownership claim','2026-11-10 17:15:00'),
('13','LOGIN','Signed in','2026-11-11 8:15:00'),
('14','REPORT_ITEM','Submitted a report','2026-11-12 9:15:00'),
('15','CLAIM_SUBMIT','Submitted a claim','2026-11-13 10:15:00'),
('2','ITEM_REVIEW','Reviewed an item report','2026-11-14 11:15:00'),
('1','CLAIM_REVIEW','Reviewed an ownership claim','2026-11-15 12:15:00'),
('18','LOGIN','Signed in','2026-11-16 13:15:00'),
('19','REPORT_ITEM','Submitted a report','2026-11-17 14:15:00'),
('20','CLAIM_SUBMIT','Submitted a claim','2026-11-18 15:15:00'),
('1','ITEM_REVIEW','Reviewed an item report','2026-11-01 16:15:00'),
('2','CLAIM_REVIEW','Reviewed an ownership claim','2026-11-02 17:15:00'),
('23','LOGIN','Signed in','2026-11-03 8:15:00'),
('24','REPORT_ITEM','Submitted a report','2026-11-04 9:15:00'),
('25','CLAIM_SUBMIT','Submitted a claim','2026-11-05 10:15:00'),
('2','ITEM_REVIEW','Reviewed an item report','2026-11-06 11:15:00'),
('1','CLAIM_REVIEW','Reviewed an ownership claim','2026-11-07 12:15:00'),
('4','LOGIN','Signed in','2026-11-08 13:15:00'),
('5','REPORT_ITEM','Submitted a report','2026-11-09 14:15:00'),
('6','CLAIM_SUBMIT','Submitted a claim','2026-11-10 15:15:00'),
('1','ITEM_REVIEW','Reviewed an item report','2026-11-11 16:15:00'),
('2','CLAIM_REVIEW','Reviewed an ownership claim','2026-11-12 17:15:00');
