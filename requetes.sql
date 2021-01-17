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
    else then
        return "amortization"
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
-- Calculer le prix moyen des tickets vendus par companie
-- Quels sont les show les plus populaires (en fonction d'une période de temps) en fonction de # représentations
-- Quels sont les show les plus populaires (en fonction d'une période de temps) en fonction de # potential viewers
-- Quels sont les show les plus populaires (en fonction d'une période de temps) en fonction de # seats sold

