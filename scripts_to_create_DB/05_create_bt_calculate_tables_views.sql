BEGIN;
--Factors Table
CREATE TABLE IF NOT EXISTS Factors (
    f REAL PRIMARY KEY
);

CREATE OR REPLACE VIEW  OrderedElectionyears(year, rank) AS (
	SELECT ey.year, rank()  OVER (ORDER BY ey.year asc) as rank
	FROM electionyear ey
);

--AggregatedZweitstimmenForLL
CREATE OR REPLACE VIEW Results_AggregatedZweitstimmenForLL_Current(fsid, llid, votes) AS (
	SELECT ll.fsid, azwfs.llid, azwfs.votes
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
	SELECT (select year from electionyear where iscurrent=true) as year, r.*
	FROM Results_AggregatedZweitstimmenForLL_Current r
);

--RankedCandidatesFirstVotes
CREATE OR REPLACE VIEW Results_RankedCandidatesFirstVotes_Current(wkid, rank, idno, pid, votes) AS (
	SELECT  c.wkid,
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
	pid INT REFERENCES Party(pid) ON DELETE CASCADE,
	votes INT NOT NULL DEFAULT 0
);

CREATE OR REPLACE VIEW Results_RankedCandidatesFirstVotes (year, wkid, rank, idno, pid, votes) AS (
	SELECT *
	FROM Results_RankedCandidatesFirstVotes_Old
	UNION ALL
	SELECT (select year from electionyear where iscurrent=true) as year, r.*
	FROM Results_RankedCandidatesFirstVotes_Current r
);

--WahlkreisWinnersFirstVotes
CREATE OR REPLACE VIEW Results_WahlkreisWinnersFirstVotes_Current (wkid, idno, pid, votes) AS (
	WITH RankedCandidatesFirstVotes AS (
		SELECT * FROM Results_RankedCandidatesFirstVotes_Current
	)

	SELECT wkid, idno, pid, votes
	FROM RankedCandidatesFirstVotes
	WHERE rank = 1
);

CREATE TABLE IF NOT EXISTS Results_WahlkreisWinnersFirstVotes_Old (
	year INT NOT NULL REFERENCES ElectionYear(year) ON DELETE CASCADE,
	wkid INT REFERENCES Wahlkreis(wkid),
	idno VARCHAR(32) NOT NULL REFERENCES Citizen(idno),
	pid INT NOT NULL REFERENCES Party(pid) ON DELETE CASCADE,
	votes INT NOT NULL DEFAULT 0
);

CREATE OR REPLACE VIEW Results_WahlkreisWinnersFirstVotes (year, wkid, idno, pid, votes) AS (
	SELECT *
	FROM Results_WahlkreisWinnersFirstVotes_Old
	UNION ALL
	SELECT (select year from electionyear where iscurrent=true) as year, r.*
	FROM Results_WahlkreisWinnersFirstVotes_Current r
);

--PartiesQualified
CREATE OR REPLACE VIEW Results_PartiesQualified_Current( pid, votes) AS (
	WITH AggregatedZweitstimmenForLL AS (
		SELECT * FROM Results_AggregatedZweitstimmenForLL_Current
	),
	WahlkreisWinnersFirstVotes AS (
		SELECT * FROM Results_WahlkreisWinnersFirstVotes_Current
	),
	AggregatedZweitstimmenForParty(pid, votes) AS (
	    SELECT ll.pid, SUM(azwfll.votes)
	    FROM AggregatedZweitstimmenForLL azwfll
	    JOIN LandesListe ll ON azwfll.llid = ll.llid
	    GROUP BY ll.pid
	)

	SELECT a1.pid, a1.votes
	FROM Party p NATURAL JOIN AggregatedZweitstimmenForParty a1
	WHERE a1.votes > 0
	AND (p.isminority
	    OR 2 < (SELECT COUNT(*) FROM WahlkreisWinnersFirstVotes WHERE pid = a1.pid)
	    OR a1.votes >= 0.05 * (SELECT SUM(votes) from AggregatedZweitstimmenForParty))
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
	SELECT (select year from electionyear where iscurrent=true) as year, r.*
	FROM Results_PartiesQualified_Current r
);

