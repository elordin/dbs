
---------------- STEP 0: preliminary work ----------------
/* aggregates Zweitstimmen per Landesliste*/ -- TODO year notwendig?!
WITH AggregatedZweitstimmenForLL(fsid, llid, votes) AS (
	SELECT  ll.fsid, azwfs.llid,azwfs.votes
	FROM AccumulatedZweitstimmenFS azwfs
	JOIN Landesliste ll ON azwfs.llid = ll.llid
	WHERE ll.year = 2013
),

-- ranks the Direktkandidaten
RankedCandidacies(wkid, rank, idno, pid) AS (
	SELECT  c.wkid, 
		rank() OVER (PARTITION BY c.wkid ORDER BY c.votes desc) as rank,
		c.idno, c.supportedby as pid
	FROM Candidacy c
	JOIN Wahlkreis wk ON c.wkid = wk.wkid
	WHERE wk.year= 2013  
),

-- selects the winning Direktkandidaten
WahlkreisWinners (wkid, idno, pid) AS (
    SELECT wkid, idno, pid
    FROM RankedCandidacies 
    WHERE rank = 1
),

-- aggregates Zweitstimmen per Party -- TODO year notwendig?!
AggregatedZweitstimmenForParty(pid, votes) AS (
    SELECT ll.pid, SUM(azwfll.votes)
    FROM AggregatedZweitstimmenForLL azwfll
    JOIN LandesListe ll ON azwfll.llid = ll.llid
    GROUP BY ll.pid
),

-- Parties that managed to have more than 5% or more than 3 Direktmandate or are Minority Parties
-- PartiesQualified(pid, votes) AS (
--     SELECT a1.pid, a1.votes
--     FROM Party p NATURAL JOIN AggregatedZweitstimmenForParty a1 JOIN AggregatedZweitstimmenForParty a2
--     GROUP BY a1.pid, a1.votes, p.isminority
--     HAVING a1.votes > 0
--        AND p.isminority -- minority parties are exempted from 5% threshold
--         OR a1.votes > SUM(a2.votes) * 0.05
--         OR 2 < (SELECT COUNT(DISTINCT wkid)
--                 FROM WahlkreisWinners
--                 WHERE pid = a1.pid)
-- ),

--bring noch nichts......
PartiesQualified(pid, votes) AS (
    SELECT a1.pid, a1.votes
    FROM Party p NATURAL JOIN AggregatedZweitstimmenForParty a1
    WHERE a1.votes > 0
       AND (p.isminority
	    OR 2 < (SELECT COUNT(*) FROM WahlkreisWinners WHERE pid = a1.pid)
	    OR a1.votes >= 0.05 * (SELECT SUM(votes) from AggregatedZweitstimmenForParty))
	    
),

AggregatedZweitstimmenForLLQualified(fsid, llid, votes) AS (
	SELECT  azwfs.fsid, azwfs.llid, azwfs.votes
	FROM AggregatedZweitstimmenForLL azwfs
	JOIN Landesliste ll ON azwfs.llid = ll.llid
	WHERE ll.pid in (select pid from PartiesQualified)
),

--calculates the number of Wahklkreis wins per Landesliste
WahlkreisesiegePerPartyPerFS (pid, fsid, seats) AS (
	SELECT pid, wk.fsid, count(*)
	FROM WahlkreisWinners wks
	JOIN Wahlkreis wk ON wks.wkid = wk.wkid
	JOIN Federalstate fs ON wk.fsid = fs.fsid
	GROUP BY pid, wk.fsid
),

