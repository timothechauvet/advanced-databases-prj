-- A link to out Github project : https://github.com/timothechauvet/advanced-databases-prj 
-- Tables destructions

drop table THEATER_COMPANY    CASCADE CONSTRAINTS;
drop table CREATIONS          CASCADE CONSTRAINTS;
drop table REPRESENTATION     CASCADE CONSTRAINTS;
drop table GRANTS             CASCADE CONSTRAINTS;
drop table TICKETS            CASCADE CONSTRAINTS;
drop table CUSTOMER           CASCADE CONSTRAINTS;
drop table REDUCE_RATE        CASCADE CONSTRAINTS;
drop table DEBUGTABLE         CASCADE CONSTRAINTS;
drop table ARCHIVE            CASCADE CONSTRAINTS;

-- Setup the environment
ALTER SESSION SET NLS_DATE_FORMAT = 'DD-MM-YYYY';
set serveroutput on;

-- Create tables
/***************************** THEATER **********************************/

CREATE TABLE THEATER_COMPANY
(
  theater_company_id     NUMBER NOT NULL, /*ID*/

  hall_capacity           NUMBER NOT NULL,
  name_company            VARCHAR(64) NOT NULL,
  budget                  FLOAT NOT NULL,
  city                    VARCHAR(64) NOT NULL,
  balance                 FLOAT NOT NULL,

  PRIMARY KEY (theater_company_id),
  CONSTRAINT BUDGET_CSTR CHECK(budget >= 0)
);

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
  representation_id       NUMBER NOT NULL,

  date_representation     DATE NOT NULL,
  normal_reference_rate   FLOAT NOT NULL,
  reduced_reference_rate  FLOAT NOT NULL,
  money_made              FLOAT NOT NULL,
  tickets_sold            NUMBER,
  city_representation     VARCHAR(64),
  theater_company_id      NUMBER NOT NULL, 
  
  creation_id             NUMBER NOT NULL,

  PRIMARY KEY (representation_id),
  FOREIGN KEY (creation_id) REFERENCES CREATIONS(creation_id),
  FOREIGN KEY (theater_company_id) REFERENCES THEATHER_COMPANY(creation_id)
  FOREIGN KEY (ticket_id) REFERENCES TICKETS(ticket_id)
);

/*List cities where a company plays between two dates*/
CREATE OR REPLACE FUNCTION citiesPlayedTwoDates(date_beginning DATE, date_ending DATE, tmp_name VARCHAR)
RETURN varchar
IS done_return varchar(64);
begin
  dbms_output.put_line('- Cities where '||tmp_name||' company played between '||TO_CHAR(date_beginning)||' and '||TO_CHAR(date_ending)||' -');
  FOR CITYNAME IN (
    SELECT r.city_representation
    FROM THEATER_COMPANY t, CREATIONS c, REPRESENTATION r
    WHERE r.creation_id = c.creation_id
      AND t.theater_company_id = c.theater_company_id
      AND t.name_company = tmp_name
      AND date_beginning <= r.date_representation
      AND r.date_representation <= date_ending
  ) LOOP
    dbms_output.put_line(CITYNAME.city_representation);
  END LOOP;
    
  RETURN 'END';
end;

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
  amount_given  FLOAT NOT NULL,

  theater_company_id NUMBER NOT NULL,

  PRIMARY KEY (grant_id),
  FOREIGN KEY (theater_company_id) REFERENCES THEATER_COMPANY(theater_company_id)
);

CREATE OR REPLACE FUNCTION giveGrant(currDate DATE)
RETURN varchar
IS done_grant varchar(64);
begin
  FOR CURRGRANT IN (SELECT * FROM GRANTS) loop
    -- If we reached the next mensuality of the grant, we move the next mensuality 
    IF CURRGRANT.number_months > 0 AND CURRGRANT.date_start = currDate THEN 
        CURRGRANT.date_start := ADD_MONTHS(currDate, 1);

        -- Update the balance of the theater company
        update THEATER_COMPANY
           set balance=balance + CURRGRANT.amount_given
         where CURRGRANT.theater_company_id = theater_company_id;
    END IF;
  end loop;
  RETURN 'END';
