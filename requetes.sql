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
-- Déterminer les companies qui jouent jamais dans des théâtres
-- Quelles companies font systématiquement leur first show dehors/en intérieur
-- Calculer le prix moyen des tickets vendus par companie
-- Quels sont les show les plus populaires (en fonction d'une période de temps) en fonction de # représentations
-- Quels sont les show les plus populaires (en fonction d'une période de temps) en fonction de # potential viewers
-- Quels sont les show les plus populaires (en fonction d'une période de temps) en fonction de # seats sold