--AggregatedZweitstimmenForLLQualified
CREATE OR REPLACE VIEW Results_AggregatedZweitstimmenForLLQualified_Current(fsid, pid, llid, votes) AS (
	WITH AggregatedZweitstimmenForLL AS (
		SELECT * FROM Results_AggregatedZweitstimmenForLL_Current
	),
	PartiesQualified AS (
		SELECT * FROM Results_PartiesQualified_Current
	)

	SELECT  azwfs.fsid, ll.pid, azwfs.llid, azwfs.votes
	FROM AggregatedZweitstimmenForLL azwfs
	JOIN Landesliste ll ON azwfs.llid = ll.llid
	WHERE ll.pid in (select pid from PartiesQualified)
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
	SELECT (select year from electionyear where iscurrent=true) as year, r.*
	FROM Results_AggregatedZweitstimmenForLLQualified_Current r
);

--WahlkreisesiegePerPartyPerFS
CREATE OR REPLACE VIEW Results_WahlkreisesiegePerPartyPerFS_Current (pid, fsid, seats) AS (
	WITH WahlkreisWinnersFirstVotes AS (
		SELECT * FROM Results_WahlkreisWinnersFirstVotes_Current
	)

	SELECT pid, wk.fsid, count(*)
	FROM WahlkreisWinnersFirstVotes wkwfv
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
	SELECT (select year from electionyear where iscurrent=true) as year, r.*
	FROM Results_WahlkreisesiegePerPartyPerFS_Current r
);

-- SeatsPerFederalState
CREATE OR REPLACE VIEW Results_SeatsPerFederalState_Current(fsid, seats) AS (
	WITH RankedSeatsperFederalState(fsid, seatnumber) as (
	SELECT fs.fsid, rank() OVER (ORDER BY fs.citizencount/f.f desc) as seatnumber
	FROM FederalState fs, Factors f
	WHERE f.f < (598 * ((fs.citizencount)*1.00/(SELECT sum(citizencount) FROM FederalState)*1.00) +1)
	)

	SELECT fsid, COUNT(seatnumber) AS seat
	FROM RankedSeatsperFederalState rspfs
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
	SELECT (select year from electionyear where iscurrent=true) as year, r.*
	FROM Results_SeatsPerFederalState_Current r
);

--Results_FVandSVSeatsPerPartyPerFederalstate_Current
CREATE OR REPLACE VIEW Results_FVandSVSeatsPerPartyPerFederalstate_Current (pid, fsid, fvseats, svseats) AS (
	WITH AggregatedZweitstimmenForLLQualified AS (
		SELECT * FROM Results_AggregatedZweitstimmenForLLQualified_Current
	),
	SeatsPerFederalState AS (
		SELECT * FROM Results_SeatsPerFederalState_Current
	),
	WahlkreisesiegePerPartyPerFS AS (
		SELECT * FROM Results_WahlkreisesiegePerPartyPerFS_Current
	),
	RankedSeatsPerLandesliste (llid, seatnumberInFS) AS (
		SELECT azllq.llid,
			rank()  OVER (Partition by azllq.fsid Order by azllq.votes/f.f desc) as seatnumberInFS		--rank within Federalstate
		FROM AggregatedZweitstimmenForLLQualified azllq, Factors f
		WHERE f.f < ((select seats from SeatsPerFederalState spfs where spfs.fsid = azllq.fsid) -- (800.0/599.0) factor if seats in Bundestag reach max.
			     *((azllq.votes)*1.00/(SELECT sum(votes) FROM AggregatedZweitstimmenForLLQualified agzwfll where agzwfll.fsid = azllq.fsid)*1.00)
			     +1)
	),
	SeatsPerLandelisteByZweitstimme(llid, seats) AS (
		SELECT rspll.llid, Count(*) as numberOfSeats
		FROM RankedSeatsPerLandesliste rspll
		JOIN LandesListe ll ON ll.llid = rspll.llid
		JOIN SeatsPerFederalState spfs ON spfs.fsid = ll.fsid
		WHERE seatnumberInFS <= spfs.seats
		GROUP BY rspll.llid
	)

	select ll.pid, ll.fsid as fsid, coalesce(wkspppfs.seats,0) as fvseats, coalesce(spllbzs.seats,0) as svseats
	from  WahlkreisesiegePerPartyPerFS wkspppfs
	FULL OUTER JOIN Landesliste ll on ll.pid= wkspppfs.pid and ll.fsid=wkspppfs.fsid
	JOIN SeatsPerLandelisteByZweitstimme spllbzs on ll.llid = spllbzs.llid
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
	SELECT (select year from electionyear where iscurrent=true) as year, r.*
	FROM Results_FVandSVSeatsPerPartyPerFederalstate_Current r
);

