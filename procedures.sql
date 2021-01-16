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
create or replace trigger not_two_same_representation_place
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

        elseif inserting then   
            insert into theater_company values (:new.theater_company_id,:new.hall_capacity,:new.budget,:new.city,:new.balance);
        endif;
    end;


--Archive transaction when there is a movement


--Compute reduce_rate if 1 of 4 condition is met (job, age, filling, date)S