---------------- STEP 1: Seats per Federalstate ----------------
-- creates the seat ranking for the Federalstates according to Sainte-Laguë with Höchstzahlverfahren
RankedSeatsperFederalState(fsid, seatnumber) as (
	WITH RECURSIVE Factors(fsid, f) AS (
		(SELECT fsid, 0.5 from federalstate)
		UNION ALL
		(SELECT f.fsid, f.f + 1
		 FROM Factors f
		 WHERE f.f < (598 * ((SELECT citizencount FROM FederalState fs where fs.fsid=f.fsid)*1.00/(SELECT sum(citizencount) FROM FederalState)*1.00) +1)
		)
	) 

	SELECT fs.fsid, rank() OVER (ORDER BY fs.citizencount/f.f desc) as seatnumber
	FROM FederalState fs
	JOIN Factors f ON fs.fsid = f.fsid
),

-- calculates the number of seats per Federalstate --> RESULT STEP 1
SeatsPerFederalState(fsid, seats) AS (
	SELECT fsid, COUNT(seatnumber) AS seat
	FROM RankedSeatsperFederalState rspfs
	WHERE rspfs.seatnumber <= 598
	GROUP BY FSID
),

---------------- STEP 2: Seats per Landesliste for each Federalstate ----------------
-- creates the seat ranking for the Landeslisten by Zweitstimmen according to Sainte-Laguë with Höchstzahlverfahren in Federalstate, in Party and in Landesliste
RankedSeatsPerLandesliste (llid, seatnumberInFS, seatnumberInParty, seatnumberLL) AS (
	WITH RECURSIVE Factors(llid, f) AS (
	    (SELECT llid, 0.5 FROM AggregatedZweitstimmenForLLQualified)
	    UNION ALL
	    (SELECT f.llid, f.f + 1
	     FROM Factors f
	     WHERE f.f < (Greatest(
			   ((select seats * (900.0/599.0) from SeatsPerFederalState spfs where spfs.fsid = (select fsid from Landesliste where llid=f.llid)) -- (800.0/599.0) factor if seats in Bundestag reach max.
			    *((SELECT votes FROM AggregatedZweitstimmenForLLQualified agzwfll where agzwfll.llid=f.llid)*1.00
			      /(SELECT sum(votes) FROM AggregatedZweitstimmenForLLQualified agzwfll where agzwfll.fsid = (select fsid from Landesliste ll where ll.llid=f.llid))*1.00
			      )
			     +1 --todoGB: check if falid now
			    ), 	
			    (select seats from WahlkreisesiegePerPartyPerFS wkspppfs where wkspppfs.fsid = (select fsid from Landesliste ll where ll.llid=f.llid)	and wkspppfs.pid = (select pid from Landesliste ll where ll.llid=f.llid))
			   )
			 ) 
	    )
	)

	SELECT ll.llid, 
		rank()  OVER (Partition by ll.fsid Order by azllq.votes/f.f desc) as seatnumberInFS,		--rank within Federalstate	
		rank()  OVER (Partition by ll.pid Order by azllq.votes/f.f desc) as seatnumberInParty,		--rank within Party
		rank()  OVER (Partition by ll.pid, ll.llid Order by azllq.votes/f.f desc) as seatnumberInLL	--rank within Landesliste
		
	FROM AggregatedZweitstimmenForLLQualified azllq 
	JOIN LandesListe ll ON azllq.llid = ll.llid
	JOIN Factors f ON f.llid = azllq.llid
),     

-- calculates the number of seats for each Landesliste according to the seat ranking an the totoal number of available seats --> RESULT STEP 2
SeatsPerLandelisteByZweitstimme(llid, seats) AS (
	SELECT rspll.llid, Count(*) as numberOfSeats 
	FROM RankedSeatsPerLandesliste rspll
	JOIN LandesListe ll ON ll.llid = rspll.llid
	JOIN SeatsPerFederalState spfs ON spfs.fsid = ll.fsid 
	WHERE seatnumberInFS <= spfs.seats
	GROUP BY rspll.llid   
),