--TotalNumberOfSeatsPerParty
CREATE OR REPLACE VIEW Results_TotalNumberOfSeatsPerParty_Current(pid,seats) AS (
	WITH PartiesQualified AS (
		SELECT * FROM Results_PartiesQualified_Current
	),
	FVandSVSeatsPerPartyPerFederalstate AS (
		SELECT * FROM Results_FVandSVSeatsPerPartyPerFederalstate_Current
	),
	RankedSeatsPerParty(pid, seatnumberTotal, seatnumberParty) AS (
		SELECT p.pid, rank()  OVER (Order by p.votes/f.f desc) as seatnumberTotal,	--rank overall seats in Bundestag
		rank()  OVER (Partition by p.pid Order by p.votes/f.f desc) as seatnumberParty	--rank within the Party
		FROM PartiesQualified p, Factors f
		WHERE f.f < (900 * p.votes * 1.00 / (SELECT sum(votes) FROM PartiesQualified)*1.00 +1) --598= max. seats in Bundestag for one Party
	),
	MinimumSeatsPerPartyPerFederalstate (pid, fsid, minSeats) AS (
		select dkllspppfs.pid, dkllspppfs.fsid as fsid, GREATEST(coalesce(dkllspppfs.fvseats,0), coalesce(dkllspppfs.svseats,0)) as minSeats
		from  FVandSVSeatsPerPartyPerFederalstate dkllspppfs
	),
	MinimumSeatsPerParty (pid,minSeats) AS (
		select pid, sum(minSeats) as minSeats
		from MinimumSeatsPerPartyPerFederalstate
		group by pid
	),
	TotalNumberOfSeats (seats) AS (
		SELECT max(seatnumberTotal) as seats		-- take the last seat,  fullfilling the minimum requirement for the last party
		from RankedSeatsPerParty rspp
		NATURAL JOIN MinimumSeatsPerParty mspp
		where rspp.seatnumberParty = mspp.minSeats  	-- select the first seat, fullfilling the minimum requirement for each party
	)

	select pid, max(seatnumberParty)				--take the last seat getting into Bundestag
	from RankedSeatsPerParty
	where seatnumberTotal <= (SELECT * from TotalNumberOfSeats)	--select the seats, which are in Bundestag
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
	SELECT (select year from electionyear where iscurrent=true) as year, r.*
	FROM Results_TotalNumberOfSeatsPerParty_Current r
);

