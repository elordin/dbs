CREATE OR REPLACE VIEW Results_View_Seatdistribution_Bundestag(year, seats, name, shorthand, colourcode, website, isminority) AS (
	SELECT tnospp.year, tnospp.seats, p.name, p.shorthand, p.colourcode, p.website, p.isminority
	FROM Results_TotalNumberOfSeatsPerParty tnospp
	JOIN Party p on p.pid = tnospp.pid
	ORDER BY tnospp.seats DESC
);

CREATE OR REPLACE VIEW Results_View_Delegates(year, title, lastname, firstname, p_name, p_shorthand, p_colourcode, p_website, fsid, fs_name, wkid, wk_name, ctype, listenplatz) AS (
	SELECT  d.year, c.title, c.lastname, c.firstname, p.name as p_name, p.shorthand as p_shorthand, p.colourcode as p_colourcode, p.website as p_website, 
		fs.fsid, fs.name as fs_name, wk.wkid, wk.name as wk_name, d.ctype, d.llpos as listenplatz 
	FROM Results_Delegates d 
	JOIN Candidates c ON d.idno = c.idno
	JOIN Federalstate fs ON fs.fsid = d.fsid
	JOIN Party p ON p.pid=d.pid
	LEFT OUTER JOIN Wahlkreis wk ON wk.wkid=d.wkid
	ORDER BY c.Lastname, c.Firstname
);

CREATE OR REPLACE VIEW Results_View_WahlkreisOverview_FirstVoteWinners(year, title, lastname, firstname, p_name, p_shorthand, p_colourcode, p_website, fsid, fs_name, wkid, wk_name) AS (
	SELECT wkwfv.year, c.title, c.lastname, c.firstname, p.name as p_name, p.shorthand as p_shorthand, p.colourcode as p_colourcode, p.website as p_website, 
	       fs.fsid, fs.name as fs_name, wk.wkid, wk.name as wk_name
	FROM Results_WahlkreisWinnersFirstVotes wkwfv
	JOIN Wahlkreis wk ON wk.wkid = wkwfv.wkid
	JOIN Candidates c ON c.idno = wkwfv.idno
	JOIN Federalstate fs ON fs.fsid = wk.fsid
	LEFT OUTER JOIN Party p on p.pid = wkwfv.pid
);

CREATE OR REPLACE VIEW Results_View_WahlkreisOverview_SecondVoteDistribution(year,wkid, wk_name, fsid, fs_name, p_name, p_shorthand, p_colourcode, p_website, votesabs, votesrel)  AS (
	SELECT ll.year,wk.wkid, wk.name as wk_name, fs.fsid, fs.name as fs_name, p.name as p_name, p.shorthand as p_shorthand, p.colourcode as p_colourcode, p.website as p_website, 
	       azwwk.votes as votesabs, (azwwk.votes*1.00/(select sum(votes) from AccumulatedZweitstimmenWK azwwk2 where azwwk.wkid=azwwk2.wkid)) as votesrel
	FROM AccumulatedZweitstimmenWK azwwk
	JOIN Wahlkreis wk on azwwk.wkid = wk.wkid
	JOIN Federalstate fs ON fs.fsid = wk.fsid
	JOIN Landesliste ll ON azwwk.llid = ll.llid
	JOIN Party p ON p.pid = ll.pid
);


Select * from Results_View_WahlkreisOverview_SecondVoteDistribution
where year = 2013 and votesrel >= 0.5

DROP VIEW Results_View_WahlkreisOverview_DKWinners