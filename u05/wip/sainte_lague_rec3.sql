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

WahlkreisSieger AS (
    SELECT wk.wkid, c1.idno, c1.supportedby
    FROM Wahlkreis wk NATURAL JOIN Candidacy c1 INNER JOIN Candidacy c2 ON c1.wkid = c2.wkid
    WHERE wk.year = 2013
    GROUP BY wk.wkid, c1.idno, c1.supportedby, c1.votes
    HAVING c1.votes = MAX(c2.votes)
    LIMIT 1
),

AggregatedVotesZS(pid, year, votes) AS (
    SELECT pid, year, SUM(votes)
    FROM AccumulatedZweitstimmenWK NATURAL JOIN LandesListe
    GROUP BY pid, year
),

SeatsPerFederalState(fsid, seats) AS (
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
                WHERE supportedby = a1.pid)
),

/*SeatsPerLandelisteByZweitstimme(llid, seats) AS (
    SELECT ll.llid, (
        WITH RECURSIVE Factors(f) AS (
            VALUES (0.5)
            UNION ALL
            SELECT f + 1
            FROM Factors
            WHERE f < (spfs.seats * (SELECT 1.250 * MAX(citizencount) / SUM(citizencount)
            FROM FederalState))
        )
        SELECT SUM(quotient) AS seats
        FROM (
            SELECT azfs.llid, azfs.votes / f.f AS quotient
            FROM AccumulatedZweitstimmenFS azfs, Factors f
            ORDER BY quotient
            LIMIT spfs.seats
        ) AS r
        GROUP BY llid
        HAVING llid = ll.llid
    ) AS seats
    FROM PartiesBeyondFivePercent ps -- pid votes
        NATURAL JOIN LandesListe ll
        NATURAL JOIN SeatsPerFederalState spfs
        INNER JOIN AccumulatedZweitstimmenFS azfs ON azfs.llid = ll.llid
    WHERE ll.year = 2009
)*/

SeatsPerLandelisteByZweitstimme(llid, seats) AS (
	WITH RECURSIVE Factors(fsid, f) AS (
	    (select fsid, 0.5 from federalstate)
	    UNION ALL
	    SELECT fsid, f + 1
	    FROM Factors f
	    WHERE f < (select max(seats) from SeatsPerFederalState spfs where spfs.fsid = f.fsid)
	),
	RankedSeatsPerLandesliste (llid, seatsInFS, seatnumber) AS (
		SELECT ll.llid, spfs.seats, rank()  OVER
			(Partition by ll.fsid Order by azfs.votes/f.f desc) as seatnumber
		FROM PartiesBeyondFivePercent ps -- pid votes
		NATURAL JOIN LandesListe ll
		NATURAL JOIN SeatsPerFederalState spfs
		INNER JOIN AggregatedZweitstimmenFS azfs ON azfs.llid = ll.llid
		INNER JOIN Factors f ON f.fsid = ll.fsid
		WHERE ll.year = 2013)      
       
	SELECT llid, Count(*) as numberOfSeats 
	from RankedSeatsPerLandesliste  
	where seatnumber <= seatsInFS
	group by llid   
)

SELECT * FROM SeatsPerLandelisteByZweitstimme
    NATURAL JOIN landesliste ll
    NATURAL JOIN party
    JOIN federalstate fs on ll.fsid = fs.fsid
    where fs.name = 'Thüringen'
    

