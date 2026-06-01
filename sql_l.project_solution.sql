SELECT * FROM books;
SELECT * FROM branch;
SELECT * FROM employees;
SELECT * FROM issued_status;
SELECT * FROM members;
SELECT * FROM return_status;

--- Project Task

-- Task 1. Create a New Book Record
-- ("'978-1-60129-456-2', 'To Kill a Mockingbird', 'Classic', 6.00, 'yes', 'Harper Lee', 'J.B Lippincott & Co'")

INSERT INTO books(isbn, book_title, category, rental_price, status, author, publisher)
VALUES ('978-1-60129-456-2', 'To Kill a Mockingbird', 'Classic', 6.00, 'yes', 'Harper Lee', 'J.B Lippincott & Co');

SELECT * FROM books;

-- Task 2. Update an Existing Member's Address

UPDATE members
SET member_address = '125 Main St'
WHERE member_id = 'C101';

SELECT * FROM members;

-- Task 3: Delete a Record from the Issued Status Table
-- Objective: Delete the record with issued_id = 'IS104' from the issued_status table.

SELECT * FROM issued_status
WHERE issued_id = 'IS104';

DELETE FROM issued_status
WHERE issued_id = 'IS104';

-- Task 4. Retrieve All Books Issued by a Specific Employee 
-- Objective: Select all books issued by the employee with emp_id = 'E101'

SELECT * FROM issued_status 
WHERE issued_emp_id = 'E101';

-- Task 5. List Members Who Have Issued More Than One Book 
-- Objective: Use GROUP BY to find members who have issued more than one book.

SELECT 
    issued_member_id,
    COUNT(issued_id) AS total_book_issued
FROM issued_status
GROUP BY issued_member_id
HAVING COUNT(issued_id) > 1;

-- CTAS (Create Table As Select)
-- Task 6. Create Summary Table: Used CTAS to generate new tables based on query results - each book and total_issued_cnt

CREATE TABLE book_cnts AS
SELECT  
    b.isbn, 
    b.book_title, 
    COUNT(ist.issued_id) AS no_issued
FROM books AS b
JOIN issued_status AS ist ON ist.issued_book_isbn = b.isbn
GROUP BY b.isbn, b.book_title;

SELECT * FROM book_cnts;

-- Task 7. Retrieve All Books in a Specific Category.

SELECT * FROM books
WHERE category = 'Classic';

-- Task 8. Find Total Rental Income by Category:

SELECT 
    b.category,
    SUM(b.rental_price) AS total_income,
    COUNT(*) AS total_loans
FROM books AS b
JOIN issued_status AS ist ON b.isbn = ist.issued_book_isbn
GROUP BY b.category;

-- Task 9. List Members Who Registered in the last 180 Days

SELECT * FROM members 
WHERE reg_date >= CURRENT_DATE - INTERVAL '180 days';

INSERT INTO members(member_id, member_name, member_address, reg_date)
VALUES
('C187', 'sam', '145 Main St', '2026-05-01'),
('C189', 'john', '140 Main St', '2026-03-01');

-- Task 10. List Employees with Their Branch Manager's Name and their branch details;

SELECT 
    el.*,
    b.manager_id,
    e2.emp_name AS manager
FROM employees AS el
JOIN branch AS b ON b.branch_id = el.branch_id
JOIN employees AS e2 ON b.manager_id = e2.emp_id;

-- Task 11. Create a Table of Books with Rental Price Above a Certain Threshold 10 USD

CREATE TABLE books_price_greater_than_ten AS
SELECT * FROM books
WHERE rental_price > 10;

SELECT * FROM books_price_greater_than_ten;

-- Task 12. Retrieve the List of Books Not yet Returned 

SELECT DISTINCT 
    ist.issued_book_name
FROM issued_status AS ist
LEFT JOIN return_status AS rs ON ist.issued_id = rs.issued_id
WHERE rs.issued_id IS NULL;

SELECT * FROM return_status;

/*-- Task 13. Task 13: Identify Members with Overdue Books
Write a query to identify members who have overdue books (assume a 30-day return period). Display the member's_id, member's name, book title, issue date, and days overdue.
*/

SELECT 
    ist.issued_member_id,
    m.member_name,
    bk.book_title,
    ist.issued_date,
    -- rs.return_date,
    CURRENT_DATE - ist.issued_date as over_dues_days
FROM issued_status as ist
JOIN 
members as m
    ON m.member_id = ist.issued_member_id
JOIN 
books as bk
ON bk.isbn = ist.issued_book_isbn
LEFT JOIN 
return_status as rs
ON rs.issued_id = ist.issued_id
WHERE 
    rs.return_date IS NULL
    AND
    (CURRENT_DATE - ist.issued_date) > 30
ORDER BY 1

/*Task 14. Update Book Status on Return
Write a query to update the status of books in the books table to "Yes" when they are returned (based on entries in the return_status table).*/


CREATE OR REPLACE PROCEDURE add_return_records(
    p_return_id VARCHAR(10), 
    p_issued_id VARCHAR(10), 
    p_book_quality VARCHAR(10)
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_isbn VARCHAR(50);
    v_book_name VARCHAR(80);
BEGIN
    -- Inserting into returns based on user input
    INSERT INTO return_status(return_id, issued_id, return_date, book_quality)
    VALUES (p_return_id, p_issued_id, CURRENT_DATE, p_book_quality);

    -- Fetching the ISBN and book name to update the books table
    SELECT 
        issued_book_isbn,
        issued_book_name
    INTO
        v_isbn,
        v_book_name
    FROM issued_status
    WHERE issued_id = p_issued_id;

    -- Updating the book status to 'yes'
    UPDATE books
    SET status = 'yes'
    WHERE isbn = v_isbn;

    RAISE NOTICE 'Thank you for returning the book: %', v_book_name;
END;
$$;


-- Testing FUNCTION add_return_records
-- (Notes commented out so they don't cause syntax errors)
-- issued_id = IS135
-- ISBN = WHERE isbn = '978-0-307-58837-1'

SELECT * FROM books
WHERE isbn = '978-0-307-58837-1';

SELECT * FROM issued_status
WHERE issued_book_isbn = '978-0-307-58837-1';

SELECT * FROM return_status
WHERE issued_id = 'IS135';

-- calling function 
CALL add_return_records('RS138', 'IS135', 'Good');

-- calling function 
CALL add_return_records('RS148', 'IS140', 'Good');


/* Task 15. Branch Performance Report
Create a query that generates a performance report for each branch, showing the number 
of books issued, the number of books returned, and the total revenue generated from book rentals.*/

CREATE TABLE branch_reports
AS
SELECT 
    b.branch_id,
    b.manager_id,
    COUNT(ist.issued_id) as number_book_issued,
    COUNT(rs.return_id) as number_of_book_return,
    SUM(bk.rental_price) as total_revenue
FROM issued_status as ist
JOIN 
employees as e
ON e.emp_id = ist.issued_emp_id
JOIN
branch as b
ON e.branch_id = b.branch_id
LEFT JOIN
return_status as rs
ON rs.issued_id = ist.issued_id
JOIN 
books as bk
ON ist.issued_book_isbn = bk.isbn
GROUP BY 1, 2;

SELECT * FROM branch_reports;

-- End of the project 