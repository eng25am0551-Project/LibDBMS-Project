LIBFLOW – HYBRID DBMS PACKAGE
================================

CONTENTS
- LibFlow_Hybrid_DBMS.ipynb: Colab/Jupyter implementation notebook
- LibFlow_Schema.sql: PostgreSQL tables, constraints, indexes and triggers
- LibFlow_Sample_Data.sql: sample students, books and issue records
- LibFlow_MongoDB.json: nested MongoDB sample documents
- LibFlow_ER_Diagram.png: ER and cross-database integration diagram
- LibFlow_Design_Justification.docx: hybrid design reasoning and trade-offs
- LibFlow_Project_Report.docx: report draft
- LibFlow_Viva_Questions.docx: viva preparation

QUICK START
1. Create a PostgreSQL database named libflow_db.
2. Run LibFlow_Schema.sql.
3. Run LibFlow_Sample_Data.sql.
4. Create a MongoDB database named libflow and a collection named book_metadata.
5. Open the notebook in Google Colab.
6. Add PGHOST, PGPORT, PGDATABASE, PGUSER, PGPASSWORD, MONGO_URI and MONGO_DATABASE as environment variables / Colab Secrets.
7. Run the notebook from top to bottom.
8. Capture your own screenshots of successful connections, nested MongoDB query, sync, SQL JOIN, nested SQL query, issue/return and fine report.

IMPORTANT NOTES
- The sample notebook uses PostgreSQL, not MySQL. If your course/lab requires MySQL, the schema and Python connector need conversion.
- MongoDB documents use book_id values that must already exist in PostgreSQL books.
- The notebook contains demonstration operations; uncomment issue/return examples only after checking your sample IDs and available stock.
- Do not submit database passwords or private connection strings.
- This is a complete reference package based on the described LibFlow screens/features. The exact Google AI Studio source code and screenshot field names were not available to inspect here. Match the sample field names and labels to your current app before final submission.
