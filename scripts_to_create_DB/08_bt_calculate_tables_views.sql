
--AggregatedZweitstimmenForLL
CREATE OR REPLACE VIEW Results_AggregatedZweitstimmenForLL_Current(year, fsid, llid, votes) AS (
	SELECT  (select year from electionyear where iscurrent=true) as year, ll.fsid, azwfs.llid, azwfs.votes
	FROM AccumulatedZweitstimmenFS azwfs
	JOIN Landesliste ll ON azwfs.llid = ll.llid
	WHERE ll.year = (select year from electionyear where iscurrent=true)
);

CREATE TABLE IF NOT EXISTS Results_AggregatedZweitstimmenForLL_Old (
	year INT NOT NULL REFERENCES ElectionYear(year) ON DELETE CASCADE,
	fsid INT NOT NULL REFERENCES FederalState(fsid) ON DELETE CASCADE,
	llid INT NOT NULL REFERENCES LandesListe(llid) ON DELETE CASCADE,
	votes INT NOT NULL DEFAULT 0
);

CREATE OR REPLACE VIEW Results_AggregatedZweitstimmenForLL (year, fsid, llid, votes) AS (
	SELECT *
	FROM Results_AggregatedZweitstimmenForLL_Old
	UNION ALL
	SELECT *
	FROM Results_AggregatedZweitstimmenForLL_Current
);

--RankedCandidatesFirstVotes
CREATE OR REPLACE VIEW Results_RankedCandidatesFirstVotes_Current(year, wkid, rank, idno, pid, votes) AS (
	SELECT  (select year from electionyear where iscurrent=true) as year, c.wkid, 
		rank() OVER (PARTITION BY c.wkid ORDER BY c.votes desc) as rank,
		c.idno, c.supportedby as pid, c.votes
	FROM Candidacy c
	JOIN Wahlkreis wk ON c.wkid = wk.wkid
	WHERE wk.year= (select year from electionyear where iscurrent=true)  
);

CREATE TABLE IF NOT EXISTS Results_RankedCandidatesFirstVotes_Old (
	year INT NOT NULL REFERENCES ElectionYear(year) ON DELETE CASCADE,
	wkid INT REFERENCES Wahlkreis(wkid),
	rank INT NOT NULL DEFAULT 0,
	idno VARCHAR(32) NOT NULL REFERENCES Citizen(idno),
	pid INT NOT NULL REFERENCES Party(pid) ON DELETE CASCADE,
	votes INT NOT NULL DEFAULT 0	
);

CREATE OR REPLACE VIEW Results_RankedCandidatesFirstVotes (year, wkid, rank, idno, pid, votes) AS (
	SELECT *
	FROM Results_RankedCandidatesFirstVotes_Old
	UNION ALL
	SELECT *
	FROM Results_RankedCandidatesFirstVotes_Current
);

--WahlkreisWinnersFirstVotes
CREATE OR REPLACE VIEW Results_WahlkreisWinnersFirstVotes_Current (year, wkid, idno, pid) AS (
    SELECT (select year from electionyear where iscurrent=true) as year, wkid, idno, pid
    FROM Results_RankedCandidatesFirstVotes_Current 
    WHERE rank = 1
);

CREATE TABLE IF NOT EXISTS Results_WahlkreisWinnersFirstVotes_Old (
	year INT NOT NULL REFERENCES ElectionYear(year) ON DELETE CASCADE,
	wkid INT REFERENCES Wahlkreis(wkid),
	idno VARCHAR(32) NOT NULL REFERENCES Citizen(idno),
	pid INT NOT NULL REFERENCES Party(pid) ON DELETE CASCADE
);

CREATE OR REPLACE VIEW Results_WahlkreisWinnersFirstVotes (year, wkid, idno, pid) AS (
	SELECT *
	FROM Results_WahlkreisWinnersFirstVotes_Old
	UNION ALL
	SELECT *
	FROM Results_WahlkreisWinnersFirstVotes_Current
);

--AggregatedZweitstimmenForParty
CREATE OR REPLACE VIEW Results_AggregatedZweitstimmenForParty_Current (year, pid, votes) AS (
    SELECT (select year from electionyear where iscurrent=true) as year, ll.pid, SUM(azwfll.votes)
    FROM Results_AggregatedZweitstimmenForLL_Current azwfll
    JOIN LandesListe ll ON azwfll.llid = ll.llid
    GROUP BY ll.pid
);

CREATE TABLE IF NOT EXISTS Results_AggregatedZweitstimmenForParty_Old (
	year INT NOT NULL REFERENCES ElectionYear(year) ON DELETE CASCADE,
	pid INT NOT NULL REFERENCES Party(pid) ON DELETE CASCADE,
	votes INT NOT NULL DEFAULT 0	
);

CREATE OR REPLACE VIEW Results_AggregatedZweitstimmenForParty (year, pid, votes) AS (
	SELECT *
	FROM Results_AggregatedZweitstimmenForParty_Old
	UNION ALL
	SELECT *
	FROM Results_AggregatedZweitstimmenForParty_Current
);