-- SeatsPerLandesliste
CREATE OR REPLACE VIEW Results_SeatsPerLandesliste_Current (llid, seats)  AS(
	WITH AggregatedZweitstimmenForLLQualified AS (
		SELECT * FROM Results_AggregatedZweitstimmenForLLQualified_Current
	),
	TotalNumberOfSeatsPerParty AS (
		SELECT * FROM Results_TotalNumberOfSeatsPerParty_Current
	),
	WahlkreisesiegePerPartyPerFS AS (
		SELECT * FROM Results_WahlkreisesiegePerPartyPerFS_Current
	),
	RankedSeatsPerLandesliste (llid, seatnumberInParty, seatnumberLL) AS (
		SELECT azllq.llid,
			rank()  OVER (Partition by azllq.pid Order by azllq.votes/f.f desc) as seatnumberInParty,		--rank within Party
			rank()  OVER (Partition by azllq.pid, azllq.llid Order by azllq.votes/f.f desc) as seatnumberInLL	--rank within Landesliste

		FROM AggregatedZweitstimmenForLLQualified azllq, Factors f
		WHERE f.f < (Greatest(
				   ((select seats from TotalNumberOfSeatsPerParty tnospp where tnospp.pid = azllq.pid)
				    *((azllq.votes)*1.00
				      /(SELECT sum(votes) FROM AggregatedZweitstimmenForLLQualified agzwfll where agzwfll.pid = azllq.pid)*1.00
				      )
				     +1 --todoGB: check if falid now
				    ),
				    (select seats from WahlkreisesiegePerPartyPerFS wkspppfs where wkspppfs.fsid =azllq.fsid and wkspppfs.pid = azllq.pid)
				   )
				 )

	),
	RemainingRankedSeatsPerLandesliste (llid, seatnumberInParty) AS (
		SELECT rspll.llid,
		rank()  OVER (Partition by ll.pid  Order by rspll.seatnumberInParty asc) as seatnumberInParty		--rerank the remaining seats
		FROM RankedSeatsPerLandesliste rspll
		JOIN Landesliste ll ON ll.llid=rspll.llid
		Left Outer JOIN WahlkreisesiegePerPartyPerFS wkspll ON wkspll.pid=ll.pid and wkspll.fsid=ll.fsid
		where rspll.seatnumberLL > coalesce(wkspll.seats,0)							--remove seats won by Direktkandidaturen
	),
	NumberOfAdditionalSeatsPerParty (pid, seats) AS (
		SELECT spp.pid, (spp.seats-sum(coalesce(wks.seats,0))) as seats
		FROM TotalNumberOfSeatsPerParty spp
		Left OUTER JOIN WahlkreisesiegePerPartyPerFS wks ON spp.pid=wks.pid
		group by spp.pid, spp.seats
	),
	AdditionalSeatsToDirektmandatePerLandeliste(llid, seats) AS (
		SELECT  rrspll.llid, count(*)
		FROM RemainingRankedSeatsPerLandesliste rrspll
		NATURAL JOIN Landesliste ll
		NATURAL JOIN NumberOfAdditionalSeatsPerParty aspp
		where rrspll.seatnumberInParty <= aspp.seats
		group by  rrspll.llid
	)

	select ll.llid, (coalesce(wkspll.seats,0)+coalesce(astdkpll.seats,0)) as seats
	FROM AggregatedZweitstimmenForLLQualified azllq
	JOIN Landesliste ll ON azllq.llid=ll.llid
	LEFT OUTER JOIN WahlkreisesiegePerPartyPerFS wkspll ON ll.pid = wkspll.pid AND ll.fsid = wkspll.fsid
	LEFT OUTER JOIN AdditionalSeatsToDirektmandatePerLandeliste astdkpll ON ll.llid = astdkpll.llid
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
	SELECT (select year from electionyear where iscurrent=true) as year, r.*
	FROM Results_SeatsPerLandesliste_Current r
);

