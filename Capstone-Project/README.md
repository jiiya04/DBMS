# Campus Lost & Found

A web application where students report lost and found items on campus, search listings and submit ownership claims, while administrators review reports and claims. Built as a DBMS course project.

**🔗 Live demo:** https://campusfound-gules.vercel.app/

---

## Features

**Students**
- Register, log in, edit profile and change password
- Dashboard with personal statistics
- Browse items with search and filters (type, category, location)
- Report a lost or found item (reviewed by an admin before it goes live)
- Track own reports and ownership claims

**Admins**
- Analytics dashboard with charts
- Approve or reject item reports and ownership claims, with notes
- Manage students, categories and locations
- Publish announcements and view activity logs
- Generate reports, export CSV and print

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Frontend | HTML, CSS, JavaScript |
| Database | MySql(Aiven) |
| Charts | Chart.js |
| Hosting | Vercel |

## Database

The schema has 10 tables: `users`, `student_profiles`, `categories`, `locations`, `items`, `item_images`, `claims`, `notifications`, `announcements` and `activity_logs`. It uses primary and foreign keys, `UNIQUE` and `CHECK` constraints, indexes, a view (`v_item_details`) and a trigger (`trg_item_review`) that notifies a student when their report is approved or rejected.

## Project Structure

```
Campus-Lost-Found/
├── index.html      # Page shell
├── style.css       # Styling
├── app.js          # UI and role-based pages
├── db.js           # Database layer (sql.js)
├── database/
schema.sql      # Tables, view, trigger, demo data
├── sql/            # Example reports, index demo, test cases
└── README.md
```

## Demo Accounts

| Role | Email | Password |
|------|-------|----------|
| Admin (Staff tab) | sunita.rao@campus.edu | [Admin@123] |
| Student | jiya.gupta@campus.edu | [Student@123] |