--PartiesQualified
CREATE OR REPLACE VIEW Results_PartiesQualified_Current(year, pid, votes) AS (
    SELECT (select year from electionyear where iscurrent=true) as year, a1.pid, a1.votes
    FROM Party p NATURAL JOIN Results_AggregatedZweitstimmenForParty_Current a1
    WHERE a1.votes > 0
       AND (p.isminority
	    OR 2 < (SELECT COUNT(*) FROM Results_WahlkreisWinnersFirstVotes_Current WHERE pid = a1.pid)
	    OR a1.votes >= 0.05 * (SELECT SUM(votes) from Results_AggregatedZweitstimmenForParty_Current))
	    
);

CREATE TABLE IF NOT EXISTS Results_PartiesQualified_Old (
	year INT NOT NULL REFERENCES ElectionYear(year) ON DELETE CASCADE,
	pid INT NOT NULL REFERENCES Party(pid) ON DELETE CASCADE,
	votes INT NOT NULL DEFAULT 0	
);

CREATE OR REPLACE VIEW Results_PartiesQualified (year, pid, votes) AS (
	SELECT *
	FROM Results_PartiesQualified_Old
	UNION ALL
	SELECT *
	FROM Results_PartiesQualified_Current
);

--AggregatedZweitstimmenForLLQualified
CREATE OR REPLACE VIEW Results_AggregatedZweitstimmenForLLQualified_Current(year, fsid, pid, llid, votes) AS (
	SELECT (select year from electionyear where iscurrent=true) as year, azwfs.fsid, ll.pid, azwfs.llid, azwfs.votes
	FROM Results_AggregatedZweitstimmenForLL_Current azwfs
	JOIN Landesliste ll ON azwfs.llid = ll.llid
	WHERE ll.pid in (select pid from Results_PartiesQualified_Current)
);

CREATE TABLE IF NOT EXISTS Results_AggregatedZweitstimmenForLLQualified_Old (
	year INT NOT NULL REFERENCES ElectionYear(year) ON DELETE CASCADE,
	fsid INT NOT NULL REFERENCES FederalState(fsid) ON DELETE CASCADE,
	pid INT NOT NULL REFERENCES Party(pid) ON DELETE CASCADE,
	llid INT NOT NULL REFERENCES LandesListe(llid) ON DELETE CASCADE,
	votes INT NOT NULL DEFAULT 0	
);

CREATE OR REPLACE VIEW Results_AggregatedZweitstimmenForLLQualified (year, fsid, pid, llid, votes) AS (
	SELECT *
	FROM Results_AggregatedZweitstimmenForLLQualified_Old
	UNION ALL
	SELECT *
	FROM Results_AggregatedZweitstimmenForLLQualified_Current
);

--WahlkreisesiegePerPartyPerFS
CREATE OR REPLACE VIEW Results_WahlkreisesiegePerPartyPerFS_Current (year, pid, fsid, seats) AS (
	SELECT (select year from electionyear where iscurrent=true) as year, pid, wk.fsid, count(*)
	FROM Results_WahlkreisWinnersFirstVotes_Current wkwfv
	JOIN Wahlkreis wk ON wkwfv.wkid = wk.wkid
	JOIN Federalstate fs ON wk.fsid = fs.fsid
	GROUP BY pid, wk.fsid
);

CREATE TABLE IF NOT EXISTS Results_WahlkreisesiegePerPartyPerFS_Old (
	year INT NOT NULL REFERENCES ElectionYear(year) ON DELETE CASCADE,
	pid INT NOT NULL REFERENCES Party(pid) ON DELETE CASCADE,
	fsid INT NOT NULL REFERENCES FederalState(fsid) ON DELETE CASCADE,
	seats BIGINT NOT NULL DEFAULT 0	
);

CREATE OR REPLACE VIEW Results_WahlkreisesiegePerPartyPerFS (year, pid, fsid, seats) AS (
	SELECT *
	FROM Results_WahlkreisesiegePerPartyPerFS_Old
	UNION ALL
	SELECT *
	FROM Results_WahlkreisesiegePerPartyPerFS_Current
);

--RankedSeatsPerFederalState
CREATE OR REPLACE VIEW Results_RankedSeatsPerFederalState_Current(year, fsid, seatnumber) as (
	SELECT (select year from electionyear where iscurrent=true) as year, fs.fsid, rank() OVER (ORDER BY fs.citizencount/f.f desc) as seatnumber
	FROM FederalState fs, Factors f
	WHERE f.f < (598 * ((fs.citizencount)*1.00/(SELECT sum(citizencount) FROM FederalState)*1.00) +1)
);

CREATE TABLE IF NOT EXISTS Results_RankedSeatsPerFederalState_Old (
	year INT NOT NULL REFERENCES ElectionYear(year) ON DELETE CASCADE,
	fsid INT NOT NULL REFERENCES FederalState(fsid) ON DELETE CASCADE,
	seatnumber INT NOT NULL DEFAULT 0	
);

