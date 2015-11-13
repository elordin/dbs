WITH RECURSIVE
Factors(f) AS (
    VALUES (0.5)
    UNION ALL
    SELECT f + 1
    FROM Factors
    WHERE f < (598 * (SELECT 1.250 * MAX(citizencount) / SUM(citizencount)
                             FROM FederalState))
),

AggregatedZweitstimmenFS(llid, votes) AS (
    SELECT llid, SUM(votes)
    FROM AccumulatedZweitstimmenWK
    GROUP BY llid
),

WahlkreisSieger (wkid, idno, pid) AS (
    SELECT wk.wkid, c1.idno, c1.supportedby as pid
    FROM Wahlkreis wk NATURAL JOIN Candidacy c1 INNER JOIN Candidacy c2 ON c1.wkid = c2.wkid
    WHERE wk.year = 2013
    GROUP BY wk.wkid, c1.idno, c1.supportedby, c1.votes
    HAVING c1.votes = MAX(c2.votes)
),

AggregatedVotesZS(pid, year, votes) AS (
    SELECT pid, year, SUM(votes)
    FROM AccumulatedZweitstimmenWK NATURAL JOIN LandesListe
    GROUP BY pid, year
),

SeatsPerFederalState_STEP1(fsid, seats) AS (
    SELECT fsid, COUNT(quotient) AS seats
    FROM (
        SELECT fs.fsid, fs.citizencount / f.f AS quotient
          -- TODO: Create FederlStateWithCitizenCount
          FROM FederalState fs, Factors f
          ORDER BY quotient DESC
          LIMIT 598) AS r
    GROUP BY fsid
),

-- Parties that managed to have more than 5% or more than 3 Direktmandate or are Minority Parties
PartiesBeyondFivePercent(pid, votes) AS (
    SELECT a1.pid, a1.votes
    FROM Party p NATURAL JOIN AggregatedVotesZS a1 JOIN AggregatedVotesZS a2 ON a1.year = a2.year
    WHERE a1.year = 2013
    GROUP BY a1.pid, a1.votes, p.isminority
    HAVING a1.votes > 0
       AND p.isminority -- minority parties are exempted from 5% threshold
        OR a1.votes > SUM(a2.votes) * 0.05
        OR 2 < (SELECT COUNT(DISTINCT wkid)
                FROM WahlkreisSieger
                WHERE pid = a1.pid)
),

SeatsPerLandelisteByZweitstimme_STEP2_1(llid, seats) AS (
	WITH RECURSIVE Factors(fsid, f) AS (
	    (select fsid, 0.5 from federalstate)
	    UNION ALL
	    SELECT fsid, f + 1
	    FROM Factors f
	    WHERE f < (select max(seats) from SeatsPerFederalState_STEP1 spfs where spfs.fsid = f.fsid)
	),
	RankedSeatsPerLandesliste (llid, seatsInFS, seatnumber) AS (
		SELECT ll.llid, spfs.seats, rank()  OVER
			(Partition by ll.fsid Order by azfs.votes/f.f desc) as seatnumber
		FROM PartiesBeyondFivePercent ps -- pid votes
		NATURAL JOIN LandesListe ll
		NATURAL JOIN SeatsPerFederalState_STEP1 spfs
		INNER JOIN AggregatedZweitstimmenFS azfs ON azfs.llid = ll.llid
		INNER JOIN Factors f ON f.fsid = ll.fsid
		WHERE ll.year = 2013)      
       
	SELECT llid, Count(*) as numberOfSeats 
	from RankedSeatsPerLandesliste  
	where seatnumber <= seatsInFS
	group by llid   
),

MinimumSeatsPerParty (pid,seats) AS (
	WITH WahlkreisesiegePerPartyPerFS (pid, fsid, seats) AS (
		select pid, wk.fsid, count(*)
		from WahlkreisSieger wks
		join Wahlkreis wk ON wks.wkid = wk.wkid
		join Federalstate fs ON wk.fsid = fs.fsid
		group by pid, wk.fsid
	),
	MinimumSeatsPerPartyPerFederalstate (pid, fsid, seats) AS (
	select ll.pid, ll.fsid as fsid, GREATEST(coalesce(wkspppfs.seats,0), coalesce(spllbzs.seats,0)) as seats
	from  WahlkreisesiegePerPartyPerFS wkspppfs
	FULL OUTER JOIN Landesliste ll on ll.pid= wkspppfs.pid and ll.fsid=wkspppfs.fsid
	JOIN SeatsPerLandelisteByZweitstimme_STEP2_1 spllbzs on ll.llid = spllbzs.llid)

	select pid, sum(seats) as seats
	from MinimumSeatsPerPartyPerFederalstate
	group by pid

	
),

 WahlkreisesiegePerPartyPerFS (pid, fsid, seats) AS (
		select pid, wk.fsid, count(*)
		from WahlkreisSieger wks
		join Wahlkreis wk ON wks.wkid = wk.wkid
		join Federalstate fs ON wk.fsid = fs.fsid
		group by pid, wk.fsid)


SELECT sum(seats) from MinimumSeatsPerParty



    

