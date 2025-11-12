-- Schema v1
CREATE TABLE IF NOT EXISTS patients (
  id TEXT PRIMARY KEY,
  full_name TEXT NOT NULL,
  dob INT,
  email TEXT,
  phone TEXT,
  address TEXT,
  created_at INT NOT NULL
);

CREATE TABLE IF NOT EXISTS invoices (
  id TEXT PRIMARY KEY,
  patient_id TEXT NOT NULL,
  episode TEXT,
  issue_date INT NOT NULL,
  due_date INT NOT NULL,
  status TEXT NOT NULL CHECK(status IN ('brouillon','en_attente','payee','annulee')),
  notes TEXT,
  subtotal_cents INT NOT NULL,
  tax_cents INT NOT NULL,
  discount_cents INT NOT NULL,
  total_cents INT NOT NULL,
  amount_due_cents INT NOT NULL,
  qr_pay_url TEXT,
  created_at INT NOT NULL,
  updated_at INT NOT NULL,
  needs_sync INT DEFAULT 0,
  FOREIGN KEY(patient_id) REFERENCES patients(id)
);

CREATE TABLE IF NOT EXISTS line_items (
  id TEXT PRIMARY KEY,
  invoice_id TEXT NOT NULL,
  label TEXT NOT NULL,
  qty REAL NOT NULL,
  unit_price_cents INT NOT NULL,
  tax_rate REAL NOT NULL,
  discount_cents INT NOT NULL,
  line_total_cents INT NOT NULL,
  FOREIGN KEY(invoice_id) REFERENCES invoices(id)
);

CREATE TABLE IF NOT EXISTS payments (
  id TEXT PRIMARY KEY,
  invoice_id TEXT NOT NULL,
  amount_cents INT NOT NULL,
  method TEXT NOT NULL CHECK(method IN ('cash','card','bank','stripe')),
  status TEXT NOT NULL CHECK(status IN ('en_attente','confirme','rembourse')),
  reference TEXT,
  created_at INT NOT NULL,
  deleted_at INT,
  FOREIGN KEY(invoice_id) REFERENCES invoices(id)
);

CREATE INDEX IF NOT EXISTS idx_inv_patient ON invoices(patient_id);
CREATE INDEX IF NOT EXISTS idx_pay_invoice ON payments(invoice_id);
CREATE INDEX IF NOT EXISTS idx_inv_status ON invoices(status);

-- Seeds (demo)
INSERT OR IGNORE INTO patients (id, full_name, dob, email, phone, address, created_at) VALUES
('p1','Ahmed Ben Ali', 536457600000, 'ahmed@example.com','+216 20 111 222','Tunis', strftime('%s','now')*1000),
('p2','Maya Trabelsi', 662688000000, 'maya@example.com','+216 20 333 444','Sfax', strftime('%s','now')*1000);

INSERT OR IGNORE INTO invoices (id, patient_id, episode, issue_date, due_date, status, notes, subtotal_cents, tax_cents, discount_cents, total_cents, amount_due_cents, qr_pay_url, created_at, updated_at, needs_sync) VALUES
('inv1','p1','Consultation', strftime('%s','now')*1000, strftime('%s','now')*1000 + 7*86400000, 'en_attente', 'Première visite', 50000, 9500, 0, 59500, 29500, NULL, strftime('%s','now')*1000, strftime('%s','now')*1000, 0),
('inv2','p2','Analyse', strftime('%s','now')*1000, strftime('%s','now')*1000 + 7*86400000, 'en_attente', 'Analyse labo', 30000, 5700, 0, 35700, 35700, NULL, strftime('%s','now')*1000, strftime('%s','now')*1000, 0);

INSERT OR IGNORE INTO line_items (id, invoice_id, label, qty, unit_price_cents, tax_rate, discount_cents, line_total_cents) VALUES
('li1','inv1','Consultation générale', 1, 50000, 19.0, 0, 59500),
('li2','inv2','Analyse sanguine', 1, 30000, 19.0, 0, 35700);

INSERT OR IGNORE INTO payments (id, invoice_id, amount_cents, method, status, reference, created_at, deleted_at) VALUES
('pay1','inv1', 30000, 'cash', 'confirme', 'REC-001', strftime('%s','now')*1000, NULL),
('pay2','inv1', 0, 'card', 'en_attente', NULL, strftime('%s','now')*1000, NULL),
('pay3','inv2', 0, 'bank', 'en_attente', NULL, strftime('%s','now')*1000, NULL);

