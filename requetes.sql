-- Prévoir quand la companie sera dans le rouge
-- Prévoir quand la companie sera dans le rouge longtemps

-- Prévoir les revenus d'une représentationbasés sur la capacity 
create function earning_capacity (rep IN NUMBER)--representation id
RETURN NUMBER
begin 
    Return (select hall_capacity from theater_company , representation where representation_id = rep 
            and representation.theater_company_id =theater_company.theater_company_id;)
        * (select price from tickets, representation where representation_id = rep 
            and tickets.ticket_id = representation.ticket_id;)
end;

-- Déterminer si le coût sera amorti avec les potentielles recettes
create function amortization (cre IN NUMBER) --creation id
RETURN varchar(15)

earning NUMBER ;
rep NUMBER;
begin   
    rep := (select representation_id from representation where cre.creation_id = representation.creation_id);
    earning := earning_capacity(rep);
    if earnin * (select count(*) from representation where representation_id = rep.representation_id 
    group by representation_id;) < 0 then
        return  "no amortization";
    else 
        return "amortization";
    endif;
end;


-- Effective cost : Costs/Ticketing
create function effective_cost (rep IN NUMBER)--representation id
RETURN NUMBER
begin 
    Return (select creation_cost from creations, representation where 
        rep.representation_id = representation.representation_id and creation.creation_id = representation.creation_id;)
        / ((select price from tickets, representation where representation_id = rep 
            and tickets.ticket_id = representation.ticket_id;) 
            * (select count(*) from representation where representation_id = rep 
                and tickets.ticket_id = representation.ticket_id;))
end;

-- Déterminer les companies qui jouent jamais dans des théâtres
select theater_company_id from theater_company --select all row from theater_company
left join representation on representation.theater_company_id = theater_company.theater_company_id --find row in representation with same company id, otherwise have null
where representation.theater_company_id is NULL; --pick only result where id in representation is  null

-- Quelles companies font systématiquement leur first show dehors/en intérieur
Create procedure first_show
begin 
    dbms_output.put_line ("theatre id | in their theatre or outside")
    for theatre in (select * from theater_company) loop
        if theatre in (select theater_company_id from theater_company
        left join representation on representation.theater_company_id = theater_company.theater_company_id)
            dbms_output.put_line (theatre.theater_company_id '|  inside' );
        
        else
            dbms_output.put_line (theatre.theater_company_id '|  outside' );
        endif;
    endloop;
end;

-- Calculer le prix moyen des tickets vendus par companie
Create procedure average_ticket_price
is
average NUMBER;

begin 
    dbms_output.put_line ("theatre id | average ticket price")
    for  theatre in (select * from theater_company) loop
        average := (select avg(price) from tickets,representation  
                    where theatre.theater_company_id = representation.representation_id
                    and representation.ticket_id = tickets.ticket_id;)

        dbms_output.put_line (theatre '|' average);
    endloop;
end;


-- Quels sont les show les plus populaires (en fonction d'une période de temps) 
--en fonction de # représentations
create function most_popular_representation(startDate DATE, endDate DATE)
RETURN NUMBER

begin
    SELECT representation_id most_popular from representation
    where representation.date > startDate AND representation.date < endDate
    group by representation_id order by count(representation_id) DESC
    limit 1;

    return most_popular;
end;

-- Quels sont les show les plus populaires (en fonction d'une période de temps) 
--en fonction de # potential viewers
create function most_popular_viewer(startDate DATE, endDate DATE)
RETURN NUMBER

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

create function most_popular_ticket(startDate DATE, endDate DATE)
RETURN NUMBER

begin
    SELECT representation_id most_popular from representation,tickets
    where representation.date > startDate AND representation.date < endDate 
    AND ticket.representation_id = representation.representation_id
    group by representation_id order by count(tickets.representation_id) DESC
    limit 1;

    return most_popular;
end;