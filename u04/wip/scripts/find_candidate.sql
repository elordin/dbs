select 	c.firstname, c.lastname, p1.name as dk_party, wk.wknr, wk.name as wk_name, ca.cid as cid, ca.votes as dk_votes, fs.name as fs_name, p2.name as ll_party, lp.position as ll_pos
from 	candidates c
	left outer join candidacy ca on ca.idno = c.idno left outer join wahlkreis wk on wk.wkid = ca.wkid
	left outer join party p1 on p1.pid=ca.supportedby 
	left outer join landeslistenplatz lp on lp.idno = c.idno left outer join landesliste ll on lp.llid = ll.llid
	left outer join party p2 on p2.pid= ll.pid 
	left outer join federalstate fs on fs.fsid = ll.fsid
where c.lastname='Di Leo'  --and c.firstname='Gino'

