CREATE OR REPLACE VIEW Results_View_Seatdistribution_Bundestag(year, seats, name, shorthand, colourcode, website, isminority) AS (
    SELECT tnospp.year, tnospp.seats, p.name, p.shorthand, p.colourcode, p.website, p.isminority
    FROM Results_TotalNumberOfSeatsPerParty tnospp
    JOIN Party p on p.pid = tnospp.pid
    ORDER BY tnospp.seats DESC
);

CREATE OR REPLACE VIEW Results_View_Delegates(year, title, lastname, firstname, p_name, p_shorthand, p_colourcode, p_website, fsid, fs_name, wkid, wk_name, wknr, ctype, listenplatz) AS (
    SELECT  d.year, c.title, c.lastname, c.firstname, p.name as p_name, p.shorthand as p_shorthand, p.colourcode as p_colourcode, p.website as p_website,
        fs.fsid, fs.name as fs_name, wk.wkid, wk.name as wk_name, wk.wknr, d.ctype, d.llpos as listenplatz
    FROM Results_Delegates d
    JOIN Candidates c ON d.idno = c.idno
    JOIN Federalstate fs ON fs.fsid = d.fsid
    JOIN Party p ON p.pid=d.pid
    LEFT OUTER JOIN Wahlkreis wk ON wk.wkid=d.wkid
    ORDER BY c.Lastname, c.Firstname
);

CREATE OR REPLACE VIEW Results_View_WahlkreisOverview_FirstVoteWinners(year, title, lastname, firstname, p_name, p_shorthand, p_colourcode, p_website, fsid, fs_name, wkid, wk_name, wknr) AS (
    SELECT wkwsv.year, c.title, c.lastname, c.firstname, p.name as p_name, p.shorthand as p_shorthand, p.colourcode as p_colourcode, p.website as p_website,
           fs.fsid, fs.name as fs_name, wk.wkid, wk.name as wk_name, wk.wknr
    FROM Results_WahlkreisWinnersFirstVotes wkwsv
    JOIN Wahlkreis wk ON wk.wkid = wkwsv.wkid
    JOIN Candidates c ON c.idno = wkwsv.idno
    JOIN Federalstate fs ON fs.fsid = wk.fsid
    LEFT OUTER JOIN Party p on p.pid = wkwsv.pid
);

CREATE OR REPLACE VIEW Results_View_WahlkreisOverview_SecondVoteDistribution(year,wkid, wk_name, wknr, fsid, fs_name, p_name, p_shorthand, p_colourcode, p_website, votesabs, votesrel)  AS (
    SELECT ll.year,wk.wkid, wk.name as wk_name, wk.wknr, fs.fsid, fs.name as fs_name, p.name as p_name, p.shorthand as p_shorthand, p.colourcode as p_colourcode, p.website as p_website,
           azwwk.votes as votesabs, (azwwk.votes*1.00/(select sum(votes) from AccumulatedZweitstimmenWK azwwk2 where azwwk.wkid=azwwk2.wkid)) as votesrel
    FROM AccumulatedZweitstimmenWK azwwk
    JOIN Wahlkreis wk on azwwk.wkid = wk.wkid
    JOIN Federalstate fs ON fs.fsid = wk.fsid
    JOIN Landesliste ll ON azwwk.llid = ll.llid
    JOIN Party p ON p.pid = ll.pid
);

CREATE OR REPLACE VIEW Results_View_Results_View_WahlkreisOverview_Voterparticipation (year, wkid, wk_name, elective, voted, participationrate) AS (
	SELECT rvppwk.year, rvppwk.wkid, wk.name, rvppwk.elective, rvppwk.voted, ((rvppwk.voted*1.0)/(rvppwk.elective*1.0))*100.0 as participationrate
	FROM Results_VoterparticipationPerWK rvppwk
	JOIN Wahlkreis wk ON wk.wkid = rvppwk.wkid
);

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


CREATE OR REPLACE VIEW Results_View_Wahlkreiswinners(year, fsid, fs_name, wkid, wk_name, wknr, fv_title, fv_lastname, fv_firstname, fv_p_name, fv_p_shorthand, fv_p_colourcode, fv_p_website, sv_p_name, sv_p_shorthand, sv_p_colourcode, sv_p_website)  AS (
    WITH RankedLandeslistenPerWK (wkid, llid, rank) AS (
		SELECT acczswk.wkid, acczswk.llid, rank() OVER (PARTITION BY acczswk.wkid ORDER BY acczswk.votes desc) as rank
		FROM AccumulatedZweitstimmenWK acczswk
	),
	WahlkreisWinnersSecondVotes (wkid, llid) AS (
		SELECT wkllpwk.wkid, wkllpwk.llid
		FROM RankedLandeslistenPerWK wkllpwk
		WHERE rank = 1
	)

	SELECT  wkwfv.year, fs.fsid, fs.name as fs_name, wk.wkid, wk.name as wk_name, wk.wknr,
	c.title as fv_title, c.lastname as fv_lastname, c.firstname as fv_firstname, p.name as fv_p_name, p.shorthand as fv_p_shorthand, p.colourcode as fv_p_colourcode, p.website as fv_p_website,
	p2.name as sv_p_name, p2.shorthand as sv_p_shorthand, p2.colourcode as sv_p_colourcode, p2.website as sv_p_website
	FROM Results_WahlkreisWinnersFirstVotes wkwfv
	JOIN Wahlkreis wk ON wk.wkid = wkwfv.wkid
	JOIN Candidates c ON c.idno = wkwfv.idno
	JOIN Federalstate fs ON fs.fsid = wk.fsid
	LEFT OUTER JOIN Party p on p.pid = wkwfv.pid
	JOIN WahlkreisWinnersSecondVotes wkwsv ON wkwfv.wkid = wkwsv.wkid
	JOIN Landesliste ll ON wkwsv.llid = ll.llid
	JOIN Party p2 ON p2.pid = ll.pid
);

CREATE OR REPLACE VIEW Results_View_UeberhangsMandate(year, fsid, fs_name, p_name, p_shorthand, p_colourcode, p_website, mandates)  AS (
    SELECT fsspppfs.year, fs.fsid, fs.name as fs_name, p.name as p_name, p.shorthand as p_shorthand, p.colourcode as p_colourcode, p.website as p_website,
        (fsspppfs.fvseats-fsspppfs.svseats) as mandates
    FROM Results_FVandSVSeatsPerPartyPerFederalstate fsspppfs
    JOIN Federalstate fs ON fs.fsid = fsspppfs.fsid
    JOIN Party p ON p.pid = fsspppfs.pid
    WHERE fsspppfs.fvseats > fsspppfs.svseats
);

CREATE OR REPLACE VIEW  Results_View_NarrowWahlkreisWinsAndLosings (year, fsid, fs_name, wkid, wk_name, wknr, idno, c_title, c_firstname, c_lastname, pid, p_name, p_shorthand, rank, diffvotes) AS
(
    SELECT nwkwl.year, fs.fsid, fs.name as fs_name, wk.wkid, wk.name as wk_name, wk.wknr, c.idno, c.title as c_title, c.firstname as c_firstname, c.lastname as c_lastname,
           p.pid, p.name, p.shorthand, nwkwl.rank, nwkwl.diffvotes
    FROM Results_NarrowWahlkreisWinsAndLosings nwkwl
    JOIN Wahlkreis wk ON wk.wkid = nwkwl.wkid
    JOIN Federalstate fs ON fs.fsid = wk.fsid
    JOIN Party p ON p.pid = nwkwl.pid
    JOIN Candidates c ON c.idno = nwkwl.idno
)
