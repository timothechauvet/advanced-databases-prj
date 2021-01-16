-- Tables destructions

drop table THEATER_COMPANY    CASCADE CONSTRAINTS;
drop table CREATIONS          CASCADE CONSTRAINTS;
drop table REPRESENTATION     CASCADE CONSTRAINTS;
drop table GRANTS             CASCADE CONSTRAINTS;
drop table TICKETS            CASCADE CONSTRAINTS;
drop table CUSTOMER           CASCADE CONSTRAINTS;
drop table REDUCE_RATE        CASCADE CONSTRAINTS;
drop table DEBUGTABLE              CASCADE CONSTRAINTS;
drop table ARCHIVE            CASCADE CONSTRAINTS;

-- Edit date format
ALTER SESSION SET NLS_DATE_FORMAT = 'DD-MM-YYYY';

-- Create tables
/***************************** THEATER **********************************/

CREATE TABLE THEATER_COMPANY
(
  theater_company_id     NUMBER NOT NULL, /*ID*/

  hall_capacity           NUMBER NOT NULL,
  name_company            VARCHAR(64) NOT NULL;
  budget                  FLOAT NOT NULL,
  city                    VARCHAR(64) NOT NULL,
  balance                 FLOAT NOT NULL

  PRIMARY KEY (theater_company_id),
  CONSTRAINT BUDGET_CSTR CHECK(budget >= 0)
);

CREATE OR REPLACE TRIGGER balance_update
    AFTER UPDATE OF curr_date ON DEBUGTABLE
    FOR EACH ROW
    begin
      IF DAY(curr_date) = 1 THEN
        balance
      END IF
    end;

/***************************** CREATIONS **********************************/

CREATE TABLE CREATIONS
(
  creation_id            NUMBER NOT NULL,

  creation_cost           FLOAT NOT NULL,
  promotion_creations     FLOAT NOT NULL,
  
  theater_company_id     NUMBER NOT NULL,

  PRIMARY KEY (creation_id),
  FOREIGN KEY (theater_company_id) REFERENCES THEATER_COMPANY(theater_company_id),
  /*This will be a factor multiplied with the price in order to apply promotions*/
  CONSTRAINT PROMO_CSTR CHECK(promotion_creations >= 0 AND promotion_creations <= 1) 
);

/***************************** REPRESENTATION **********************************/

CREATE TABLE REPRESENTATION
(
  representation_id      NUMBER NOT NULL,

  date_representation     DATE NOT NULL,
  normal_reference_rate   FLOAT NOT NULL,
  reduced_reference_rate  FLOAT NOT NULL,
  money_made              FLOAT NOT NULL,
  tickets_sold            NUMBER,
  
  creation_id            NUMBER NOT NULL,

  PRIMARY KEY (representation_id),
  FOREIGN KEY (creation_id) REFERENCES CREATIONS(creation_id)
);

CREATE OR REPLACE TRIGGER no_duplicates_representation
    BEFORE INSERT OR UPDATE ON REPRESENTATION
    FOR EACH ROW
    DECLARE no_duplicates_representation_exception EXCEPTION;
    begin
    /*Search if multiple representations at the same date for the same creation exist*/
      IF COUNT(SELECT * FROM REPRESENTATION Re, CREATIONS Cr WHERE Re._creation_id = Cr._creation_id AND Re.date_representation = :NEW.date_representation) > 0
        RAISE no_duplicates_representation_exception;
      END IF;
      EXCEPTION WHEN(no_duplicates_representation_exception) THEN
        RAISE_APPLICATION_ERROR(-20001, 'No duplicates for representations are possible');
    end;

/***************************** GRANTS **********************************/

CREATE TABLE GRANTS
(
  grant_id     NUMBER NOT NULL,

  entity        VARCHAR(64) NOT NULL,
  amount        FLOAT NOT NULL,
  number_months NUMBER NOT NULL,
  date_start    DATE NOT NULL,

  PRIMARY KEY (grant_id)
);

/***************************** TICKETS **********************************/

CREATE TABLE TICKETS
(
  ticket_id          NUMBER NOT NULL,

  price               FLOAT NOT NULL,
  promotion           FLOAT NOT NULL,
  buying_date         DATE NOT NULL,
  
  representation_id  NUMBER NOT NULL,

  PRIMARY KEY (ticket_id),
  FOREIGN KEY (representation_id) REFERENCES REPRESENTATION(representation_id)
);

