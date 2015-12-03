CREATE OR REPLACE VIEW Results_View_WahlkreisOverview_FirstVoteWinners_SLOW(title, lastname, firstname, p_name, p_shorthand, p_colourcode, p_website, fsid, fs_name, wkid, wk_name) AS (
	WITH CandidacyWithVotes_SLOW (wkid, votes, idno, supportedby) AS
	(
		SELECT  c.wkid, COUNT(*) as votes, c.idno, c.supportedby as pid
		FROM Candidacy c
		JOIN Stimmzettel sz ON c.cid = sz.erststimme
		GROUP BY c.wkid, c.idno, c.supportedby
	),
	Results_RankedCandidatesFirstVotes_Current_SLOW(wkid, rank, idno, pid, votes) AS (
		SELECT  c.wkid, 
			rank() OVER (PARTITION BY c.wkid ORDER BY c.votes desc) as rank,
			c.idno, c.supportedby as pid, c.votes
		FROM CandidacyWithVotes_SLOW c
		JOIN Wahlkreis wk ON c.wkid = wk.wkid
		WHERE wk.year= (select year from electionyear where iscurrent=true)  
	),
	Results_WahlkreisWinnersFirstVotes_Current_SLOW (wkid, idno, pid, votes) AS (
		WITH RankedCandidatesFirstVotes AS (
			SELECT * FROM Results_RankedCandidatesFirstVotes_Current_SLOW
		)
		
		SELECT wkid, idno, pid, votes
		FROM RankedCandidatesFirstVotes 
		WHERE rank = 1
	)
	
	
	SELECT c.title, c.lastname, c.firstname, p.name as p_name, p.shorthand as p_shorthand, p.colourcode as p_colourcode, p.website as p_website,
	   fs.fsid, fs.name as fs_name, wk.wkid, wk.name as wk_name
	FROM Results_WahlkreisWinnersFirstVotes_Current_SLOW wkwsv
	JOIN Wahlkreis wk ON wk.wkid = wkwsv.wkid
	JOIN Candidates c ON c.idno = wkwsv.idno
	JOIN Federalstate fs ON fs.fsid = wk.fsid
	LEFT OUTER JOIN Party p on p.pid = wkwsv.pid
);

CREATE OR REPLACE VIEW Results_View_WahlkreisOverview_SecondVoteDistribution_SLOW(wkid, wk_name, fsid, fs_name, p_name, p_shorthand, p_colourcode, p_website, votesabs, votesrel)  AS (
	WITH AccumulatedZweitstimmenWK_SLOW (wkid, llid, votes) AS
	(
		SELECT  wk.wkid, ll.llid, COUNT(*) as votes
		FROM Landesliste ll
		JOIN Stimmzettel sz ON ll.llid = sz.zweitstimme
		JOIN Direktwahlbezirk dwb ON sz.dwbid = dwb.dwbid
		JOIN Wahlkreis wk ON dwb.wkid = wk.wkid
		GROUP BY wk.wkid, ll.llid

	)
	
	SELECT wk.wkid, wk.name as wk_name, fs.fsid, fs.name as fs_name, p.name as p_name, p.shorthand as p_shorthand, p.colourcode as p_colourcode, p.website as p_website,
	   azwwk.votes as votesabs, (azwwk.votes*1.00/(select sum(votes) from AccumulatedZweitstimmenWK azwwk2 where azwwk.wkid=azwwk2.wkid)) as votesrel
	FROM AccumulatedZweitstimmenWK_SLOW azwwk
	JOIN Wahlkreis wk on azwwk.wkid = wk.wkid
	JOIN Federalstate fs ON fs.fsid = wk.fsid
	JOIN Landesliste ll ON azwwk.llid = ll.llid
	JOIN Party p ON p.pid = ll.pid
);
