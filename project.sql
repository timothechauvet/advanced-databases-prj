CREATE TABLE THEATER_COMPANY
(
  hall_capacity INT NOT NULL,
  _theater_company_id INT NOT NULL,
  budget FLOAT NOT NULL,
  city VARCHAR(64) NOT NULL,
  balance FLOAT NOT NULL,
  PRIMARY KEY (_theater_company_id)
);

CREATE TABLE CREATIONS
(
  creation_cost FLOAT NOT NULL,
  _creation_id INT NOT NULL,
  promotion_creations FLOAT NOT NULL,
  PRIMARY KEY (_creation_id)
);

CREATE TABLE REPRESENTATION
(
  date DATE NOT NULL,
  normal_reference_rate FLOAT NOT NULL,
  reduced_reference_rate FLOAT NOT NULL,
  money_made FLOAT NOT NULL,
  representation_id INT NOT NULL,
  PRIMARY KEY (representation_id)
);

CREATE TABLE GRANT
(
  entity VARCHAR(64) NOT NULL,
  amount FLOAT NOT NULL,
  number_months INT NOT NULL,
  date_start DATE NOT NULL,
  grant_id INT NOT NULL,
  PRIMARY KEY (grant_id)
);

CREATE TABLE TICKETS
(
  price FLOAT NOT NULL,
  promotion FLOAT NOT NULL,
  buying_date DATE NOT NULL,
  ticket_id INT NOT NULL,
  PRIMARY KEY (ticket_id)
);

CREATE TABLE CUSTOMER
(
  age INT NOT NULL,
  mail VARCHAR(64) NOT NULL,
  name VARCHAR(64) NOT NULL,
  job VARCHAR(64) NOT NULL,
  customer_id INT NOT NULL,
  PRIMARY KEY (customer_id)
);

CREATE TABLE REDUCE_RATE
(
  age_reduce INT NOT NULL,
  job_reduce VARCHAR(64) NOT NULL,
  percentage FLOAT NOT NULL,
  starting_date DATE NOT NULL,
  finish_date DATE NOT NULL,
  completion_percentage FLOAT NOT NULL,
  reduce_id INT NOT NULL,
  representation_id INT NOT NULL,
  PRIMARY KEY (reduce_id),
  FOREIGN KEY (representation_id) REFERENCES REPRESENTATION(representation_id)
);

CREATE TABLE DEBUG
(
  date INT NOT NULL
);

CREATE TABLE ARCHIVE
(
  date_transaction DATE NOT NULL,
  amount FLOAT NOT NULL,
  type VARCHAR(16) NOT NULL,
  trans_id INT NOT NULL,
  PRIMARY KEY (trans_id)
);