CREATE OR REPLACE VIEW Results_RankedSeatsPerFederalState (year, fsid, seatnumber) AS (
	SELECT *
	FROM Results_RankedSeatsPerFederalState_Old
	UNION ALL
	SELECT *
	FROM Results_RankedSeatsPerFederalState_Current
);

-- SeatsPerFederalState
CREATE OR REPLACE VIEW Results_SeatsPerFederalState_Current(year, fsid, seats) AS (
	SELECT (select year from electionyear where iscurrent=true) as year, fsid, COUNT(seatnumber) AS seat
	FROM Results_RankedSeatsPerFederalState_Current rspfs
	WHERE rspfs.seatnumber <= 598
	GROUP BY FSID
);

CREATE TABLE IF NOT EXISTS Results_SeatsPerFederalState_Old (
	year INT NOT NULL REFERENCES ElectionYear(year) ON DELETE CASCADE,
	fsid INT NOT NULL REFERENCES FederalState(fsid) ON DELETE CASCADE,
	seats BIGINT NOT NULL DEFAULT 0		
);

CREATE OR REPLACE VIEW Results_SeatsPerFederalState (year, fsid, seats) AS (
	SELECT *
	FROM Results_SeatsPerFederalState_Old
	UNION ALL
	SELECT *
	FROM Results_SeatsPerFederalState_Current
);

---RankedSeatsPerLandesliste
CREATE OR REPLACE VIEW Results_RankedSeatsPerLandesliste_Current (year, llid, seatnumberInFS, seatnumberInParty, seatnumberLL) AS (
	SELECT (select year from electionyear where iscurrent=true) as year, azllq.llid, 
		rank()  OVER (Partition by azllq.fsid Order by azllq.votes/f.f desc) as seatnumberInFS,		--rank within Federalstate	
		rank()  OVER (Partition by azllq.pid Order by azllq.votes/f.f desc) as seatnumberInParty,		--rank within Party
		rank()  OVER (Partition by azllq.pid, azllq.llid Order by azllq.votes/f.f desc) as seatnumberInLL	--rank within Landesliste
		
	FROM Results_AggregatedZweitstimmenForLLQualified_Current azllq, Factors f 
	WHERE f.f < (Greatest(
			   ((select seats * (900.0/599.0) from Results_SeatsPerFederalState_Current spfs where spfs.fsid = azllq.fsid) -- (800.0/599.0) factor if seats in Bundestag reach max.
			    *((azllq.votes)*1.00
			      /(SELECT sum(votes) FROM Results_AggregatedZweitstimmenForLLQualified_Current agzwfll where agzwfll.fsid = azllq.fsid)*1.00
			      )
			     +1 --todoGB: check if falid now
			    ), 	
			    (select seats from Results_WahlkreisesiegePerPartyPerFS_Current wkspppfs where wkspppfs.fsid =azllq.fsid and wkspppfs.pid = azllq.pid)
			   )
			 ) 
);     

CREATE TABLE IF NOT EXISTS Results_RankedSeatsPerLandesliste_Old (
	year INT NOT NULL REFERENCES ElectionYear(year) ON DELETE CASCADE,
	llid INT NOT NULL REFERENCES LandesListe(llid) ON DELETE CASCADE,
	seatnumberInFS INT NOT NULL DEFAULT 0,
	seatnumberInParty INT NOT NULL DEFAULT 0,
	seatnumberLL INT NOT NULL DEFAULT 0	
);

CREATE OR REPLACE VIEW Results_RankedSeatsPerLandesliste (year, llid, seatnumberInFS, seatnumberInParty, seatnumberLL) AS (
	SELECT *
	FROM Results_RankedSeatsPerLandesliste_Old
	UNION ALL
	SELECT *
	FROM Results_RankedSeatsPerLandesliste_Current
);

--SeatsPerLandelisteByZweitstimme
CREATE OR REPLACE VIEW Results_SeatsPerLandelisteByZweitstimme_Current(year, llid, seats) AS (
	SELECT (select year from electionyear where iscurrent=true) as year, rspll.llid, Count(*) as numberOfSeats 
	FROM Results_RankedSeatsPerLandesliste_Current rspll
	JOIN LandesListe ll ON ll.llid = rspll.llid
	JOIN Results_SeatsPerFederalState_Current spfs ON spfs.fsid = ll.fsid 
	WHERE seatnumberInFS <= spfs.seats
	GROUP BY rspll.llid   
);

CREATE TABLE IF NOT EXISTS Results_SeatsPerLandelisteByZweitstimme_Old (
	year INT NOT NULL REFERENCES ElectionYear(year) ON DELETE CASCADE,
	llid INT NOT NULL REFERENCES LandesListe(llid) ON DELETE CASCADE,
	seats BIGINT NOT NULL DEFAULT 0	
);

