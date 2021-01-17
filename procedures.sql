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