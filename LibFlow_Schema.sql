-- LibFlow Hybrid DBMS Schema (PostgreSQL)
-- Core transactions live in PostgreSQL; flexible book metadata lives in MongoDB.
-- Run this script in a fresh PostgreSQL database.

CREATE TABLE IF NOT EXISTS students (
    student_id       VARCHAR(20) PRIMARY KEY,
    full_name        VARCHAR(100) NOT NULL,
    email            VARCHAR(120) UNIQUE NOT NULL,
    phone            VARCHAR(20),
    department       VARCHAR(80) NOT NULL,
    semester         SMALLINT CHECK (semester BETWEEN 1 AND 12),
    section          VARCHAR(20),
    created_at       TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS books (
    book_id          VARCHAR(20) PRIMARY KEY,
    isbn             VARCHAR(20) UNIQUE,
    title            VARCHAR(200) NOT NULL,
    author           VARCHAR(150) NOT NULL,
    category         VARCHAR(80) NOT NULL,
    publisher        VARCHAR(120),
    publication_year SMALLINT CHECK (publication_year BETWEEN 1400 AND 2100),
    total_copies     INTEGER NOT NULL CHECK (total_copies >= 0),
    available_copies INTEGER NOT NULL CHECK (
        available_copies >= 0 AND available_copies <= total_copies
    ),
    shelf_number     VARCHAR(30),
    created_at       TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS issues (
    issue_id              BIGSERIAL PRIMARY KEY,
    student_id            VARCHAR(20) NOT NULL REFERENCES students(student_id),
    book_id               VARCHAR(20) NOT NULL REFERENCES books(book_id),
    issue_date            DATE NOT NULL DEFAULT CURRENT_DATE,
    due_date              DATE NOT NULL,
    return_date           DATE,
    status                VARCHAR(12) NOT NULL DEFAULT 'issued'
                          CHECK (status IN ('issued', 'returned')),
    title_snapshot        VARCHAR(200) NOT NULL,
    fine_per_day_snapshot NUMERIC(8,2) NOT NULL DEFAULT 5.00
                          CHECK (fine_per_day_snapshot >= 0),
    CHECK (due_date >= issue_date),
    CHECK (return_date IS NULL OR return_date >= issue_date)
);

CREATE TABLE IF NOT EXISTS fines (
    fine_id       BIGSERIAL PRIMARY KEY,
    issue_id      BIGINT NOT NULL UNIQUE REFERENCES issues(issue_id),
    amount        NUMERIC(10,2) NOT NULL CHECK (amount >= 0),
    status        VARCHAR(12) NOT NULL DEFAULT 'unpaid'
                  CHECK (status IN ('unpaid', 'paid', 'waived')),
    assessed_on   DATE NOT NULL DEFAULT CURRENT_DATE
);

CREATE TABLE IF NOT EXISTS payments (
    payment_id    BIGSERIAL PRIMARY KEY,
    fine_id       BIGINT NOT NULL REFERENCES fines(fine_id),
    amount        NUMERIC(10,2) NOT NULL CHECK (amount > 0),
    payment_date  TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    payment_mode  VARCHAR(20) NOT NULL
                  CHECK (payment_mode IN ('cash', 'upi', 'card', 'online')),
    reference_no  VARCHAR(80) UNIQUE
);

-- SQL-side index of selected nested MongoDB metadata.
-- book_id is the stable integration key; it is NOT a cross-database foreign key.
CREATE TABLE IF NOT EXISTS book_metadata_index (
    book_id             VARCHAR(20) PRIMARY KEY REFERENCES books(book_id),
    subjects            TEXT[] NOT NULL DEFAULT '{}',
    languages           TEXT[] NOT NULL DEFAULT '{}',
    latest_edition_year SMALLINT,
    mongo_updated_at    TIMESTAMP,
    synced_at           TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_issues_student ON issues(student_id);
CREATE INDEX IF NOT EXISTS idx_issues_book ON issues(book_id);
CREATE INDEX IF NOT EXISTS idx_issues_status ON issues(status);
CREATE INDEX IF NOT EXISTS idx_fines_status ON fines(status);

-- Keep available-copy count consistent when a book is issued or returned.
CREATE OR REPLACE FUNCTION libflow_adjust_available_copies()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        IF NEW.status = 'issued' THEN
            UPDATE books
               SET available_copies = available_copies - 1
             WHERE book_id = NEW.book_id AND available_copies > 0;
            IF NOT FOUND THEN
                RAISE EXCEPTION 'No available copy for book %', NEW.book_id;
            END IF;
        END IF;
        RETURN NEW;
    ELSIF TG_OP = 'UPDATE' THEN
        IF OLD.status = 'issued' AND NEW.status = 'returned' THEN
            UPDATE books SET available_copies = available_copies + 1
             WHERE book_id = OLD.book_id;
        ELSIF OLD.book_id <> NEW.book_id THEN
            RAISE EXCEPTION 'Changing the book on an existing issue is not allowed';
        END IF;
        RETURN NEW;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_adjust_available_copies ON issues;
CREATE TRIGGER trg_adjust_available_copies
BEFORE INSERT OR UPDATE OF status, book_id ON issues
FOR EACH ROW EXECUTE FUNCTION libflow_adjust_available_copies();

-- Assess a fine automatically when an issue is returned late.
CREATE OR REPLACE FUNCTION libflow_assess_fine()
RETURNS TRIGGER AS $$
DECLARE late_days INTEGER;
DECLARE fine_value NUMERIC(10,2);
BEGIN
    IF OLD.status = 'issued' AND NEW.status = 'returned'
       AND NEW.return_date IS NOT NULL THEN
        late_days := GREATEST(NEW.return_date - NEW.due_date, 0);
        fine_value := late_days * NEW.fine_per_day_snapshot;
        IF fine_value > 0 THEN
            INSERT INTO fines(issue_id, amount, status)
            VALUES (NEW.issue_id, fine_value, 'unpaid')
            ON CONFLICT (issue_id)
            DO UPDATE SET amount = EXCLUDED.amount, status = 'unpaid';
        END IF;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_assess_fine ON issues;
CREATE TRIGGER trg_assess_fine
AFTER UPDATE OF status, return_date ON issues
FOR EACH ROW EXECUTE FUNCTION libflow_assess_fine();

-- Example JOIN report: active issues with student and book details.
-- SELECT i.issue_id, s.full_name, b.title, i.issue_date, i.due_date
-- FROM issues i
-- JOIN students s ON s.student_id = i.student_id
-- JOIN books b ON b.book_id = i.book_id
-- WHERE i.status = 'issued';

-- Example nested query: books never issued.
-- SELECT b.book_id, b.title FROM books b
-- WHERE NOT EXISTS (SELECT 1 FROM issues i WHERE i.book_id = b.book_id);