CREATE OR REPLACE VIEW Results_SeatsPerLandelisteByZweitstimme (year, llid, seats)AS (
	SELECT *
	FROM Results_SeatsPerLandelisteByZweitstimme_Old
	UNION ALL
	SELECT *
	FROM Results_SeatsPerLandelisteByZweitstimme_Current
);

--Results_FVandSVSeatsPerPartyPerFederalstate_Current
CREATE OR REPLACE VIEW Results_FVandSVSeatsPerPartyPerFederalstate_Current (year, pid, fsid, fvseats, svseats) AS (
	SELECT (select year from electionyear where iscurrent=true) as year, ll.pid, ll.fsid as fsid, coalesce(wkspppfs.seats,0) as fvseats, coalesce(spllbzs.seats,0) as svseats
	FROM  Results_WahlkreisesiegePerPartyPerFS_Current wkspppfs
	FULL OUTER JOIN Landesliste ll on ll.pid= wkspppfs.pid and ll.fsid=wkspppfs.fsid
	JOIN Results_SeatsPerLandelisteByZweitstimme_Current spllbzs on ll.llid = spllbzs.llid
);

CREATE TABLE IF NOT EXISTS Results_FVandSVSeatsPerPartyPerFederalstate_Old (
	year INT NOT NULL REFERENCES ElectionYear(year) ON DELETE CASCADE,
	pid INT NOT NULL REFERENCES Party(pid) ON DELETE CASCADE,
	fsid INT NOT NULL REFERENCES FederalState(fsid) ON DELETE CASCADE,
	fvseats BIGINT NOT NULL DEFAULT 0,
	svseats BIGINT NOT NULL DEFAULT 0	
);

CREATE OR REPLACE VIEW Results_FVandSVSeatsPerPartyPerFederalstate(year, pid, fsid, fvseats, svseats) AS (
	SELECT *
	FROM Results_FVandSVSeatsPerPartyPerFederalstate_Old
	UNION ALL
	SELECT *
	FROM Results_FVandSVSeatsPerPartyPerFederalstate_Current
);



--MinimumSeatsPerPartyPerFederalstate
CREATE OR REPLACE VIEW Results_MinimumSeatsPerPartyPerFederalstate_Current (year, pid, fsid, minSeats) AS (
	SELECT (select year from electionyear where iscurrent=true) as year, dkllspppfs.pid, dkllspppfs.fsid as fsid, GREATEST(coalesce(dkllspppfs.fvseats,0), coalesce(dkllspppfs.svseats,0)) as minSeats
	FROM  Results_FVandSVSeatsPerPartyPerFederalstate_Current dkllspppfs
);

CREATE TABLE IF NOT EXISTS Results_MinimumSeatsPerPartyPerFederalstate_Old (
	year INT NOT NULL REFERENCES ElectionYear(year) ON DELETE CASCADE,
	pid INT NOT NULL REFERENCES Party(pid) ON DELETE CASCADE,
	fsid INT NOT NULL REFERENCES FederalState(fsid) ON DELETE CASCADE,
	minSeats INT NOT NULL DEFAULT 0	
);

CREATE OR REPLACE VIEW Results_MinimumSeatsPerPartyPerFederalstate (year, pid, fsid, minSeats) AS (
	SELECT *
	FROM Results_MinimumSeatsPerPartyPerFederalstate_Old
	UNION ALL
	SELECT *
	FROM Results_MinimumSeatsPerPartyPerFederalstate_Current
);



--MinimumSeatsPerParty
CREATE OR REPLACE VIEW Results_MinimumSeatsPerParty_Current (year, pid,minSeats) AS (
	SELECT (select year from electionyear where iscurrent=true) as year, pid, sum(minSeats) as minSeats
	FROM Results_MinimumSeatsPerPartyPerFederalstate_Current
	GROUP BY pid	
);

CREATE TABLE IF NOT EXISTS Results_MinimumSeatsPerParty_Old (
	year INT NOT NULL REFERENCES ElectionYear(year) ON DELETE CASCADE,
	pid INT NOT NULL REFERENCES Party(pid) ON DELETE CASCADE,
	minSeats INT NOT NULL DEFAULT 0	
);

CREATE OR REPLACE VIEW Results_MinimumSeatsPerParty(year, pid,minSeats) AS (
	SELECT *
	FROM Results_MinimumSeatsPerParty_Old
	UNION ALL
	SELECT *
	FROM Results_MinimumSeatsPerParty_Current
);



