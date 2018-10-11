
DROP TABLE IF EXISTS groceries CASCADE;
DROP TABLE IF EXISTS comments;


CREATE TABLE groceries (
  id SERIAL PRIMARY KEY,
  name VARCHAR(255) NOT NULL
);

CREATE TABLE comments (
  id SERIAL PRIMARY KEY,
  body VARCHAR(255) NOT NULL,
  grocery_id INTEGER REFERENCES groceries (id) ON DELETE CASCADE
);