---------------- STEP ZWISCHENERGEBNIS: minimum Number of Seats per Party ----------------
--calculates the minimum number of seats per Party in each Federalstate, based on Zweistimmen and won Wahlkreise
MinimumSeatsPerPartyPerFederalstate (pid, fsid, minSeats) AS (
	select ll.pid, ll.fsid as fsid, GREATEST(coalesce(wkspppfs.seats,0), coalesce(spllbzs.seats,0)) as minSeats
	from  WahlkreisesiegePerPartyPerFS wkspppfs
	FULL OUTER JOIN Landesliste ll on ll.pid= wkspppfs.pid and ll.fsid=wkspppfs.fsid
	JOIN SeatsPerLandelisteByZweitstimme spllbzs on ll.llid = spllbzs.llid
),

--adds up the overall minimum number of seats per Party  --> RESULT STEP ZWISCHENERGEBNIS
MinimumSeatsPerParty (pid,minSeats) AS (
	select pid, sum(minSeats) as minSeats
	from MinimumSeatsPerPartyPerFederalstate
	group by pid	
),

---------------- STEP 3: final number of Seats per Party ----------------
-- creates the seat ranking for the Bundestag for each Party based on Zweitstimmen according to Sainte-Laguë with Höchstzahlverfahren
RankedSeatsPerParty(pid, seatnumberTotal, seatnumberParty) AS (
	WITH RECURSIVE Factors(pid, f) AS (
	    (SELECT pid, 0.5 from PartiesQualified)
	    UNION ALL
	    (SELECT f.pid, f + 1
	     FROM Factors f
	     WHERE f < (900 * (SELECT votes FROM PartiesQualified p where p.pid = f.pid)*1.00 / (SELECT sum(votes) FROM PartiesQualified)*1.00 +1) --900 = max. seats in Bundestag
	    )
	)

	SELECT p.pid, rank()  OVER (Order by p.votes/f.f desc) as seatnumberTotal,	--rank overall seats in Bundestag
	rank()  OVER (Partition by p.pid Order by p.votes/f.f desc) as seatnumberParty	--rank within the Party
	FROM PartiesQualified p
	JOIN Factors f ON p.pid = f.pid
),

--calculates the final number of seats for Bundestag
TotalNumberOfSeats (seats) AS (
	SELECT max(seatnumberTotal) as seats		-- take the last seat,  fullfilling the minimum requirement for the last party
	from RankedSeatsPerParty rspp
	NATURAL JOIN MinimumSeatsPerParty mspp
	where rspp.seatnumberParty = mspp.minSeats  	-- select the first seat, fullfilling the minimum requirement for each party
),

--calculates the final number of seats per Party in Bundestag  --> RESULT STEP 3
TotalNumberOfSeatsPerParty(pid,seats) AS (	
	select pid, max(seatnumberParty)				--take the last seat getting into Bundestag
	from RankedSeatsPerParty
	where seatnumberTotal <= (SELECT * from TotalNumberOfSeats)	--select the seats, which are in Bundestag	
	group by pid	
),

---------------- STEP 4: final number of Seats per Landesliste ----------------
-- removes the seats used by Direktkandidaturen and re-ranks the remaining seats by the number within the Party
RemainingRankedSeatsPerLandesliste (llid, seatnumberInParty) AS (
	SELECT rspll.llid,
	rank()  OVER (Partition by ll.pid  Order by rspll.seatnumberInParty asc) as seatnumberInParty		--rerank the remaining seats
	FROM RankedSeatsPerLandesliste rspll
	JOIN Landesliste ll ON ll.llid=rspll.llid
	Left Outer JOIN WahlkreisesiegePerPartyPerFS wkspll ON wkspll.pid=ll.pid and wkspll.fsid=ll.fsid
	where rspll.seatnumberLL > coalesce(wkspll.seats,0)							--remove seats won by Direktkandidaturen
),

---calculates the number of seats per Party, without the seats for Direktkandidaturen
NumberOfAdditionalSeatsPerParty (pid, seats) AS (
	SELECT spp.pid, (spp.seats-sum(wks.seats)) as seats
	FROM TotalNumberOfSeatsPerParty spp
	JOIN WahlkreisesiegePerPartyPerFS wks ON spp.pid=wks.pid
	group by spp.pid, spp.seats
),