--RankedSeatsPerParty
CREATE OR REPLACE VIEW Results_RankedSeatsPerParty_Current(year, pid, seatnumberTotal, seatnumberParty) AS (
	WITH RECURSIVE Factors(pid, f) AS (
	    (SELECT pid, 0.5 from Results_PartiesQualified_Current)
	    UNION ALL
	    (SELECT f.pid, f + 1
	     FROM Factors f
	     WHERE f < (900 * (SELECT votes FROM Results_PartiesQualified_Current p where p.pid = f.pid)*1.00 / (SELECT sum(votes) FROM Results_PartiesQualified_Current)*1.00 +1) --900 = max. seats in Bundestag
	    )
	)

	SELECT (select year from electionyear where iscurrent=true) as year, p.pid, rank()  OVER (Order by p.votes/f.f desc) as seatnumberTotal,	--rank overall seats in Bundestag
	rank()  OVER (Partition by p.pid Order by p.votes/f.f desc) as seatnumberParty	--rank within the Party
	FROM Results_PartiesQualified_Current p
	JOIN Factors f ON p.pid = f.pid
);

CREATE TABLE IF NOT EXISTS Results_RankedSeatsPerParty_Old (
	year INT NOT NULL REFERENCES ElectionYear(year) ON DELETE CASCADE,
	pid INT NOT NULL REFERENCES Party(pid) ON DELETE CASCADE,
	seatnumberTotal INT NOT NULL DEFAULT 0,
	seatnumberParty INT NOT NULL DEFAULT 0
);

CREATE OR REPLACE VIEW Results_RankedSeatsPerParty(year, pid, seatnumberTotal, seatnumberParty)  AS (
	SELECT *
	FROM Results_RankedSeatsPerParty_Old
	UNION ALL
	SELECT *
	FROM Results_RankedSeatsPerParty_Current
);

--TotalNumberOfSeats
CREATE OR REPLACE VIEW Results_TotalNumberOfSeats_Current (year, seats) AS (
	SELECT (select year from electionyear where iscurrent=true) as year, max(seatnumberTotal) as seats
	from Results_RankedSeatsPerParty_Current rspp
	NATURAL JOIN Results_MinimumSeatsPerParty_Current mspp
	where rspp.seatnumberParty = mspp.minSeats  	
);

CREATE TABLE IF NOT EXISTS Results_TotalNumberOfSeats_Old (
	year INT NOT NULL REFERENCES ElectionYear(year) ON DELETE CASCADE,
	seats INT NOT NULL DEFAULT 0
);

CREATE OR REPLACE VIEW Results_TotalNumberOfSeats (year, seats)  AS (
	SELECT *
	FROM Results_TotalNumberOfSeats_Old
	UNION ALL
	SELECT *
	FROM Results_TotalNumberOfSeats_Current
);

--TotalNumberOfSeatsPerParty
CREATE OR REPLACE VIEW Results_TotalNumberOfSeatsPerParty_Current(year, pid,seats) AS (	
	select (select year from electionyear where iscurrent=true) as year, pid, max(seatnumberParty)
	from Results_RankedSeatsPerParty_Current
	where seatnumberTotal <= (SELECT seats from Results_TotalNumberOfSeats_Current)	
	group by pid	
);

CREATE TABLE IF NOT EXISTS Results_TotalNumberOfSeatsPerParty_Old (
	year INT NOT NULL REFERENCES ElectionYear(year) ON DELETE CASCADE,
	pid INT NOT NULL REFERENCES Party(pid) ON DELETE CASCADE,
	seats INT NOT NULL DEFAULT 0
);

CREATE OR REPLACE VIEW Results_TotalNumberOfSeatsPerParty (year, pid,seats)   AS (
	SELECT *
	FROM Results_TotalNumberOfSeatsPerParty_Old
	UNION ALL
	SELECT *
	FROM Results_TotalNumberOfSeatsPerParty_Current
);

--RemainingRankedSeatsPerLandesliste
CREATE OR REPLACE VIEW Results_RemainingRankedSeatsPerLandesliste_Current (year, llid, seatnumberInParty) AS (
	SELECT (select year from electionyear where iscurrent=true) as year, rspll.llid,
	rank()  OVER (Partition by ll.pid  Order by rspll.seatnumberInParty asc) as seatnumberInParty		
	FROM Results_RankedSeatsPerLandesliste_Current rspll
	JOIN Landesliste ll ON ll.llid=rspll.llid
	Left Outer JOIN Results_WahlkreisesiegePerPartyPerFS_Current wkspll ON wkspll.pid=ll.pid and wkspll.fsid=ll.fsid
	where rspll.seatnumberLL > coalesce(wkspll.seats,0)							
);

CREATE TABLE IF NOT EXISTS Results_RemainingRankedSeatsPerLandesliste_Old (
	year INT NOT NULL REFERENCES ElectionYear(year) ON DELETE CASCADE,
	llid INT NOT NULL REFERENCES LandesListe(llid) ON DELETE CASCADE,
	seatnumberInParty INT NOT NULL DEFAULT 0
);

CREATE OR REPLACE VIEW Results_RemainingRankedSeatsPerLandesliste (year, llid, seatnumberInParty)  AS (
	SELECT *
	FROM Results_RemainingRankedSeatsPerLandesliste_Old
	UNION ALL
	SELECT *
	FROM Results_RemainingRankedSeatsPerLandesliste_Current
);