end;

/***************************** TICKETS **********************************/

CREATE TABLE TICKETS
(
  ticket_id          NUMBER NOT NULL,

  price               FLOAT NOT NULL,
  promotion           FLOAT NOT NULL,
  buying_date         DATE NOT NULL,
  
  representation_id  NUMBER NOT NULL,

  PRIMARY KEY (ticket_id),
  FOREIGN KEY (customer_id) REFERENCES CUSTOMER(customer_id),
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

CREATE OR REPLACE TRIGGER reducedTicketsRates
  AFTER INSERT OR UPDATE ON TICKETS
  FOR EACH ROW
  DECLARE
    rate FLOAT;
  begin
    SELECT percentage INTO rate
    FROM REDUCE_RATE r
    WHERE :NEW.representation_id = r.representation_id;

    UPDATE (SELECT :NEW.promotion promo
            FROM REDUCE_RATE r, CUSTOMER c
            WHERE c.customer_id = :NEW.customer_id
              AND c.age <= r.age_reduce
              AND r.representation_id = :NEW.representation_id)
    SET promo = rate;
  end;

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
    -- Call all functions that rely on the current time
  ELSE
    giveGrant(:NEW.curr_date);
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

/************************ FILL DATA ****************************/
-- Theater company
                                --(id, capacity, name, budget, city, balance)
INSERT INTO THEATER_COMPANY VALUES(1, 300, 'Wakanim', 32000, 'Ineretu', 50798);
INSERT INTO THEATER_COMPANY VALUES(2, 57, 'Caldwell', 20046, 'Sutufo', 79164);
INSERT INTO THEATER_COMPANY VALUES(3, 78, 'Vasquez', 22422, 'Wuhilre', 39315);
INSERT INTO THEATER_COMPANY VALUES(4, 323, 'Underwood', 3272, 'Ficzuzem', 77914);
INSERT INTO THEATER_COMPANY VALUES(5, 55, 'Morton', 1502, 'Loghene', 49319);
INSERT INTO THEATER_COMPANY VALUES(6, 286, 'Miles', 19484, 'Hebauke', 52953);
INSERT INTO THEATER_COMPANY VALUES(7, 494, 'Nelson', 19741, 'Ticosgeg', 94483);

-- Creations
                          --(id, cost, promo, FK theater)
INSERT INTO CREATIONS VALUES(1, 1000, 0, 6);
INSERT INTO CREATIONS VALUES(2, 2813, 0.1, 5);
INSERT INTO CREATIONS VALUES(3, 2863, 0, 3);
INSERT INTO CREATIONS VALUES(4, 1551, 0.3, 6);
INSERT INTO CREATIONS VALUES(5, 1143, 0, 2);
INSERT INTO CREATIONS VALUES(6, 2543, 0, 3);
INSERT INTO CREATIONS VALUES(7, 1074, 0.7, 5);

-- Representation
                               --(id, date, normal, reduced, money, #tickets,FK ticket, city, FK creation)
INSERT INTO REPRESENTATION VALUES( 1, '01-01-2021', 15, 10, 0, 100,0, 'Owocasok', 1);
INSERT INTO REPRESENTATION VALUES( 2, '02-01-2021', 10,  8, 0,  27,1, 'Fufebokar', 1);
INSERT INTO REPRESENTATION VALUES( 3, '04-01-2021', 20, 17, 0, 242,1, 'Fegifpez', 6);
INSERT INTO REPRESENTATION VALUES( 4, '03-01-2021', 20,  6, 0, 348,2, 'Neibbi', 2);
INSERT INTO REPRESENTATION VALUES( 5, '06-01-2021', 25, 13, 0, 306,2, 'Duwafen', 3);
INSERT INTO REPRESENTATION VALUES( 6, '05-01-2021', 29, 11, 0, 205,4, 'Wiefeze', 7);
INSERT INTO REPRESENTATION VALUES( 7, '04-01-2021', 21, 17, 0,  72,3, 'Miwdasi', 3);
INSERT INTO REPRESENTATION VALUES( 8, '05-01-2021', 18, 10, 0, 147,4, 'Igogiac', 2);
INSERT INTO REPRESENTATION VALUES( 9, '01-01-2021',  6,  5, 0, 123,2, 'Wazuri', 2);
INSERT INTO REPRESENTATION VALUES(10, '01-01-2021', 15, 10, 0, 131,5, 'Avejubci', 7);
INSERT INTO REPRESENTATION VALUES(11, '02-01-2021', 10,  8, 0, 168,3, 'Vezkafof', 5);
INSERT INTO REPRESENTATION VALUES(12, '04-01-2021', 20, 17, 0, 187,5, 'Erufoszuw', 1);
INSERT INTO REPRESENTATION VALUES(13, '03-01-2021', 20,  6, 0, 251,4, 'Isitiwac', 4);
INSERT INTO REPRESENTATION VALUES(14, '06-01-2021', 25, 13, 0, 291,4, 'Zekkoeme', 1);
INSERT INTO REPRESENTATION VALUES(15, '05-01-2021', 29, 11, 0, 283,4, 'Seguwe', 5);
INSERT INTO REPRESENTATION VALUES(16, '04-01-2021', 21, 17, 0, 142,4, 'Leojini', 5);
INSERT INTO REPRESENTATION VALUES(17, '05-01-2021', 18, 10, 0, 299,2, 'Tedetjaf', 6);
INSERT INTO REPRESENTATION VALUES(18, '01-01-2021',  6,  5, 0, 147,5, 'Fulafobet', 5);
INSERT INTO REPRESENTATION VALUES(19, '01-01-2021', 15, 10, 0, 129,3, 'Ilfopi', 5);
INSERT INTO REPRESENTATION VALUES(20, '02-01-2021', 10,  8, 0, 112,2, 'Ledirbot', 7);
INSERT INTO REPRESENTATION VALUES(21, '04-01-2021', 20, 17, 0, 144,0, 'Banhatep', 6);
INSERT INTO REPRESENTATION VALUES(22, '03-01-2021', 20,  6, 0, 133,1, 'Uftiupo', 6);
INSERT INTO REPRESENTATION VALUES(23, '06-01-2021', 25, 13, 0, 198,1, 'Fisuami', 4);
INSERT INTO REPRESENTATION VALUES(24, '05-01-2021', 29, 11, 0, 121,1, 'Topihun', 6);
INSERT INTO REPRESENTATION VALUES(25, '04-01-2021', 21, 17, 0, 112,2, 'Semobe', 4);
INSERT INTO REPRESENTATION VALUES(26, '05-01-2021', 18, 10, 0, 172,5, 'Fufosfit', 3);
INSERT INTO REPRESENTATION VALUES(27, '01-01-2021',  6,  5, 0, 126,4, 'Potrebi', 6);

-- Customer
                         --(id, age, mail, name, job)
INSERT INTO CUSTOMER VALUES( 1, 66, 'tizol@zo.cv', 'Andre Chambers', 'retired');
INSERT INTO CUSTOMER VALUES( 2,  9, 'fo@mib.ht', 'Loretta Black', 'kid');
INSERT INTO CUSTOMER VALUES( 3, 12, 'hot@raukdew.at', 'Rebecca Spencer', 'kid');
INSERT INTO CUSTOMER VALUES( 4, 36, 'fiditefir@ruoticu.va', 'Glen Allen', 'manager');
INSERT INTO CUSTOMER VALUES( 5, 59, 'netijof@ec.tg', 'Arthur McCormick', 'programmer');
INSERT INTO CUSTOMER VALUES( 6, 61, 'conidzur@lufupe.sy', 'Cameron Estrada', 'manager');
INSERT INTO CUSTOMER VALUES( 7, 19, 'goksu@hi.cz', 'Bruce Stevenson', 'student');
INSERT INTO CUSTOMER VALUES( 8, 22, 'we@cowope.lv', 'Rebecca Nash', 'student');
INSERT INTO CUSTOMER VALUES( 9, 17, 'setuzawi@ga.su', 'Mittie Hale', 'student');
INSERT INTO CUSTOMER VALUES(10, 56, 'imoumomug@nor.ws', 'Devin Dawson', 'manager');


-- Reduce rate
--(id, age, job, %, start, end, completion, FK representation_id)
INSERT INTO REDUCE_RATE VALUES( 1, 21, 'unemployed', 0.6, '01-01-2021', '04-01-2021', 0.4, 3);
INSERT INTO REDUCE_RATE VALUES( 2, 15, 'unemployed', 0.8, '03-01-2021', '04-01-2021', 0.5, 2);
INSERT INTO REDUCE_RATE VALUES( 3, 11, 'retired', 0.5, '01-01-2021', '01-01-2021', 0.6, 3);
INSERT INTO REDUCE_RATE VALUES( 4, 11, 'student', 0.4, '02-01-2021', '02-01-2021', 0.2, 5);
INSERT INTO REDUCE_RATE VALUES( 5, 25, 'student', 0.5, '01-01-2021', '01-01-2021', 0.1, 5);
INSERT INTO REDUCE_RATE VALUES( 6, 24, 'unemployed', 0.7, '01-01-2021', '05-01-2021', 0.5, 4);
INSERT INTO REDUCE_RATE VALUES( 7, 23, 'student', 0.7, '02-01-2021', '05-01-2021', 0.2, 5);
INSERT INTO REDUCE_RATE VALUES( 8, 16, 'unemployed', 0.6, '01-01-2021', '01-01-2021', 0.2, 3);
INSERT INTO REDUCE_RATE VALUES( 9, 20, 'retired', 0.3, '03-01-2021', '04-01-2021', 0.2, 5);
INSERT INTO REDUCE_RATE VALUES(10, 12, 'retired', 0.8, '02-01-2021', '03-01-2021', 0.6, 5);
INSERT INTO REDUCE_RATE VALUES(11, 23, 'student', 0.1, '03-01-2021', '03-01-2021', 0.1, 4);
INSERT INTO REDUCE_RATE VALUES(12, 25, 'student', 0.8, '02-01-2021', '03-01-2021', 0.5, 5);
INSERT INTO REDUCE_RATE VALUES(13, 10, 'unemployed', 0.6, '01-01-2021', '02-01-2021', 0.6, 2);
INSERT INTO REDUCE_RATE VALUES(14, 24, 'unemployed', 0.8, '02-01-2021', '04-01-2021', 0.6, 2);
INSERT INTO REDUCE_RATE VALUES(15, 25, 'retired', 0.9, '02-01-2021', '01-01-2021', 0.5, 3);
INSERT INTO REDUCE_RATE VALUES(16, 11, 'retired', 0.8, '01-01-2021', '01-01-2021', 0.4, 2);
INSERT INTO REDUCE_RATE VALUES(17, 14, 'kid', 0.1, '03-01-2021', '03-01-2021', 0.6, 2);
INSERT INTO REDUCE_RATE VALUES(18, 19, 'retired', 0.9, '03-01-2021', '05-01-2021', 0.4, 4);
INSERT INTO REDUCE_RATE VALUES(19, 22, 'retired', 0.9, '02-01-2021', '02-01-2021', 0.3, 2);
INSERT INTO REDUCE_RATE VALUES(20, 10, 'student', 0.1, '03-01-2021', '03-01-2021', 0.5, 4);
INSERT INTO REDUCE_RATE VALUES(21, 10, 'kid', 0.6, '01-01-2021', '02-01-2021', 0.2, 3);

-- Tickets
--(id, price, promo, date, FK representation_id, FK customer_id)
INSERT INTO TICKETS VALUES( 1, 13, , '09-01-2021', 6, 10);
INSERT INTO TICKETS VALUES( 2, 28, , '05-01-2021', 22, 8);
INSERT INTO TICKETS VALUES( 3, 20, , '05-01-2021', 18, 9);
INSERT INTO TICKETS VALUES( 4, 24, , '04-01-2021', 5, 7);
INSERT INTO TICKETS VALUES( 5, 30, , '01-01-2021', 14, 9);
INSERT INTO TICKETS VALUES( 6, 12, , '09-01-2021', 5, 1);
INSERT INTO TICKETS VALUES( 7, 24, , '03-01-2021', 5, 6);
INSERT INTO TICKETS VALUES( 8, 23, , '04-01-2021', 12, 2);
INSERT INTO TICKETS VALUES( 9, 25, , '02-01-2021', 18, 10);
INSERT INTO TICKETS VALUES(10, 20, , '03-01-2021', 8, 1);
INSERT INTO TICKETS VALUES(11, 28, , '01-01-2021', 14, 6);
INSERT INTO TICKETS VALUES(12, 10, , '08-01-2021', 11, 2);
INSERT INTO TICKETS VALUES(13, 13, , '02-01-2021', 20, 8);
INSERT INTO TICKETS VALUES(14, 26, , '01-01-2021', 10, 7);
INSERT INTO TICKETS VALUES(15, 24, , '09-01-2021', 10, 6);
INSERT INTO TICKETS VALUES(16, 21, , '07-01-2021', 23, 1);
INSERT INTO TICKETS VALUES(17, 30, , '03-01-2021', 15, 3);
INSERT INTO TICKETS VALUES(18, 14, , '05-01-2021', 1, 6);
INSERT INTO TICKETS VALUES(19, 14, , '09-01-2021', 4, 4);
INSERT INTO TICKETS VALUES(20, 14, , '02-01-2021', 26, 2);
INSERT INTO TICKETS VALUES(21, 15, , '06-01-2021', 20, 3);
INSERT INTO TICKETS VALUES(22, 19, , '09-01-2021', 20, 1);
INSERT INTO TICKETS VALUES(23, 27, , '09-01-2021', 26, 4);
INSERT INTO TICKETS VALUES(24, 30, , '03-01-2021', 21, 4);
INSERT INTO TICKETS VALUES(25, 24, , '02-01-2021', 5, 10);
INSERT INTO TICKETS VALUES(26, 28, , '01-01-2021', 15, 6);
INSERT INTO TICKETS VALUES(27, 27, , '08-01-2021', 11, 5);
INSERT INTO TICKETS VALUES(28, 10, , '09-01-2021', 9, 7);
INSERT INTO TICKETS VALUES(29, 20, , '09-01-2021', 26, 4);
INSERT INTO TICKETS VALUES(30, 26, , '05-01-2021', 6, 8);

/******************************* PROCEDURES *******************************************/
--No two representation at same time from same company
create or replace trigger not_two_same_representation_time
before insert or update on representation

for each row
    declare
        not_same_time exception;
begin 
    for rep in (select * from representation) loop 
        refcomp := (select theater_company_id from creation, representation 
                    where creation.creation_id =  rep.creation_id;) --get id of company
        
        for rep2 in (select * from representation) loop
            refcomp2 := (select theater_company_id from creation, representation 
                    where creation.creation_id =  rep2.creation_id;)
            if rep.date == rep2.date AND refcomp == refcomp2 then 
                raise not_same_time
        endloop;
    endloop;

    when (not_same_time) then
        raise_application_error (-2000, 'no representation from same company at same time');
end;
    
--No two representation at same place from same company
create or replace trigger  
before insert or update on representation

for each row
    declare
        not_same_place exception;
begin 
    for rep in (select * from representation) loop
        refcomp := (select theater_company_id from creation, representation 
                    where company.creation_id =  rep.creation_id;) --get id of company

        refhost := (select theater_company_id from host, representation
                            where rep.representation_id = host.representation_id;) --get id of host
        
        for rep2 in (select * from representation) loop
            refcomp2 := (select theater_company_id from creation, representation 
                    where creation.creation_id =  rep2.creation_id;)

            refhost2 := (select theater_company_id from host, representation
                        where rep2.representation_id = host.representation_id;) --get id of host

            if refhost == refhost2 AND refcomp == refcomp2 then 
                raise not_same_place
        endloop;
    endloop;

    when (not_same_place) then
        raise_application_error (-2001, 'no representation from same company at same place');
end;

--Balance is updated daily/with any change
create or replace trigger update_balance
before update, insert or delete on theater_company

for each row
    begin
        if inserting then   
            insert into theater_company values (:new.theater_company_id,:new.hall_capacity,:new.budget,:new.city,:new.balance);
       
        elsif deleting then   
            insert into theater_company values (:new.theater_company_id,:new.hall_capacity,:new.budget,:new.city,:new.balance);

        elseif updating then   
            insert into theater_company values (:new.theater_company_id,:new.hall_capacity,:new.budget,:new.city,:new.balance);
        endif;
    end;


--Archive transaction when there is a movement
create procedure archive_transaction
is
curr_date DATE = getcurrdate();

declare
@ReportStartDate DATE= month(curr_date, -1), --it run each end of month
@ReportEndDate DATE= month(curr_date)

if @ReportEndDate=curr_date
Begin
    for curr_grant in (select * from grant) loop
        if curr_grant.date_start < curr_date AND curr_grant.date_end > curr_date then
            insert into archive values ((SELECT max(trans_id) FROM archive)+1,curr_date,curr_grant.amount,"automatic transfer from "+ entity)  ;

        endif;
    endloop;
end;
   

--Compute reduce_rate if 1 of 4 condition is met (job, age, filling, date)
create procedure compute_reduce_rate
is
reduction_p NUMBER;
price NUMBER;
reduce_rate NUMBER;

begin
    for curr_customer in (select * from customer) loop
        if curr_customer.age in (select age_reduce from reduce_rate) then
            reduction_p := (select precentage from reduce_rate 
                            where curr_customer.age == age_reduce;)
        
        elsif curr_customer.job in (select job_reduce from reduce_rate) then
            reduction_p := (select precentage from reduce_rate 
                            where curr_customer.job == job_reduce;)

        elsif curr_customer.customer_id in (select customer_id from buys, reduce_rate
                                            where buying_date > reduce_rate.starting_date
                                            AND buying_date < reduce_rate.finish_date) then
            reduction_p := (select precentage from reduce_rate , buys
                            where curr_customer.customer_id == buys.customer_id and buys.buying_date > reduce_rate.starting_date
                            and buys.buying_date < reduce_rate.finish_date ;)

        elsif curr_customer.customer_id in (select customer_id from buys, reduce_rate
                                            where count(customer_id) < reduce_rate.completion_percentage) then
            reduction_p := (select precentage from reduce_rate ,buys
                            where curr_customer.customer_id == buys.customer_id and count(customer_id) < reduce_rate.completion_percentage);)

      
        price := (select price from buys 
                    where customer_id== curr_customer.customer_id;)
        reduce_rate := price * (1-reduction_p) ;
    endloop;
end;

/******************************** SQL QUERIES ************************************/
-- List the cities where a company played during a time period
begin
  dbms_output.put_line(citiesplayedtwodates('01-01-2021', '03-01-2021', 'Vasquez'));
end;

-- Prévoir quand la companie sera dans le rouge
-- Prévoir quand la companie sera dans le rouge longtemps

-- Prévoir les revenus d'une représentationbasés sur la capacity 
create or replace function earning_capacity (rep IN NUMBER)--representation id
RETURN NUMBER
IS
    hall_cap NUMBER;
    tick_price NUMBER;
    begin 
    
        select hall_capacity into hall_cap
        from theater_company , representation 
        where representation_id = rep and representation.theater_company_id =theater_company.theater_company_id;
        
        select price into tick_price
        from tickets, representation 
        where representation_id = rep and tickets.representation_id = reduce_rate.representation_id;
        
        return (hall_cap*tick_price);
    end;

-- Déterminer si le coût sera amorti avec les potentielles recettes
create or replace function amortization (cre IN NUMBER) --creation id
RETURN varchar
IS
    rep NUMBER;
    factor NUMBER;
    earning NUMBER := earning_capacity(rep);

    begin   
        select representation_id into rep 
        from representation ,creations
        where cre.creation_id = representation.creation_id;

        select count(*) into factor
        from representation where representation_id = rep.representation_id 
        group by representation_id;
        
        if (earning *factor < 0) then
            return  'no amortization';
        else 
            return 'amortization';
        end if;
    end;


-- Effective cost : Costs/Ticketing
create or replace function effective_cost (rep IN NUMBER)--representation id
RETURN NUMBER
IS
    cre_cost NUMBER;
    tick_price NUMBER;
begin 
    select creation_cost INTO cre_cost
    from creations, representation 
    where rep.representation_id = representation.representation_id and creations.creation_id = representation.creation_id;
    
    select price INTO tick_price
    from tickets, representation 
    where representation_id = rep and tickets.representation_id = reduce_rate.representation_id;
    
    select count(*) into tick_nbr
    from representation,tickets where representation_id = rep and tickets.representation_id = reduce_rate.representation_id;
                
    Return cre_cost/(tick_price * rep.tickets_sold);
end;

-- Déterminer les companies qui jouent jamais dans des théâtres
select theater_company_id from theater_company --select all row from theater_company
left join representation on representation.theater_company_id = theater_company.theater_company_id --find row in representation with same company id, otherwise have null
where representation.theater_company_id is NULL; --pick only result where id in representation is  null

-- Quelles companies font systématiquement leur first show dehors/en intérieur
Createor replace procedure first_show
begin 
    dbms_output.put_line ("theatre id | in their theatre or outside");
    for theatre in (select * from theater_company) loop
        if theatre in (select theater_company_id from theater_company left join representation on representation.theater_company_id = theater_company.theater_company_id)
            dbms_output.put_line (theatre.theater_company_id '|  inside' );

        else
            dbms_output.put_line (theatre.theater_company_id '|  outside' );
        end if;
    end loop;
end;

-- Calculer le prix moyen des tickets vendus par companie
Create or replace procedure average_ticket_price
is
average NUMBER;

begin 
    dbms_output.put_line ('theatre id | average ticket price');
    for  theatre in (select * from theater_company) loop
        select avg(price) into average
        from tickets,representation  
        where theatre.theater_company_id = representation.representation_id and tickets.representation_id = reduce_rate.representation_id;

        dbms_output.put_line(theatre '|' average);
    end loop;
end;


-- Quels sont les show les plus populaires (en fonction d'une période de temps) 
--en fonction de # représentations
create or replace function most_popular_representation(startDate DATE, endDate DATE)
RETURN NUMBER
IS
begin
    SELECT representation_id most_popular from representation
    where representation.date > startDate AND representation.date < endDate
    group by representation_id order by count(representation_id) DESC
    limit 1;

    return most_popular;
end;

-- Quels sont les show les plus populaires (en fonction d'une période de temps) 
--en fonction de # potential viewers
create or replace function most_popular_viewers(startDate DATE, endDate DATE)
RETURN NUMBER
IS
begin
    SELECT representation_id most_popular from representation, theater_company
    where representation.date > startDate AND representation.date < endDate
    AND representation.theater_company_id = theater_company.theater_company_id
    Group by representation_id order by sum(hall_capacity) DESC
    limit 1;

    return most_popular;
end;


-- Quels sont les show les plus populaires (en fonction d'une période de temps) 
--en fonction de # seats sold

create or replace function most_popular_ticket(startDate DATE, endDate DATE)
RETURN NUMBER
IS
begin
    SELECT representation_id most_popular from representation,tickets
    where representation.date > startDate AND representation.date < endDate 
    AND ticket.representation_id = representation.representation_id
    group by representation_id order by count(tickets.representation_id) DESC
    limit 1;

    return most_popular;
end;