-- calculates the number of additional seats to the Direktkandidaturen, used by Landeslistenplätze
AdditionalSeatsToDirektmandatePerLandeliste(llid, seats) AS (
	SELECT  rrspll.llid, count(*)
	FROM RemainingRankedSeatsPerLandesliste rrspll
	NATURAL JOIN Landesliste ll
	NATURAL JOIN NumberOfAdditionalSeatsPerParty aspp
	where rrspll.seatnumberInParty <= aspp.seats
	group by  rrspll.llid
),

-- calculates the number of seats per Landesliste by adding the Direktkandidaturen plus the raimining seats, filled by Landeslistenplätzen --> RESULT STEP 4
SeatsPerLandesliste (llid, seats)  AS(
	select ll.llid, (coalesce(wkspll.seats,0)+coalesce(astdkpll.seats,0)) as seats
	FROM AggregatedZweitstimmenForLLQualified azllq
	JOIN Landesliste ll ON azllq.llid=ll.llid
	LEFT OUTER JOIN WahlkreisesiegePerPartyPerFS wkspll ON ll.pid = wkspll.pid AND ll.fsid = wkspll.fsid
	LEFT OUTER JOIN AdditionalSeatsToDirektmandatePerLandeliste astdkpll ON ll.llid = astdkpll.llid
	WHERE (coalesce(wkspll.seats,0)+coalesce(astdkpll.seats,0)) >0
),

---------------- STEP 5: List of Delegates for Bundestag ----------------
--unions the Direktkandidaturen with the Listenplätzen
 MergedCandidates (idno, fsid, pid, wkid, rank) AS (
	(select wks.idno, wk.fsid, wks.pid, wk.wkid, 0 as position		-- 0 to come before the Landeslistenplätze (which start with 1)
	 from WahlkreisWinners wks
	 NATURAL JOIN Wahlkreis wk)
	UNION
	(select c.idno, ll.fsid, ll.pid, NULL as wkid,llp.position as rank
	 from AggregatedZweitstimmenForLLQualified azllq
	 JOIN Landesliste ll ON ll.llid = azllq.llid
	 JOIN Landeslistenplatz llp ON llp.llid = ll.llid
	 JOIN Candidates c ON c.idno = llp.idno 
	 WHERE not exists (select * from WahlkreisWinners wks where wks.idno = c.idno)	-- remove Landeslistenplätze which won a Direktmandat
	 )
 ),

--ranks the unioned Candidates
MergedRankedCandidates (idno, fsid, pid, wkid,  rank)  AS (
	SELECT mc.idno, mc.fsid,  mc.pid, mc.wkid, 
	       rank() OVER (Partition by mc.fsid, mc.pid Order by mc.rank asc) as rank		--re-rank to match with number of seats, (all Direktmandate have rank 0 from MergedCandidates)
	FROM MergedCandidates mc	
),

-- selecte the Candidates which get a seat in Bundestag --> RESULT STEP 5
Delegates (idno, fsid, pid, wkid, rankInFS) AS (
	SELECT mrc.idno, mrc.fsid, mrc.pid, mrc.wkid, mrc.rank
	FROM MergedRankedCandidates mrc
	LEFT OUTER JOIN Landesliste ll ON mrc.fsid = ll.fsid AND mrc.pid=ll.pid
	NATURAL JOIN SeatsPerLandesliste spll	
	WHERE mrc.pid is NULL or spll.seats >= rank						--take only candidates who have ll-rank <= ll-number of seats
)

------------------------------ TESTING ------------------------------
---------- STEP 1: Seats per Federalstate ----------
----Ranked Seats
-- SELECT fs.name, rspfs.seatnumber
-- FROM RankedSeatsperFederalState rspfs
-- JOIN FederalState fs ON rspfs.fsid = fs.fsid
-- ORDER BY rspfs.seatnumber

