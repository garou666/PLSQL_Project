# SQL Injection Defense & Query Sanitizer using PL/SQL

## 📌 Project Overview
This project demonstrates the mechanics of SQL Injection (SQLi) at the database layer using Oracle PL/SQL. It implements a vulnerable stored procedure and a secure stored procedure to show how to prevent authentication bypass attacks.

## 🛠️ Technologies Used
*   Oracle Database (PL/SQL)
*   SQL*Plus / Oracle SQL Developer

## 🚀 Features
1.  **Vulnerable Procedure (`vulnerable_login`)**: Uses dynamic SQL with string concatenation, allowing SQL Injection via payloads like `admin' OR '1'='1`.
2.  **Safe Procedure (`safe_login`)**: Uses bind variables (parameterized queries) to treat user input as literal text, neutralizing the attack.
3.  **Sanitization Function (`sanitize_input`)**: Strips dangerous characters (quotes, semicolons, comments) from user input as an additional layer of defense.

## 📂 Files
*   `sql_injection_defense.sql`: The complete PL/SQL script containing table creation, procedures, function, and the live demo execution block.

## 🖥️ How to Run
1. Open Oracle SQL Developer or SQL*Plus.
2. Connect to your database.
3. Open `sql_injection_defense.sql`.
4. Run the script as a Script (F5).
5. Check the Script Output tab for the detailed execution results.
