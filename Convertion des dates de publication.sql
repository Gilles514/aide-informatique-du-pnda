update NOTICES4 set annee = substring(PUBLICATION from CHAR_LENGTH(PUBLICATION)-4 for 4)
where ANNEE not like '1%'  and ANNEE not like '2%' and publication like '%.';

update NOTICES4 set annee = substring(PUBLICATION from POSITION('[19' in PUBLICATION)+1 for 4)
where ANNEE not like '1%'  and ANNEE not like '2%' and publication like '%[19%';

update NOTICES4 set annee = substring(PUBLICATION from POSITION('[20' in PUBLICATION)+1 for 4)
where ANNEE not like '1%'  and ANNEE not like '2%' and publication like '%[20%';

update NOTICES4 set annee = substring(PUBLICATION from POSITION('19' in PUBLICATION) for 4)
where ANNEE not like '1%'  and ANNEE not like '2%' and publication like '%19%';

update NOTICES4 set annee = substring(PUBLICATION from POSITION('20' in PUBLICATION) for 4)
where ANNEE not like '1%'  and ANNEE not like '2%' and publication like '%20%';

select ID_NOTICE, substring(PUBLICATION from POSITION('[19' in PUBLICATION)+1 for 4), PUBLICATION, ANNEE from notices4 
where ANNEE not like '1%'  and ANNEE not like '2%' and publication like '%[19%';

select count(*), n.UA, n4.ANNEE from notices4 n4 
JOIN EXEMPLAIRES e on n4.ID_NOTICE = e.ID_NOTICE
JOIN NOTICES n on n.ID_NOTICE = n4.ID_NOTICE
where n4.ANNEE like '1%'  or n4.ANNEE  like '2%' and (e.DATEINVENTAIRE is not null or e.statut is not null) 
group by n.UA, n4.ANNEE;

select n.UA, n4.ANNEE, n4.PREMIER, count(*) from notices4 n4 
JOIN EXEMPLAIRES e on n4.ID_NOTICE = e.ID_NOTICE
JOIN NOTICES n on n.ID_NOTICE = n4.ID_NOTICE
where n4.ANNEE like '1%'  or n4.ANNEE  like '2%' and (e.DATEINVENTAIRE is not null or e.statut is not null) 
group by n.UA, n4.ANNEE, n4.PREMIER;