---NumberOfAdditionalSeatsPerParty_
CREATE OR REPLACE VIEW Results_NumberOfAdditionalSeatsPerParty_Current (year, pid, seats) AS (
	SELECT (select year from electionyear where iscurrent=true) as year, spp.pid, Cast((spp.seats-sum(wks.seats)) as INT) as seats
	FROM Results_TotalNumberOfSeatsPerParty_Current spp
	JOIN Results_WahlkreisesiegePerPartyPerFS_Current wks ON spp.pid=wks.pid
	group by spp.pid, spp.seats
);
CREATE TABLE IF NOT EXISTS Results_NumberOfAdditionalSeatsPerParty_Old (
	year INT NOT NULL REFERENCES ElectionYear(year) ON DELETE CASCADE,
	pid INT NOT NULL REFERENCES Party(pid) ON DELETE CASCADE,
	seats BIGINT NOT NULL DEFAULT 0
);

CREATE OR REPLACE VIEW Results_NumberOfAdditionalSeatsPerParty (year, pid, seats)  AS (
	SELECT *
	FROM Results_NumberOfAdditionalSeatsPerParty_Old
	UNION ALL
	SELECT *
	FROM Results_NumberOfAdditionalSeatsPerParty_Current
);


-- AdditionalSeatsToDirektmandatePerLandeliste
CREATE OR REPLACE VIEW Results_AdditionalSeatsToDirektmandatePerLandeliste_Current (year, llid, seats) AS (
	SELECT  (select year from electionyear where iscurrent=true) as year, rrspll.llid, count(*)
	FROM Results_RemainingRankedSeatsPerLandesliste_Current rrspll
	NATURAL JOIN Landesliste ll
	NATURAL JOIN Results_NumberOfAdditionalSeatsPerParty_Current aspp
	where rrspll.seatnumberInParty <= aspp.seats
	group by  rrspll.llid
);

CREATE TABLE IF NOT EXISTS Results_AdditionalSeatsToDirektmandatePerLandeliste_Old (
	year INT NOT NULL REFERENCES ElectionYear(year) ON DELETE CASCADE,
	llid INT NOT NULL REFERENCES LandesListe(llid) ON DELETE CASCADE,
	seats BIGINT NOT NULL DEFAULT 0
);

CREATE OR REPLACE VIEW Results_AdditionalSeatsToDirektmandatePerLandeliste (year, llid, seats)  AS (
	SELECT *
	FROM Results_AdditionalSeatsToDirektmandatePerLandeliste_Old
	UNION ALL
	SELECT *
	FROM Results_AdditionalSeatsToDirektmandatePerLandeliste_Current
);

-- SeatsPerLandesliste
CREATE OR REPLACE VIEW Results_SeatsPerLandesliste_Current (year, llid, seats)  AS(
	SELECT (select year from electionyear where iscurrent=true) as year, ll.llid, (coalesce(wkspll.seats,0)+coalesce(astdkpll.seats,0)) as seats
	FROM Results_AggregatedZweitstimmenForLLQualified_Current azllq
	JOIN Landesliste ll ON azllq.llid=ll.llid
	LEFT OUTER JOIN Results_WahlkreisesiegePerPartyPerFS_Current wkspll ON ll.pid = wkspll.pid AND ll.fsid = wkspll.fsid
	LEFT OUTER JOIN Results_AdditionalSeatsToDirektmandatePerLandeliste_Current astdkpll ON ll.llid = astdkpll.llid
	WHERE (coalesce(wkspll.seats,0)+coalesce(astdkpll.seats,0)) >0
);

CREATE TABLE IF NOT EXISTS Results_SeatsPerLandesliste_Old (
	year INT NOT NULL REFERENCES ElectionYear(year) ON DELETE CASCADE,
	llid INT NOT NULL REFERENCES LandesListe(llid) ON DELETE CASCADE,
	seats BIGINT NOT NULL DEFAULT 0
);

CREATE OR REPLACE VIEW Results_SeatsPerLandesliste (year, llid, seats)  AS (
	SELECT *
	FROM Results_SeatsPerLandesliste_Old
	UNION ALL
	SELECT *
	FROM Results_SeatsPerLandesliste_Current
);

