-- Tables destructions

drop table THEATER_COMPANY CASCADE CONSTRAINTS;
drop table CREATIONS CASCADE CONSTRAINTS;
drop table REPRESENTATION CASCADE CONSTRAINTS;
drop table GRANTS CASCADE CONSTRAINTS;
drop table TICKETS CASCADE CONSTRAINTS;
drop table CUSTOMER CASCADE CONSTRAINTS;
drop table REDUCE_RATE CASCADE CONSTRAINTS;
drop table DEBUG CASCADE CONSTRAINTS;
drop table ARCHIVE CASCADE CONSTRAINTS;

-- Edit date format

ALTER SESSION SET NLS_DATE_FORMAT = 'DD-MM-YYYY' ;

-- Create tables
/***************************** THEATER **********************************/

CREATE TABLE THEATER_COMPANY
(
  _theater_company_id     NUMBER NOT NULL, /*ID*/

  hall_capacity           NUMBER NOT NULL,
  name_company            VARCHAR(64) NOT NULL;
  budget                  FLOAT NOT NULL,
  city                    VARCHAR(64) NOT NULL,
  balance                 FLOAT NOT NULL,
  date_last_balance_edit  DATE NOT NULL

  PRIMARY KEY (_theater_company_id),
  CONSTRAINT BUDGET_CSTR CHECK(budget >= 0), /* Exo 3-B-1-C */
);

CREATE OR REPLACE TRIGGER balance_update
    AFTER UPDATE OF curr_date ON DEBUG
    FOR EACH ROW
    
    /* How is it supposed to be done for each month to update the balance with budget */
    begin
      IF MONTH(curr_date) > MONTH(THEATER_COMPANY.date_last_balance_edit) OR YEAR(curr_date) > YEAR(THEATER_COMPANY.date_last_balance_edit) THEN
        balance
      END IF
    end;

/***************************** CREATIONS **********************************/

CREATE TABLE CREATIONS
(
  _creation_id            NUMBER NOT NULL,

  creation_cost           FLOAT NOT NULL,
  promotion_creations     FLOAT NOT NULL,

  PRIMARY KEY (_creation_id),
  /*This will be a factor multiplied with the price in order to apply promotions*/
  CONSTRAINT PROMO_CSTR CHECK(promotion_creations >= 0 AND promotion_creations <= 1) 
);

CREATE TABLE REPRESENTATION
(
  date_representation DATE NOT NULL,
  normal_reference_rate FLOAT NOT NULL,
  reduced_reference_rate FLOAT NOT NULL,
  money_made FLOAT NOT NULL,
  representation_id NUMBER NOT NULL,
  PRIMARY KEY (representation_id)
);

CREATE TABLE GRANTS
(
  entity VARCHAR(64) NOT NULL,
  amount FLOAT NOT NULL,
  number_months NUMBER NOT NULL,
  date_start DATE NOT NULL,
  grant_id NUMBER NOT NULL,
  PRIMARY KEY (grant_id)
);

CREATE TABLE TICKETS
(
  price FLOAT NOT NULL,
  promotion FLOAT NOT NULL,
  buying_date DATE NOT NULL,
  ticket_id NUMBER NOT NULL,
  PRIMARY KEY (ticket_id)
);

CREATE TABLE CUSTOMER
(
  age NUMBER NOT NULL,
  mail VARCHAR(64) NOT NULL,
  name VARCHAR(64) NOT NULL,
  job VARCHAR(64) NOT NULL,
  customer_id NUMBER NOT NULL,
  PRIMARY KEY (customer_id)
);

CREATE TABLE REDUCE_RATE
(
  age_reduce NUMBER NOT NULL,
  job_reduce VARCHAR(64) NOT NULL,
  percentage FLOAT NOT NULL,
  starting_date DATE NOT NULL,
  finish_date DATE NOT NULL,
  completion_percentage FLOAT NOT NULL,
  reduce_id NUMBER NOT NULL,
  representation_id NUMBER NOT NULL,
  PRIMARY KEY (reduce_id),
  FOREIGN KEY (representation_id) REFERENCES REPRESENTATION(representation_id)
);

CREATE TABLE DEBUG
(
  curr_date DATE NOT NULL
);

CREATE TABLE ARCHIVE
(
  date_transaction DATE NOT NULL,
  amount FLOAT NOT NULL,
  type VARCHAR(16) NOT NULL,
  trans_id NUMBER NOT NULL,
  PRIMARY KEY (trans_id)
);