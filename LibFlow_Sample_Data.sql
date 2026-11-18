-- LibFlow sample data (run after LibFlow_Schema.sql)
INSERT INTO students(student_id, full_name, email, phone, department, semester, section)
VALUES
('STU001','Aarav Sharma','aarav@example.edu','9000000001','CSE',3,'A'),
('STU002','Meera Nair','meera@example.edu','9000000002','AIML',3,'B'),
('STU003','Kabir Rao','kabir@example.edu','9000000003','ECE',2,'A'),
('STU004','Ananya Iyer','ananya@example.edu','9000000004','AIML',3,'A')
ON CONFLICT (student_id) DO NOTHING;

INSERT INTO books(book_id,isbn,title,author,category,publisher,publication_year,total_copies,available_copies,shelf_number)
VALUES
('BK001','9780132350884','Clean Code','Robert C. Martin','Programming','Prentice Hall',2008,5,5,'A-01'),
('BK002','9780262033848','Introduction to Algorithms','Cormen et al.','Computer Science','MIT Press',2009,4,4,'A-02'),
('BK003','9781492056355','Fluent Python','Luciano Ramalho','Programming','O''Reilly',2022,3,3,'B-01'),
('BK004','9780134685991','Effective Java','Joshua Bloch','Programming','Addison-Wesley',2018,2,2,'B-02'),
('BK005','9780596009205','Learning SQL','Alan Beaulieu','Database','O''Reilly',2020,3,3,'C-01')
ON CONFLICT (book_id) DO NOTHING;

-- Demonstration issue rows (the trigger reduces available_copies).
INSERT INTO issues(student_id,book_id,issue_date,due_date,status,title_snapshot,fine_per_day_snapshot)
VALUES
('STU001','BK001',CURRENT_DATE - 3,CURRENT_DATE + 11,'issued','Clean Code',5.00),
('STU002','BK003',CURRENT_DATE - 20,CURRENT_DATE - 6,'issued','Fluent Python',5.00)
ON CONFLICT DO NOTHING;