--MergedCandidates
CREATE OR REPLACE VIEW Results_MergedCandidates_Current (year, idno, fsid, pid, wkid, llpos, ctype, rank) AS (
	(SELECT (select year from electionyear where iscurrent=true) as year, wkwfv.idno, wk.fsid, wkwfv.pid, wk.wkid, 0 as llpos, 'Direktkandidat' as ctype, 0 as rank		-- 0 to come before the Landeslistenplätze (which start with 1)
	 FROM Results_WahlkreisWinnersFirstVotes_Current wkwfv
	 NATURAL JOIN Wahlkreis wk)
	UNION
	(SELECT (select year from electionyear where iscurrent=true) as year, c.idno, ll.fsid, ll.pid, NULL as wkid, llp.position as llpos, 'Listenkandidat' as ctype,llp.position as rank
	 from Results_AggregatedZweitstimmenForLLQualified_Current azllq
	 JOIN Landesliste ll ON ll.llid = azllq.llid
	 JOIN Landeslistenplatz llp ON llp.llid = ll.llid
	 JOIN Candidates c ON c.idno = llp.idno 
	 WHERE not exists (select * from Results_WahlkreisWinnersFirstVotes_Current wkwfv where wkwfv.idno = c.idno)	-- remove Landeslistenplätze which won a Direktmandat
	 )
 );

 CREATE TABLE IF NOT EXISTS Results_MergedCandidates_Old (
	year INT NOT NULL REFERENCES ElectionYear(year) ON DELETE CASCADE,
	idno VARCHAR(32) NOT NULL REFERENCES CandidatesData(idno) ON DELETE CASCADE,
	fsid INT NOT NULL REFERENCES FederalState(fsid) ON DELETE CASCADE,
	pid INT NOT NULL REFERENCES Party(pid) ON DELETE CASCADE,
	wkid INT NOT NULL REFERENCES Wahlkreis(wkid) ON DELETE CASCADE,
	llpos INT NOT NULL DEFAULT 0,
	ctype VARCHAR(255) NOT NULL,
	rank INT NOT NULL DEFAULT 0

);

CREATE OR REPLACE VIEW Results_MergedCandidates (year, idno, fsid, pid, wkid, llpos, ctype, rank)  AS (
	SELECT *
	FROM Results_MergedCandidates_Old
	UNION ALL
	SELECT *
	FROM Results_MergedCandidates_Current
);

--MergedRankedCandidates
CREATE OR REPLACE VIEW Results_MergedRankedCandidates_Current (year, idno, fsid, pid, wkid, llpos, ctype,  rank)  AS (
	SELECT (select year from electionyear where iscurrent=true) as year, mc.idno, mc.fsid,  mc.pid, mc.wkid, mc.llpos, mc.ctype,
	       rank() OVER (Partition by mc.fsid, mc.pid Order by mc.rank asc) as rank		--re-rank to match with number of seats, (all Direktmandate have rank 0 from Results_MergedCandidates_Current)
	FROM Results_MergedCandidates_Current mc	
);

 CREATE TABLE IF NOT EXISTS Results_MergedRankedCandidates_Old (
	year INT NOT NULL REFERENCES ElectionYear(year) ON DELETE CASCADE,
	idno VARCHAR(32) NOT NULL REFERENCES CandidatesData(idno) ON DELETE CASCADE,
	fsid INT NOT NULL REFERENCES FederalState(fsid) ON DELETE CASCADE,
	pid INT NOT NULL REFERENCES Party(pid) ON DELETE CASCADE,
	wkid INT NOT NULL REFERENCES Wahlkreis(wkid) ON DELETE CASCADE,
	llpos INT NOT NULL DEFAULT 0,
	ctype VARCHAR(255) NOT NULL,
	rank INT NOT NULL DEFAULT 0

);

CREATE OR REPLACE VIEW Results_MergedRankedCandidates (year, idno, fsid, pid, wkid, llpos, ctype, rank)  AS (
	SELECT *
	FROM Results_MergedRankedCandidates_Old
	UNION ALL
	SELECT *
	FROM Results_MergedRankedCandidates_Current
);

-- Delegates
CREATE OR REPLACE VIEW Results_Delegates_Current (year, idno, fsid, pid, wkid, llpos, ctype, rankInFS) AS (
	SELECT mrc.year, mrc.idno, mrc.fsid, mrc.pid, mrc.wkid, mrc.llpos, mrc.ctype, mrc.rank
	FROM Results_MergedRankedCandidates_Current mrc
	LEFT OUTER JOIN Landesliste ll ON mrc.fsid = ll.fsid AND mrc.pid=ll.pid AND mrc.year = ll.year
	JOIN Results_SeatsPerLandesliste_Current spll ON  spll.llid=ll.llid AND mrc.year = spll.year
	WHERE mrc.pid is NULL or spll.seats >= rank						--take only candidates who have ll-rank <= ll-number of seats
);

 CREATE TABLE IF NOT EXISTS Results_Delegates_Old (
	year INT NOT NULL REFERENCES ElectionYear(year) ON DELETE CASCADE,
	idno VARCHAR(32) NOT NULL REFERENCES CandidatesData(idno) ON DELETE CASCADE,
	fsid INT NOT NULL REFERENCES FederalState(fsid) ON DELETE CASCADE,
	pid INT NOT NULL REFERENCES Party(pid) ON DELETE CASCADE,
	wkid INT NOT NULL REFERENCES Wahlkreis(wkid) ON DELETE CASCADE,
	llpos INT NOT NULL DEFAULT 0,
	ctype VARCHAR(255) NOT NULL,
	rankInFS INT NOT NULL DEFAULT 0

);

