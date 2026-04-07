
# SQL Syntax Guidelines
## [**back to Linux-Engineer-Applied-Practice**](../README.md)
### [**back to Table of Contents**](/Additional-Notes/Table-of-Contents.md)


## 1. Backticks (`` ` ``)

- **Usage**: Enclose database identifiers such as database names, table names, column names, and aliases.
- **Condition**: Use backticks for identifiers with special characters, spaces, or reserved keywords.

**Example**:
```sql
SELECT `select`, `from`, `table-name` FROM `database-name`.`table-name`;
```

## 2. Single Quotes (`'`)

- **Usage**: Enclose string literals.
- **Condition**: Use single quotes for text or date values.

**Example**:
```sql
SELECT * FROM users WHERE username = 'john_doe';
SELECT * FROM orders WHERE order_date = '2023-07-21';
```

## 3. Double Quotes (`"`)

- **Usage**: Enclose identifiers (standard SQL) or string literals (MySQL with `ANSI_QUOTES` mode).
- **Condition**: Use for identifiers in standard SQL, and cautiously for string literals in MySQL with `ANSI_QUOTES` mode.

**Example** (Standard SQL):
```sql
SELECT "column_name" FROM "table_name";
```

**Example** (MySQL with `ANSI_QUOTES` mode):
```sql
SET sql_mode = 'ANSI_QUOTES';
SELECT * FROM users WHERE username = "john_doe";
```

## 4. Comments

- **Usage**: Explain sections of SQL code.
- **Condition**: Use to describe the purpose or functionality of queries.

**Example**:
```sql
-- This is a single-line comment
SELECT * FROM users;

# This is another single-line comment
SELECT * FROM products;

/*
 This is a multi-line comment
 which spans multiple lines
*/
SELECT * FROM orders;
```

## 5. Semicolon (`;`)

- **Usage**: Terminate SQL statements.
- **Condition**: Use to separate individual SQL statements, especially in scripts.

**Example**:
```sql
SELECT * FROM users;
SELECT * FROM orders;
```

## 6. Parentheses (`(` and `)`)

- **Usage**: Group expressions and define the order of operations, function calls, and subqueries.
- **Condition**: Use to ensure correct evaluation and define subqueries.

**Example**:
```sql
SELECT (price * quantity) AS total_cost FROM sales;
SELECT * FROM (SELECT * FROM users WHERE age > 21) AS adults;
```

## 7. Wildcards (`%` and `_`)

- **Usage**: Used with the `LIKE` operator to search for patterns in text.
- **Condition**: Use `%` to match any sequence of characters and `_` to match a single character.

**Example**:
```sql
SELECT * FROM users WHERE username LIKE 'john%';  -- Matches 'john', 'john_doe', 'johnny', etc.
SELECT * FROM users WHERE username LIKE 'j_hn';   -- Matches 'john', 'jahn', etc.
```

## 8. Logical Operators (`AND`, `OR`, `NOT`)

- **Usage**: Combine multiple conditions in a `WHERE` clause.
- **Condition**: Use `AND` for all true conditions, `OR` for at least one true condition, and `NOT` to negate a condition.

**Example**:
```sql
SELECT * FROM users WHERE age > 18 AND country = 'USA';
SELECT * FROM users WHERE age < 18 OR age > 65;
SELECT * FROM users WHERE NOT (country = 'USA');
```

## 9. Comparison Operators (`=`, `!=`, `<`, `>`, `<=`, `>=`)

- **Usage**: Compare values.
- **Condition**: Use in `WHERE` clauses to filter results based on comparisons.

**Example**:
```sql
SELECT * FROM users WHERE age = 25;
SELECT * FROM products WHERE price >= 100;
SELECT * FROM orders WHERE order_date != '2023-07-21';
```

## 10. Aggregate Functions (`COUNT`, `SUM`, `AVG`, `MIN`, `MAX`)

- **Usage**: Perform calculations on multiple rows and return a single value.
- **Condition**: Use to get summary information.

**Example**:
```sql
SELECT COUNT(*) FROM users;
SELECT AVG(price) FROM products;
SELECT MAX(order_date) FROM orders;
```

## 11. GROUP BY Clause

- **Usage**: Group rows with the same values into summary rows.
- **Condition**: Use with aggregate functions to get grouped summary information.

**Example**:
```sql
SELECT country, COUNT(*) FROM users GROUP BY country;
SELECT department, AVG(salary) FROM employees GROUP BY department;
```

## 12. HAVING Clause

- **Usage**: Filter groups based on a condition, often used with `GROUP BY`.
- **Condition**: Use to filter groups after aggregation.

**Example**:
```sql
SELECT country, COUNT(*) FROM users GROUP BY country HAVING COUNT(*) > 10;
SELECT department, AVG(salary) FROM employees GROUP BY department HAVING AVG(salary) > 50000;
```

## 13. ORDER BY Clause

- **Usage**: Sort the result set by one or more columns.
- **Condition**: Use to sort results in ascending (`ASC`) or descending (`DESC`) order.

**Example**:
```sql
SELECT * FROM users ORDER BY last_name ASC;
SELECT * FROM products ORDER BY price DESC;
```

## 14. LIMIT Clause

- **Usage**: Specify the number of rows returned.
- **Condition**: Use to restrict the number of rows in the result set.

**Example**:
```sql
SELECT * FROM users LIMIT 10;
SELECT * FROM products ORDER BY price DESC LIMIT 5;
```
