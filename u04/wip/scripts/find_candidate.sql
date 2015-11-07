select 	c.firstname, c.lastname, p.name, wk.wknr, wk.name as wk_name, fs.name as fs_name, lp.position as ll_pos
from 	candidates c join partymembership pm on pm.idno = c.idno join party p on p.pid=pm.pid 
	left outer join candidacy ca on ca.idno = c.idno left outer join wahlkreis wk on wk.wkid = ca.wkid
	left outer join landeslistenplatz lp on lp.idno = c.idno left outer join landesliste ll on lp.llid = ll.llid
	left outer join federalstate fs on fs.fsid = ll.fsid
where c.lastname='Leopold'  --and c.firstname='Gino'