CREATE OR REPLACE VIEW Results_Delegates (year, idno, fsid, pid, wkid, llpos, ctype, rankInFS)  AS (
	SELECT *
	FROM Results_Delegates_Old
	UNION ALL
	SELECT *
	FROM Results_Delegates_Current
);

------------------------------ TESTING ------------------------------
---------- STEP 1: Seats per Federalstate ----------
----Ranked Seats
-- SELECT fs.name, rspfs.seatnumber
-- FROM Results_RankedSeatsPerFederalState_Current rspfs
-- JOIN FederalState fs ON rspfs.fsid = fs.fsid
-- ORDER BY rspfs.seatnumber

----Seats per fs
-- SELECT fs.name, spfs.seats
-- FROM Results_SeatsPerFederalState_Current spfs
-- JOIN FederalState fs ON spfs.fsid = fs.fsid
-- ORDER BY fs.fsid

---------------- STEP 2: Seats per Landesliste for each Federalstate ----------------
----Ranked seats
-- SELECT rspll.seatnumberInFS, fs.name, p.name
-- FROM Results_RankedSeatsPerLandesliste_Current rspll
-- JOIN Landesliste ll ON ll.llid = rspll.llid
-- JOIN Federalstate fs ON fs.fsid = ll.fsid
-- JOIN Party p on ll.pid = p.pid
-- WHERE fs.name='Thüringen'

----Number of Seats per Landesliste
-- SELECT spllpzw.seats, fs.name, p.name
-- FROM Results_MinimumSeatsPerParty_Current spllpzw
-- JOIN Landesliste ll ON ll.llid = spllpzw.llid
-- JOIN Federalstate fs ON fs.fsid = ll.fsid
-- JOIN Party p on ll.pid = p.pid
-- WHERE fs.name='Thüringen'
-- ORDER BY spllpzw.seats desc

---------------- STEP ZWISCHENERGEBNIS: minimum Number of Seats per Party ----------------
---Minimum seats per Party per Federalstate
-- SELECT mspppf.minSeats, fs.name, p.name
-- FROM Results_MinimumSeatsPerPartyPerFederalstate_Current mspppf
-- JOIN Federalstate fs ON mspppf.fsid = fs.fsid
-- JOIN Party p on mspppf.pid = p.pid
-- WHERE fs.name='Thüringen'

----Minimum seats per Party in Bundestag
-- SELECT mspp.minSeats, p.name
-- FROM Results_MinimumSeatsPerParty_Current mspp
-- JOIN Party p ON mspp.pid = p.pid


---------------- STEP 3: final number of Seats per Party ----------------

----ranked Seats in Bundestag, total and in Party
-- SELECT p.name, rspp.seatnumberTotal, rspp.seatnumberParty
-- FROM Results_RankedSeatsPerParty_Current rspp
-- JOIN Party p ON rspp.pid = p.pid
-- ORDER BY rspp.seatnumberTotal

----total number of seats in Bundestag for Party
-- SELECT p.name, tnospp.seats
-- FROM Results_TotalNumberOfSeatsPerParty_Current tnospp
-- JOIN Party p ON tnospp.pid = p.pid 
-- ORDER BY tnospp.seats desc


---------------- STEP 4: final number of Seats per Landesliste ----------------
----ranks seats fro each Landesliste within Party and LL
-- SELECT fs.name, p.name, rspll.seatnumberInParty, rspll.seatnumberLL
-- FROM Results_RankedSeatsPerLandesliste_Current rspll
-- JOIN Landesliste ll ON ll.llid = rspll.llid
-- JOIN Federalstate fs ON ll.fsid = fs.fsid
-- JOIN Party p on ll.pid = p.pid
-- WHERE fs.name='Thüringen' AND p.name='CDU'

----total number of seats per Landesliste
-- SELECT fs.name, p.name, spll.seats
-- FROM Results_SeatsPerLandesliste_Current spll
-- JOIN Landesliste ll ON ll.llid = spll.llid
-- JOIN Federalstate fs ON ll.fsid = fs.fsid
-- JOIN Party p on ll.pid = p.pid
-- WHERE p.name='CDU'

---------------- STEP 5: List of Results_Delegates_Current for Bundestag ----------------
-- SELECT  c.Lastname, c.Firstname, p.name, fs.name, d.ctype, d.llpos as Listenplatz 
-- FROM Results_Delegates_Current d 
-- JOIN Candidates c ON d.idno = c.idno
-- JOIN Federalstate fs ON fs.fsid = d.fsid
-- JOIN Party p ON p.pid=d.pid
-- WHERE p.name='CDU'
-- ORDER BY c.Lastname, c.Firstname

-- SELECT  Count(*)
-- FROM Results_Delegates_Current d 


--Überhangsmandate
-- select * from Results_FVandSVSeatsPerPartyPerFederalstate_Current
-- where (fvseats-svseats) > 0


-- select * from RankedWahlkreisCandidatesFirstVotes