-- Delegates
CREATE OR REPLACE VIEW Results_Delegates_Current (idno, fsid, pid, wkid, llpos, ctype, rankInFS) AS (
	WITH WahlkreisWinnersFirstVotes AS (
		SELECT * FROM Results_WahlkreisWinnersFirstVotes_Current
	),
	AggregatedZweitstimmenForLLQualified AS (
		SELECT * FROM Results_AggregatedZweitstimmenForLLQualified_Current
	),
	SeatsPerLandesliste AS (
		SELECT * FROM Results_SeatsPerLandesliste_Current
	),
	MergedCandidates (idno, fsid, pid, wkid, llpos, ctype, rank) AS (
		(select wkwfv.idno, wk.fsid, wkwfv.pid, wk.wkid, 0 as llpos, 'Direktkandidat' as ctype, 0 as rank		-- 0 to come before the Landeslistenplätze (which start with 1)
		 from WahlkreisWinnersFirstVotes wkwfv
		 NATURAL JOIN Wahlkreis wk)
		UNION
		(select c.idno, ll.fsid, ll.pid, NULL as wkid, llp.position as llpos, 'Listenkandidat' as ctype,llp.position as rank
		 from AggregatedZweitstimmenForLLQualified azllq
		 JOIN Landesliste ll ON ll.llid = azllq.llid
		 JOIN Landeslistenplatz llp ON llp.llid = ll.llid
		 JOIN Candidates c ON c.idno = llp.idno
		 WHERE not exists (select * from WahlkreisWinnersFirstVotes wkwfv where wkwfv.idno = c.idno)	-- remove Landeslistenplätze which won a Direktmandat
		)
	),
	MergedRankedCandidates (idno, fsid, pid, wkid, llpos, ctype,  rank)  AS (
		SELECT mc.idno, mc.fsid,  mc.pid, mc.wkid, mc.llpos, mc.ctype,
		       rank() OVER (Partition by mc.fsid, mc.pid Order by mc.rank asc) as rank		--re-rank to match with number of seats, (all Direktmandate have rank 0 from MergedCandidates)
		FROM MergedCandidates mc
	)

	SELECT mrc.idno, mrc.fsid, mrc.pid, mrc.wkid, mrc.llpos, mrc.ctype, mrc.rank
	FROM MergedRankedCandidates mrc
	LEFT OUTER JOIN Landesliste ll ON mrc.fsid = ll.fsid AND mrc.pid=ll.pid
	NATURAL JOIN SeatsPerLandesliste spll
	WHERE mrc.pid is NULL or spll.seats >= rank
);

 CREATE TABLE IF NOT EXISTS Results_Delegates_Old (
	year INT NOT NULL REFERENCES ElectionYear(year) ON DELETE CASCADE,
	idno VARCHAR(32) NOT NULL REFERENCES CandidatesData(idno) ON DELETE CASCADE,
	fsid INT NOT NULL REFERENCES FederalState(fsid) ON DELETE CASCADE,
	pid INT NOT NULL REFERENCES Party(pid) ON DELETE CASCADE,
	wkid INT REFERENCES Wahlkreis(wkid) ON DELETE CASCADE,
	llpos INT NOT NULL DEFAULT 0,
	ctype VARCHAR(255) NOT NULL,
	rankInFS INT NOT NULL DEFAULT 0

);

CREATE OR REPLACE VIEW Results_Delegates (year, idno, fsid, pid, wkid, llpos, ctype, rankInFS)  AS (
	SELECT *
	FROM Results_Delegates_Old
	UNION ALL
	SELECT (select year from electionyear where iscurrent=true) as year, r.*
	FROM Results_Delegates_Current r
);

CREATE OR REPLACE VIEW  Results_NarrowWahlkreisWinsAndLosings_Current (wkid, idno, pid, rank, diffvotes) AS (
	WITH LostWahlkreiseTop10 (wkid, idno, rank, pid, diffvotes) AS (
		WITH LostWahlkreiseDiffVotes AS(
			SELECT  c.wkid,
				rank() OVER (PARTITION BY c.supportedby ORDER BY (c.votes-wkwfv.votes) desc) as rank,
				c.idno, c.supportedby as pid, (c.votes-wkwfv.votes) as diffvotes
			FROM Candidacy c
			JOIN Results_WahlkreisWinnersFirstVotes_Current wkwfv ON c.wkid = wkwfv.wkid
			JOIN Wahlkreis wk ON c.wkid = wk.wkid
			WHERE wk.year= (select year from electionyear where iscurrent=true) AND c.votes-wkwfv.votes < 0
		)
		SELECT wkid, idno, rank, pid, diffvotes
		FROM  LostWahlkreiseDiffVotes
		WHERE rank <=10
	),

	WonWahlkreiseTop10 (wkid, idno, rank, pid, diffvotes) AS (
		WITH WahlkreisSecondPlacedFirstVotes AS (
			SELECT wkid, idno, pid, votes
			FROM Results_RankedCandidatesFirstVotes_Current
			WHERE rank = 2
		),

		WonWahlkreiseDiffVotes AS(
			SELECT  c.wkid,
				rank() OVER (PARTITION BY c.supportedby ORDER BY (c.votes-wkspfv.votes) asc) as rank,
				c.idno, c.supportedby as pid, (c.votes-wkspfv.votes) as diffvotes
			FROM Candidacy c
			JOIN WahlkreisSecondPlacedFirstVotes wkspfv ON c.wkid = wkspfv.wkid
			JOIN Wahlkreis wk ON c.wkid = wk.wkid
			WHERE wk.year= (select year from electionyear where iscurrent=true) AND c.votes-wkspfv.votes > 0
		)
		SELECT wkid, idno, rank, pid, diffvotes
		FROM  WonWahlkreiseDiffVotes
		WHERE rank <=10
	),

	MergedTop10WinsAndLosings (wkid, idno, rank, pid, diffvotes) AS (
		(SELECT *
		FROM WonWahlkreiseTop10)
		UNION ALL
		(SELECT *
		FROM LostWahlkreiseTop10 lwt10
		WHERE not exists (SELECT * from  WonWahlkreiseTop10 wwt10 where lwt10.pid = wwt10.pid))
	)

	SELECT wkid, idno, pid, rank, diffvotes
	FROM MergedTop10WinsAndLosings
);

