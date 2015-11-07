select 	c.firstname, c.lastname, p.name, wk.wknr, wk.name, fs.name, lp.position
from 	candidates c join partymembership pm on pm.idno = c.idno join party p on p.pid=pm.pid 
	join candidacy ca on ca.idno = c.idno join wahlkreis wk on wk.wkid = ca.wkid
	join landeslistenplatz lp on lp.idno = c.idno join landesliste ll on lp.llid = ll.llid
	join federalstate fs on fs.fsid = ll.fsid
where c.lastname='Leucht'