----Seats per fs
-- SELECT fs.name, spfs.seats
-- FROM SeatsPerFederalstate spfs
-- JOIN FederalState fs ON spfs.fsid = fs.fsid
-- ORDER BY fs.fsid

---------------- STEP 2: Seats per Landesliste for each Federalstate ----------------
----Ranked seats
-- SELECT rspll.seatnumberInFS, fs.name, p.name
-- FROM RankedSeatsPerLandesliste rspll
-- JOIN Landesliste ll ON ll.llid = rspll.llid
-- JOIN Federalstate fs ON fs.fsid = ll.fsid
-- JOIN Party p on ll.pid = p.pid
-- WHERE fs.name='Thüringen'

----Number of Seats per Landesliste
-- SELECT spllpzw.seats, fs.name, p.name
-- FROM SeatsPerLandelisteByZweitstimme spllpzw
-- JOIN Landesliste ll ON ll.llid = spllpzw.llid
-- JOIN Federalstate fs ON fs.fsid = ll.fsid
-- JOIN Party p on ll.pid = p.pid
-- WHERE fs.name='Thüringen'
-- ORDER BY spllpzw.seats desc

---------------- STEP ZWISCHENERGEBNIS: minimum Number of Seats per Party ----------------
---Minimum seats per Party per Federalstate
-- SELECT mspppf.minSeats, fs.name, p.name
-- FROM MinimumSeatsPerPartyPerFederalstate mspppf
-- JOIN Federalstate fs ON mspppf.fsid = fs.fsid
-- JOIN Party p on mspppf.pid = p.pid
-- WHERE fs.name='Thüringen'

----Minimum seats per Party in Bundestag
-- SELECT mspp.minSeats, p.name
-- FROM MinimumSeatsPerParty mspp
-- JOIN Party p ON mspp.pid = p.pid


---------------- STEP 3: final number of Seats per Party ----------------

----ranked Seats in Bundestag, total and in Party
-- SELECT p.name, rspp.seatnumberTotal, rspp.seatnumberParty
-- FROM RankedSeatsPerParty rspp
-- JOIN Party p ON rspp.pid = p.pid
-- ORDER BY rspp.seatnumberTotal

----total number of seats in Bundestag for Party
-- SELECT p.name, tnospp.seats
-- FROM TotalNumberOfSeatsPerParty tnospp
-- JOIN Party p ON tnospp.pid = p.pid 
-- ORDER BY tnospp.seats desc


---------------- STEP 4: final number of Seats per Landesliste ----------------
----ranks seats fro each Landesliste within Party and LL
-- SELECT fs.name, p.name, rspll.seatnumberInParty, rspll.seatnumberLL
-- FROM RankedSeatsPerLandesliste rspll
-- JOIN Landesliste ll ON ll.llid = rspll.llid
-- JOIN Federalstate fs ON ll.fsid = fs.fsid
-- JOIN Party p on ll.pid = p.pid
-- WHERE fs.name='Thüringen' AND p.name='CDU'

----total number of seats per Landesliste
-- SELECT fs.name, p.name, spll.seats
-- FROM SeatsPerLandesliste spll
-- JOIN Landesliste ll ON ll.llid = spll.llid
-- JOIN Federalstate fs ON ll.fsid = fs.fsid
-- JOIN Party p on ll.pid = p.pid
-- WHERE p.name='CDU'

---------------- STEP 5: List of Delegates for Bundestag ----------------
SELECT  c.Lastname, c.Firstname, p.name, fs.name, d.rankInFS 
FROM Delegates d 
JOIN Candidates c ON d.idno = c.idno
JOIN Federalstate fs ON fs.fsid = d.fsid
JOIN Party p ON p.pid=d.pid
WHERE p.name='CDU'
ORDER BY c.Lastname, c.Firstname

-- SELECT  Count(*)
-- FROM Delegates d 