--NarrowWahlkreisWinsAndLosings
CREATE TABLE IF NOT EXISTS Results_NarrowWahlkreisWinsAndLosings_Old (
	year INT NOT NULL REFERENCES ElectionYear(year) ON DELETE CASCADE,
	wkid INT REFERENCES Wahlkreis(wkid),
	idno VARCHAR(32) NOT NULL REFERENCES Citizen(idno),
	pid INT REFERENCES Party(pid) ON DELETE CASCADE,
	rank INT NOT NULL DEFAULT 0,
	diffvotes INT NOT NULL DEFAULT 0
);

CREATE OR REPLACE VIEW Results_NarrowWahlkreisWinsAndLosings (year, wkid, idno, pid, rank, diffvotes) AS (
	SELECT *
	FROM Results_NarrowWahlkreisWinsAndLosings_Old
	UNION ALL
	SELECT (select year from electionyear where iscurrent=true) as year, r.*
	FROM Results_NarrowWahlkreisWinsAndLosings_Current r
);

--VoterparticipationPerWK
CREATE OR REPLACE VIEW Results_VoterparticipationPerWK_Current(wkid, elective, voted) AS
(
	WITH Results_NumberOfElectivesPerWK(wkid, sum) AS (
		SELECT wk.wkid, count(*) as sum
		FROM Citizenregistration cr
		JOIN Direktwahlbezirk dwb ON cr.dwbid = dwb.dwbid
		JOIN Wahlkreis wk ON dwb.wkid = wk.wkid
		WHERE wk.year= (select year from electionyear where iscurrent=true)
		GROUP BY wk.wkid
	),

	Results_NumberOfVotesPerWK(wkid, sum) AS (
		SELECT wk.wkid, count(*) as sum
		FROM hasvoted hv
		JOIN Citizenregistration cr ON hv.idno = cr.idno
		JOIN Direktwahlbezirk dwb ON cr.dwbid = dwb.dwbid
		JOIN Wahlkreis wk ON dwb.wkid = wk.wkid
		WHERE hv.year= (select year from electionyear where iscurrent=true) AND wk.year= (select year from electionyear where iscurrent=true)
		GROUP BY wk.wkid
	)
	SELECT rnoe.wkid, rnoe.sum, rnov.sum
	FROM Results_NumberOfElectivesPerWK rnoe
	INNER JOIN Results_NumberOfVotesPerWK rnov ON rnoe.wkid=rnov.wkid
);

CREATE TABLE IF NOT EXISTS Results_VoterparticipationPerWK_Old (
	year INT NOT NULL REFERENCES ElectionYear(year) ON DELETE CASCADE,
	wkid INT REFERENCES Wahlkreis(wkid),
	elective INT NOT NULL DEFAULT 0,
	voted INT NOT NULL DEFAULT 0
);

CREATE OR REPLACE VIEW Results_VoterparticipationPerWK  (year, wkid, elective, voted) AS (
	SELECT *
	FROM Results_VoterparticipationPerWK_Old
	UNION ALL
	SELECT (select year from electionyear where iscurrent=true) as year, r.*
	FROM Results_VoterparticipationPerWK_Current r
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

-- SELECT  ll.fsid, azwfs.llid,azwfs.votes
-- 	FROM AccumulatedZweitstimmenFS azwfs
-- 	JOIN Landesliste ll ON azwfs.llid = ll.llid
-- 	WHERE ll.year = (select year from electionyear where iscurrent=true)


--Überhangsmandate
-- select * from Results_FVandSVSeatsPerPartyPerFederalstate_Current
-- where (fvseats-svseats) > 0


-- select * from RankedWahlkreisCandidatesFirstVotes


COMMIT;