CREATE TABLE CUSTOMER
(
  customer_id    NUMBER NOT NULL,

  age             NUMBER NOT NULL,
  mail            VARCHAR(64) NOT NULL,
  name_customer   VARCHAR(64) NOT NULL,
  job             VARCHAR(64) NOT NULL,

  PRIMARY KEY (customer_id)
);

CREATE TABLE REDUCE_RATE
(
  reduce_id              NUMBER NOT NULL,

  age_reduce              NUMBER NOT NULL,
  job_reduce              VARCHAR(64) NOT NULL,
  percentage              FLOAT NOT NULL,
  starting_date           DATE NOT NULL,
  finish_date             DATE NOT NULL,
  completion_percentage   FLOAT NOT NULL,

  representation_id      NUMBER NOT NULL,

  PRIMARY KEY (reduce_id),
  FOREIGN KEY (representation_id) REFERENCES REPRESENTATION(representation_id)
);

/***************************** OTHER **********************************/

CREATE TABLE DEBUGTABLE
(
  debugtable_pk NUMBER NOT NULL,

  curr_date DATE NOT NULL,

  PRIMARY KEY (debugtable_pk)
);

INSERT INTO DEBUGTABLE VALUES (1, '17-01-2021');

/*Simple function to get the current date*/
CREATE OR REPLACE FUNCTION getCurrDate
RETURN Date IS
  curr_date_return Date := '01-01-2000';
begin
  SELECT MAX(curr_date) INTO curr_date_return
  FROM DEBUGTABLE;
  
  RETURN curr_date_return;
end;

/*Make it impossible to go back in time for DEBUGTABLE*/
CREATE OR REPLACE TRIGGER timeTrigger
  BEFORE UPDATE ON DEBUGTABLE
  FOR EACH ROW
  DECLARE
    timeFctPreviousDate EXCEPTION;
  
  begin
  IF :OLD.curr_date > :NEW.curr_date THEN
    RAISE timeFctPreviousDate;
  END IF;
    EXCEPTION WHEN timeFctPreviousDate THEN
    RAISE_APPLICATION_ERROR(-20002, 'The new date cannot be before the older one');
  end;

/*Make it impossible to insert or delete the DEBUGTABLE*/
CREATE OR REPLACE TRIGGER timeException
  BEFORE DELETE OR INSERT ON DEBUGTABLE
  FOR EACH ROW
  DECLARE
    timeException EXCEPTION;
  begin
    RAISE timeException;
    EXCEPTION WHEN timeException THEN
    RAISE_APPLICATION_ERROR(-20003, 'You cannot insert or delete on DEBUGTABLE');
  end;

CREATE TABLE ARCHIVE
(
  trans_id           NUMBER NOT NULL,

  date_transaction    DATE NOT NULL,
  amount              FLOAT NOT NULL,
  type_transaction    VARCHAR(16) NOT NULL,

  theater_company_id NUMBER NOT NULL,

  PRIMARY KEY (trans_id),
  FOREIGN KEY (theater_company_id) REFERENCES THEATER_COMPANY(theater_company_id)
);

/**************************** CONNECTION BETWEEN ENTITIES ***********************************/
CREATE TABLE IS_GIVEN 
(
  date_given          DATE NOT NULL,
  amount_given        FLOAT NOT NULL,

  theater_company_id NUMBER NOT NULL,
  grant_id           NUMBER NOT NULL,

  FOREIGN KEY (grant_id) REFERENCES GRANTS(grant_id),
  FOREIGN KEY (theater_company_id) REFERENCES THEATER_COMPANY(theater_company_id)
);

CREATE TABLE HOSTS 
(
  hosting_fee         FLOAT NOT NULL,
  comedian_cost       FLOAT NOT NULL,
  traveling_cost      FLOAT NOT NULL,
  staging_cost        FLOAT NOT NULL,

  theater_company_id NUMBER NOT NULL,
  representation_id  NUMBER NOT NULL,

  FOREIGN KEY (representation_id) REFERENCES REPRESENTATION(representation_id),
  FOREIGN KEY (theater_company_id) REFERENCES THEATER_COMPANY(theater_company_id)
);

CREATE TABLE BUYS 
(
  buying_date   DATE NOT NULL,

  customer_id  NUMBER NOT NULL,
  ticket_id    NUMBER NOT NULL,

  FOREIGN KEY (customer_id) REFERENCES CUSTOMER(customer_id),
  FOREIGN KEY (ticket_id) REFERENCES TICKETS(ticket_id)
);