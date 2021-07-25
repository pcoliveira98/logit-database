--- POSTGRESQL 13

CREATE TABLE branch_types(
    id SERIAL PRIMARY KEY,
    name VARCHAR(50),
    created_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE TABLE products(
    id SERIAL PRIMARY KEY,
    name VARCHAR(50),
    created_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE TABLE branches(
    id SERIAL PRIMARY KEY,
    name VARCHAR(50),
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    branch_type_id INT,
    CONSTRAINT fk_branch_type
        FOREIGN KEY(branch_type_id)
        REFERENCES branch_types(id)
        ON DELETE SET NULL
);

CREATE TABLE stock(
    id INT PRIMARY KEY,
    branch_id INT,
    product_id INT,
    quantity INT,
    cost INT,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    CONSTRAINT fk_branch
        FOREIGN KEY(branch_id)
        REFERENCES branches(id)
        ON DELETE SET NULL,
    CONSTRAINT fk_product
        FOREIGN KEY (product_id)
        REFERENCES products(id)
        ON DELETE SET NULL
);

CREATE TABLE movements(
    id SERIAL PRIMARY KEY,
    branch_id INT,
    product_id INT,
    quantity INT,
    price INT,
    cost INT,
    operation CHAR,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    CONSTRAINT fk_branch
        FOREIGN KEY(branch_id)
        REFERENCES branches(id)
        ON DELETE SET NULL,
    CONSTRAINT fk_product
        FOREIGN KEY (product_id)
        REFERENCES products(id)
        ON DELETE SET NULL
);

--------------------------------------------------------------------------------------------------------------------------------

--- ORACLE 11.2g

CREATE TABLE branch_types (
  id INT,
  name  VARCHAR2(50),
  created_at TIMESTAMP,
  PRIMARY KEY (id)
);

CREATE SEQUENCE bt_seq START WITH 1;

CREATE OR REPLACE TRIGGER bt_bir 
BEFORE INSERT ON branch_types
FOR EACH ROW

BEGIN
  SELECT bt_seq.NEXTVAL
  INTO   :new.id
  FROM   dual;
END;

CREATE TABLE products(
    id INT,
    name VARCHAR2(50),
    created_at TIMESTAMP,
    PRIMARY KEY(id)
);

CREATE SEQUENCE prod_seq START WITH 1;

CREATE OR REPLACE TRIGGER prod_bir 
BEFORE INSERT ON products
FOR EACH ROW

BEGIN
  SELECT prod_seq.NEXTVAL
  INTO   :new.id
  FROM   dual;
END;

CREATE TABLE branches(
    id INT,
    name VARCHAR2(50),
    created_at TIMESTAMP,
    branch_type_id INT,
    CONSTRAINT fk_branch_type
        FOREIGN KEY(branch_type_id)
        REFERENCES branch_types(id)
        ON DELETE SET NULL,
    PRIMARY KEY(id)
);

CREATE SEQUENCE branch_seq START WITH 1;

CREATE OR REPLACE TRIGGER branch_bir 
BEFORE INSERT ON branches
FOR EACH ROW

BEGIN
  SELECT branch_seq.NEXTVAL
  INTO   :new.id
  FROM   dual;
END;

CREATE TABLE stock(
    id INT,
    branch_id INT,
    product_id INT,
    quantity INT,
    cost INT,
    created_at TIMESTAMP,
    CONSTRAINT fk_branch_stock
        FOREIGN KEY(branch_id)
        REFERENCES branches(id)
        ON DELETE SET NULL,
    CONSTRAINT fk_product_stock
        FOREIGN KEY (product_id)
        REFERENCES products(id)
        ON DELETE SET NULL
);

CREATE TABLE movements(
    id INT,
    branch_id INT,
    product_id INT,
    quantity INT,
    price INT,
    cost INT,
    operation CHAR,
    created_at TIMESTAMP,
    CONSTRAINT fk_branch_move
        FOREIGN KEY(branch_id)
        REFERENCES branches(id)
        ON DELETE SET NULL,
    CONSTRAINT fk_product_move
        FOREIGN KEY (product_id)
        REFERENCES products(id)
        ON DELETE SET NULL,
    PRIMARY KEY(id)
);

CREATE SEQUENCE move_seq START WITH 1;

CREATE OR REPLACE TRIGGER move_bir
BEFORE INSERT ON movements
FOR EACH ROW
BEGIN
    SELECT move_seq.NEXTVAL
    INTO :new.id
    FROM dual;
END;

------------------------------------------------------------------------------------------------------------------------

---Exercícios

/*1*/ SELECT * FROM products WHERE name LIKE '%Kit%';

/*2*/ 
    SELECT b.name AS filiais, bt.name AS tipos 
    FROM branches b 
    INNER JOIN branch_types bt 
    ON(bt.id = b.branch_type_id)
    WHERE bt.name = 'Deposit';

/*3*/ SELECT * FROM movements WHERE operation = 'S' AND branch_id = 1;

/*4*/ 
    ---POSTGRESQL 13
        SELECT * FROM stock WHERE branch_id = 1 AND created_at = '2021-07-07';
    
    ---ORACLE 11.2g
        SELECT * FROM stock WHERE branch_id = 1 AND created_at = '07/07/2021';

/*5*/ 
    ---POSTGRESQL 13
    SELECT p.name, m.quantity, m.quantity * m.price AS total_sales_value 
    FROM products AS p 
    INNER JOIN movements AS m 
    ON(p.id = m.product_id) 
    WHERE (m.operation = 'S') AND (m.created_at >= (CURRENT_DATE - INTERVAL '2 months')) AND (m.price IS NOT NULL OR m.price > 0)
    ORDER BY m.quantity DESC
    LIMIT 10;

    ---ORACLE 11.2g
    SELECT * FROM (
        SELECT p.name, m.quantity, m.quantity * m.price AS total_sales_value 
        FROM products p 
        INNER JOIN movements m 
        ON(p.id = m.product_id) 
        WHERE (m.operation = 'S') AND (m.created_at >= add_months(sysdate, -2)) AND (m.price IS NOT NULL OR m.price > 0)
        ORDER BY m.quantity DESC    
    )WHERE rownum <= 10;

/*6*/
    ---POSTGRESQL 13
    SELECT p.name, s.quantity * s.cost AS value_stock, s.cost
    FROM products AS p
    INNER JOIN stock AS s
    ON(p.id = s.product_id)
    WHERE s.created_at <= (CURRENT_DATE - INTERVAL '1 day')
    ORDER BY value_stock DESC
    LIMIT 10;

    ---ORACLE 11.2g
    SELECT * FROM (
        SELECT p.name, s.quantity * s.cost AS value_stock, s.cost
        FROM products p
        INNER JOIN stock s
        ON(p.id = s.product_id)
        WHERE s.created_at <= (sysdate - 1)
        ORDER BY value_stock DESC
    )WHERE rownum <= 10;

/*7*/
    ---POSTGRESQL 13
    SELECT p.name, m.price, m.cost, (s.quantity * s.cost)/((m.quantity * m.cost)/60) AS tc
    FROM products AS p
    INNER JOIN stock AS s
    ON(p.id = s.product_id)
    INNER JOIN movements AS m
    ON (p.id = m.product_id)
    WHERE (m.operation = 'S') AND (m.price IS NULL OR m.price = 0) AND (m.cost IS NOT NULL OR m.cost > 0)
    ORDER BY tc DESC
    LIMIT 10;

    ---ORACLE 11.2g
    SELECT * FROM (
        SELECT p.name, m.price, m.cost, (s.quantity * s.cost)/((m.quantity * m.cost)/60) AS tc
        FROM products p
        INNER JOIN stock s
        ON(p.id = s.product_id)
        INNER JOIN movements m
        ON (p.id = m.product_id)
        WHERE (m.operation = 'S') AND (m.price IS NULL OR m.price = 0) AND (m.cost IS NOT NULL OR m.cost > 0)
        ORDER BY tc DESC
    )WHERE rownum <= 10;