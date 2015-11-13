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

WahlkreisesiegePerPartyPerFS (pid, fsid, seats) AS (
	select pid, wk.fsid, count(*)
	from WahlkreisSieger wks
	join Wahlkreis wk ON wks.wkid = wk.wkid
	join Federalstate fs ON wk.fsid = fs.fsid
	group by pid, wk.fsid
),

MinimumSeatsPerParty (pid,seatsMin) AS (
	WITH MinimumSeatsPerPartyPerFederalstate (pid, fsid, seats) AS (
	select ll.pid, ll.fsid as fsid, GREATEST(coalesce(wkspppfs.seats,0), coalesce(spllbzs.seats,0)) as seats
	from  WahlkreisesiegePerPartyPerFS wkspppfs
	FULL OUTER JOIN Landesliste ll on ll.pid= wkspppfs.pid and ll.fsid=wkspppfs.fsid
	JOIN SeatsPerLandelisteByZweitstimme_STEP2_1 spllbzs on ll.llid = spllbzs.llid)

	select pid, sum(seats) as seatsMin
	from MinimumSeatsPerPartyPerFederalstate
	group by pid

	
),

SeatsPerParty_STEP3(pid,seats) AS (
	WITH RECURSIVE Factors(f) AS (
	    VALUES (0.5)
	    UNION ALL
	    SELECT f + 1
	    FROM Factors f
	    WHERE f < (400)
	),
	
	RankedSeatsPerParty(pid,seatnumberGes, seatnumberParty) AS (
		SELECT pbfp.pid, rank()  OVER (Order by pbfp.votes/f.f desc) as seatnumberGes,
		rank()  OVER (Partition by pbfp.pid Order by pbfp.votes/f.f desc) as seatnumberParty
		FROM PartiesBeyondFivePercent pbfp , Factors f
	),

	TotalNumberOfSeats (seats) AS (
		SELECT max(seatnumberges) as seats
		from RankedSeatsPerParty rspp
		NATURAL JOIN MinimumSeatsPerParty mspp
		NATURAL JOIN Party
		where rspp.seatnumberParty = mspp.seatsMin
	)

	select pid, max(seatnumberParty)
	from RankedSeatsPerParty
	where seatnumberGes <= (SELECT * from TotalNumberOfSeats)	
	group by pid	
),

--ohne berücksichtigung der gewonnenen Wahlkreise
AdditionalSeatsToDirektmandatePerLandeliste(llid, seats) AS (
	WITH RECURSIVE Factors(fsid, f) AS (
	    (select fsid, 0.5 from federalstate)
	    UNION ALL
	    SELECT fsid, f + 1
	    FROM Factors f
	    WHERE f < (select max(seats)+20 from SeatsPerFederalState_STEP1 spfs where spfs.fsid = f.fsid)
	),
	RankedSeatsPerLandesliste (llid, seatsForParty, seatnumberInParty, seatnumberLL) AS (
		SELECT ll.llid, spp.seats as seatsForParty,
			rank()  OVER (Partition by spp.pid Order by azfs.votes/f.f desc) as seatnumberInParty,
			rank()  OVER (Partition by spp.pid, ll.llid Order by azfs.votes/f.f desc) as seatnumberInLL
		FROM SeatsPerParty_STEP3 spp -- pid votes
		NATURAL JOIN LandesListe ll
		INNER JOIN AggregatedZweitstimmenFS azfs ON azfs.llid = ll.llid
		INNER JOIN Factors f ON f.fsid = ll.fsid
		WHERE ll.year = 2013
	),
	RemainingRankedSeatsPerLandesliste (llid, seatsForParty, seatnumberInParty) AS (
		SELECT rspll.llid, rspll.seatsForParty,
		rank()  OVER (Partition by ll.pid  Order by rspll.seatnumberInParty asc) as seatnumberInParty
		FROM RankedSeatsPerLandesliste rspll
		JOIN Landesliste ll ON ll.llid=rspll.llid
		Left Outer JOIN WahlkreisesiegePerPartyPerFS wkspll ON wkspll.pid=ll.pid and wkspll.fsid=ll.fsid
		where rspll.seatnumberLL > coalesce(wkspll.seats,0)
	)

	--select * from Factors

	--select * from RemainingRankedSeatsPerLandesliste where llid=310 order by seatnumberInParty asc
       
	SELECT  rrspll.llid, count(*)
	FROM RemainingRankedSeatsPerLandesliste rrspll
	NATURAL JOIN Landesliste ll
	where rrspll.seatnumberInParty <= (rrspll.seatsForParty - (select sum(seats) from WahlkreisesiegePerPartyPerFS wkspppfs  where wkspppfs.pid=ll.pid))
	group by  rrspll.llid
),

