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
  balance                 FLOAT NOT NULL

  PRIMARY KEY (_theater_company_id),
  CONSTRAINT BUDGET_CSTR CHECK(budget >= 0), /* Exo 3-B-1-C */
);

CREATE OR REPLACE TRIGGER balance_update
    AFTER UPDATE OF curr_date ON DEBUG
    FOR EACH ROW
    
    begin
      IF DAY(curr_date) = 1 THEN
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
  FOREIGN KEY (_theater_company_id) REFERENCES THEATER_COMPANY(_theater_company_id),
  /*This will be a factor multiplied with the price in order to apply promotions*/
  CONSTRAINT PROMO_CSTR CHECK(promotion_creations >= 0 AND promotion_creations <= 1) 
);

CREATE TABLE REPRESENTATION
(
  date_representation DATE NOT NULL,
  normal_reference_rate FLOAT NOT NULL,
  reduced_reference_rate FLOAT NOT NULL,
  money_made FLOAT NOT NULL,
  tickets_sold NUMBER,
  _representation_id NUMBER NOT NULL,

  PRIMARY KEY (_representation_id),
  FOREIGN KEY (_creation_id) REFERENCES CREATIONS(_creation_id)
);

CREATE TABLE GRANTS
(
  entity VARCHAR(64) NOT NULL,
  amount FLOAT NOT NULL,
  number_months NUMBER NOT NULL,
  date_start DATE NOT NULL,
  _grant_id NUMBER NOT NULL,

  PRIMARY KEY (_grant_id)
);

CREATE TABLE TICKETS
(
  price FLOAT NOT NULL,
  promotion FLOAT NOT NULL,
  buying_date DATE NOT NULL,
  _ticket_id NUMBER NOT NULL,

  PRIMARY KEY (_ticket_id),
  FOREIGN KEY (_representation_id) REFERENCES REPRESENTATION(_representation_id)
);

CREATE TABLE CUSTOMER
(
  age NUMBER NOT NULL,
  mail VARCHAR(64) NOT NULL,
  name_customer VARCHAR(64) NOT NULL,
  job VARCHAR(64) NOT NULL,
  _customer_id NUMBER NOT NULL,

  PRIMARY KEY (_customer_id)
);

CREATE TABLE REDUCE_RATE
(
  age_reduce NUMBER NOT NULL,
  job_reduce VARCHAR(64) NOT NULL,
  percentage FLOAT NOT NULL,
  starting_date DATE NOT NULL,
  finish_date DATE NOT NULL,
  completion_percentage FLOAT NOT NULL,
  _reduce_id NUMBER NOT NULL,
  _representation_id NUMBER NOT NULL,

  PRIMARY KEY (_reduce_id),
  FOREIGN KEY (_representation_id) REFERENCES REPRESENTATION(_representation_id)
);

CREATE TABLE DEBUG
(
  curr_date DATE NOT NULL
);

CREATE TABLE ARCHIVE
(
  date_transaction DATE NOT NULL,
  amount FLOAT NOT NULL,
  type_transaction VARCHAR(16) NOT NULL,
  _trans_id NUMBER NOT NULL,

  PRIMARY KEY (_trans_id),
  FOREIGN KEY (_theater_company_id) REFERENCES THEATER_COMPANY(_theater_company_id)
);

/**************************** CONNECTION BETWEEN ENTITIES ***********************************/
CREATE TABLE IS_GIVEN 
(
  date_given    DATE NOT NULL,
  amount_given  FLOAT NOT NULL,

  FOREIGN KEY (_grant_id) REFERENCES GRANTS(_grant_id),
  FOREIGN KEY (_theater_company_id) REFERENCES THEATER_COMPANY(_theater_company_id)
);

CREATE TABLE HOSTS 
(
  hosting_fee     FLOAT NOT NULL,
  comedian_cost   FLOAT NOT NULL,
  traveling_cost  FLOAT NOT NULL,
  staging_cost    FLOAT NOT NULL,

  FOREIGN KEY (_representation_id) REFERENCES REPRESENTATION(_representation_id),
  FOREIGN KEY (_theater_company_id) REFERENCES THEATER_COMPANY(_theater_company_id)
);

CREATE TABLE BUYS 
(
  buying_date DATE NOT NULL,

  FOREIGN KEY (_customer_id) REFERENCES CUSTOMER(_customer_id),
  FOREIGN KEY (_ticket_id) REFERENCES TICKETS(_ticket_id)
);