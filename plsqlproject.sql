-- Enable output so we can see the results printed on screen
SET SERVEROUTPUT ON;

------------------------------------------------------------
-- STEP 1: Clean up old tables and create a fresh table
------------------------------------------------------------
BEGIN
   EXECUTE IMMEDIATE 'DROP TABLE users_table';
EXCEPTION
   WHEN OTHERS THEN NULL; 
END;
/

CREATE TABLE users_table (
    id NUMBER PRIMARY KEY,
    username VARCHAR2(50),
    password VARCHAR2(50),
    role VARCHAR2(20)
);

INSERT INTO users_table VALUES (1, 'admin', 'admin123', 'ADMIN');
INSERT INTO users_table VALUES (2, 'john', 'pass123', 'USER');
INSERT INTO users_table VALUES (3, 'alice', 'alice123', 'USER');
COMMIT;

DBMS_OUTPUT.PUT_LINE('==================================================');
DBMS_OUTPUT.PUT_LINE('--- INITIAL DATA IN TABLE ---');
FOR rec IN (SELECT * FROM users_table) LOOP
    DBMS_OUTPUT.PUT_LINE('ID: ' || rec.id || ' | User: ' || rec.username || ' | Role: ' || rec.role);
END LOOP;
DBMS_OUTPUT.PUT_LINE('==================================================');

------------------------------------------------------------
-- STEP 2: VULNERABLE PROCEDURE (Uses String Concatenation)
------------------------------------------------------------
CREATE OR REPLACE PROCEDURE vulnerable_login(
    p_username IN VARCHAR2, 
    p_password IN VARCHAR2
) AS
    v_sql VARCHAR2(500);
    v_count NUMBER;
BEGIN
    -- BAD PRACTICE: Direct string concatenation
    v_sql := 'SELECT COUNT(*) FROM users_table WHERE username = ''' || p_username || ''' AND password = ''' || p_password || '''';
    
    -- DETAILED OUTPUT: Show the exact query being executed!
    DBMS_OUTPUT.PUT_LINE('   [DEBUG] Vulnerable Query Built: ' || v_sql);
    
    EXECUTE IMMEDIATE v_sql INTO v_count;
    
    IF v_count > 0 THEN
        DBMS_OUTPUT.PUT_LINE('   [RESULT] [VULNERABLE] LOGIN SUCCESSFUL! (User exists)');
    ELSE
        DBMS_OUTPUT.PUT_LINE('   [RESULT] [VULNERABLE] LOGIN FAILED.');
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('   [RESULT] [VULNERABLE] Error: ' || SQLERRM);
END;
/

------------------------------------------------------------
-- STEP 3: SAFE PROCEDURE (Uses Bind Variables)
------------------------------------------------------------
CREATE OR REPLACE PROCEDURE safe_login(
    p_username IN VARCHAR2, 
    p_password IN VARCHAR2
) AS
    v_count NUMBER;
BEGIN
    DBMS_OUTPUT.PUT_LINE('   [DEBUG] Safe Query: Using Bind Variables (Input is treated as literal text)');
    
    -- GOOD PRACTICE: Using bind variables
    SELECT COUNT(*) INTO v_count 
    FROM users_table 
    WHERE username = p_username AND password = p_password;
    
    IF v_count > 0 THEN
        DBMS_OUTPUT.PUT_LINE('   [RESULT] [SAFE] LOGIN SUCCESSFUL! (User exists)');
    ELSE
        DBMS_OUTPUT.PUT_LINE('   [RESULT] [SAFE] LOGIN FAILED.');
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('   [RESULT] [SAFE] Error: ' || SQLERRM);
END;
/

------------------------------------------------------------
-- STEP 4: SANITIZATION FUNCTION (Cleans input)
------------------------------------------------------------
CREATE OR REPLACE FUNCTION sanitize_input(p_input IN VARCHAR2) 
RETURN VARCHAR2 AS
    v_clean VARCHAR2(500);
BEGIN
    DBMS_OUTPUT.PUT_LINE('   [DEBUG] Sanitizing Input: "' || p_input || '"');
    
    v_clean := REPLACE(p_input, '''', ''); -- Remove single quotes
    v_clean := REPLACE(v_clean, '--', ''); -- Remove SQL comments
    v_clean := REPLACE(v_clean, ';', '');  -- Remove semicolons
    
    DBMS_OUTPUT.PUT_LINE('   [DEBUG] Sanitized Output: "' || v_clean || '"');
    RETURN v_clean;
END;
/

------------------------------------------------------------
-- STEP 5: LIVE DEMO (Execute and see detailed results)
------------------------------------------------------------
BEGIN
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('==================================================');
    DBMS_OUTPUT.PUT_LINE('TEST 1: Normal Login (john / pass123)');
    DBMS_OUTPUT.PUT_LINE('==================================================');
    DBMS_OUTPUT.PUT_LINE('-> Calling VULNERABLE procedure...');
    vulnerable_login('john', 'pass123');
    DBMS_OUTPUT.PUT_LINE('-> Calling SAFE procedure...');
    safe_login('john', 'pass123');

    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('==================================================');
    DBMS_OUTPUT.PUT_LINE('TEST 2: SQL Injection Attack!');
    DBMS_OUTPUT.PUT_LINE('Payload Username: admin'' OR ''1''=''1');
    DBMS_OUTPUT.PUT_LINE('Payload Password: anything');
    DBMS_OUTPUT.PUT_LINE('==================================================');
    DBMS_OUTPUT.PUT_LINE('-> Calling VULNERABLE procedure...');
    vulnerable_login('admin'' OR ''1''=''1', 'anything');
    DBMS_OUTPUT.PUT_LINE('-> Calling SAFE procedure...');
    safe_login('admin'' OR ''1''=''1', 'anything');

    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('==================================================');
    DBMS_OUTPUT.PUT_LINE('TEST 3: With Sanitization Function');
    DBMS_OUTPUT.PUT_LINE('==================================================');
    DBMS_OUTPUT.PUT_LINE('-> Calling SAFE procedure with sanitized payload...');
    safe_login(sanitize_input('admin'' OR ''1''=''1'), 'anything');
    
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('==================================================');
    DBMS_OUTPUT.PUT_LINE('--- FINAL DATA IN TABLE (Proving No Data Was Lost) ---');
    FOR rec IN (SELECT * FROM users_table) LOOP
        DBMS_OUTPUT.PUT_LINE('ID: ' || rec.id || ' | User: ' || rec.username || ' | Role: ' || rec.role);
    END LOOP;
    DBMS_OUTPUT.PUT_LINE('==================================================');
END;
/