SeatsPerLandesliste (llid, seats)  AS(
	select ll.llid, (coalesce(wkspll.seats,0)+coalesce(astdkpll.seats,0)) as seats
	FROM Landesliste ll 
	LEFT OUTER JOIN WahlkreisesiegePerPartyPerFS wkspll ON ll.pid = wkspll.pid AND ll.fsid = wkspll.fsid
	LEFT OUTER JOIN AdditionalSeatsToDirektmandatePerLandeliste astdkpll ON ll.llid = astdkpll.llid
	WHERE ll.year = 2013 AND ll.pid in (select pid from PartiesBeyondFivePercent) AND (coalesce(wkspll.seats,0)+coalesce(astdkpll.seats,0)) >0
),

Delegates (idno, fsid, pid, wkid, rank) AS (
	WITH MergedCandidates (idno, fsid, pid, wkid, rank) AS (
		(select wks.idno, wk.fsid, wks.pid, wk.wkid, 0 as position
		 from WahlkreisSieger wks
		 NATURAL JOIN Wahlkreis wk)
		UNION
		(select c.idno, ll.fsid, ll.pid, NULL as wkid,llp.position as rank
		 from Candidates c
		 NATURAL JOIN Landeslistenplatz llp
		 NATURAL JOIN Landesliste ll
		 WHERE ll.year = 2013 AND ll.pid in (select pid from PartiesBeyondFivePercent) AND  not exists (select * from WahlkreisSieger wks where wks.idno = c.idno)
		 )
	 ),
	MergedRankedCandidates (idno, fsid, pid, wkid,  rank)  AS (
		select mc.idno, mc.fsid,  mc.pid, mc.wkid, rank() OVER (Partition by mc.fsid, mc.pid Order by rank asc) as rank
		from MergedCandidates mc	
		)
	 
	--select * from MergedRankedCandidates

	select mrc.idno, mrc.fsid, mrc.pid, mrc.wkid, mrc.rank
	FROM MergedRankedCandidates mrc
	LEFT OUTER JOIN Landesliste ll ON mrc.fsid = ll.fsid AND mrc.pid=ll.pid
	NATURAL JOIN SeatsPerLandesliste spll	
	WHERE mrc.pid is NULL or spll.seats >= rank
)




--select p.name, fs.name, seats from SeatsPerLandelisteFINAL_STEP4 NATURAL JOIN LandesListe ll NATURAL JOIN FederalState fs JOIN Party p ON ll.pid=p.pid
--where p.name = 'CDU'

--select p.name, fs.name, seatsperParty, seatnumber from RankedSeatsPerLandesliste NATURAL JOIN LandesListe ll NATURAL JOIN FederalState fs JOIN Party p ON ll.pid=p.pid
--where p.name = 'CDU' and seatnumber <= seatsperParty

--select * from WahlkreisesiegePerPartyPerFS ll NATURAL JOIN FederalState fs JOIN Party p ON ll.pid=p.pid where p.name = 'CDU' 

--SELECT seats, p.name, fs.name from  SeatsPerLandesliste x NATURAL JOIN LandesListe ll NATURAL JOIN FederalState fs JOIN Party p ON ll.pid=p.pid where p.name = 'CDU' --and fs.name='Saarland' 

select  c.Firstname, c.Lastname, p.name, fs.name, d.rank 
from Delegates d 
NATURAL JOIN Candidates c
NATURAL JOIN Federalstate fs
JOIN Party p ON p.pid=d.pid
where p.name='CDU' and fs.name='Niedersachsen'





