
---------------- STEP 0: preliminary work ----------------
/* aggregates Zweitstimmen per Landesliste*/ -- TODO year notwendig?!
WITH AggregatedZweitstimmenForLL(llid, votes) AS (
    SELECT llid, SUM(votes)
    FROM AccumulatedZweitstimmenWK
    GROUP BY llid
),

-- selects the winning Direktkandidaten

-- old VERSION
-- WahlkreisWinners (wkid, idno, pid) AS (
--     SELECT wk.wkid, c1.idno, c1.supportedby as pid
--     FROM Wahlkreis wk NATURAL JOIN Candidacy c1 INNER JOIN Candidacy c2 ON c1.wkid = c2.wkid
--     WHERE wk.year = 2013
--     GROUP BY wk.wkid, c1.idno, c1.supportedby, c1.votes
--     HAVING c1.votes = MAX(c2.votes)
-- ),
WahlkreisWinners (wkid, idno, pid) AS (
    SELECT c1.wkid, c1.idno, c1.supportedby as pid
    FROM Candidacy c1
    INNER JOIN
        (SELECT wkid, MAX(votes) as votes
        FROM Candidacy
        NATURAL JOIN Wahlkreis wk
        WHERE wk.year = 2013
        GROUP BY wkid) as c2
    ON c1.wkid = c2.wkid and c1.votes= c2.votes
),

-- aggregates Zweitstimmen per Party -- TODO year notwendig?!
AggregatedZweitstimmenForParty(pid, year, votes) AS (
    SELECT pid, year, SUM(votes)
    FROM AccumulatedZweitstimmenWK NATURAL JOIN LandesListe
    GROUP BY pid, year
),

-- Parties that managed to have more than 5% or more than 3 Direktmandate or are Minority Parties
PartiesBeyondFivePercent(pid, votes) AS (
    SELECT a1.pid, a1.votes
    FROM Party p NATURAL JOIN AggregatedZweitstimmenForParty a1 JOIN AggregatedZweitstimmenForParty a2 ON a1.year = a2.year
    WHERE a1.year = 2013
    GROUP BY a1.pid, a1.votes, p.isminority
    HAVING a1.votes > 0
       AND p.isminority -- minority parties are exempted from 5% threshold
        OR a1.votes > SUM(a2.votes) * 0.05
        OR 2 < (SELECT COUNT(DISTINCT wkid)
                FROM WahlkreisWinners
                WHERE pid = a1.pid)
),

--bring noch nichts......
PartiesBeyondFivePercent2(pid, votes) AS (
    SELECT a1.pid, a1.votes
    FROM Party p NATURAL JOIN AggregatedZweitstimmenForParty a1
    WHERE a1.year = 2013
       AND a1.votes > 0
       AND (p.isminority
        OR a1.votes >= 0.05 * (SELECT SUM(votes) from AggregatedZweitstimmenForParty  where year = 2013)
        OR 2 < (SELECT COUNT(DISTINCT wkid) FROM WahlkreisWinners WHERE pid = a1.pid))
),

---------------- STEP 1: Seats per Federalstate ----------------
-- creates the seat ranking for the Federalstates according to Sainte-Laguë with Höchstzahlverfahren
RankedSeatsperFederalState(fsid, seatnumber) as (
    WITH RECURSIVE Factors(f) AS (
        VALUES (0.5)
        UNION ALL
        SELECT f + 1
        FROM Factors
        WHERE f < (598 * (SELECT 1.250 * MAX(citizencount) / SUM(citizencount) FROM FederalState))
    )

    SELECT fs.fsid, rank() OVER (ORDER BY fs.citizencount/f.f desc) as seatnumber
    FROM FederalState fs, Factors f
),

-- calculates the number of seats per Federalstate --> RESULT STEP 1
SeatsPerFederalState(fsid, seats) AS (
    SELECT fsid, COUNT(seatnumber) AS seat
    FROM RankedSeatsperFederalState rspfs
    WHERE rspfs.seatnumber <= 598
    GROUP BY FSID
),

---------------- STEP 2: Seats per Landesliste for each Federalstate ----------------
-- creates the seat ranking for the Landeslisten by Zweitstimmen according to Sainte-Laguë with Höchstzahlverfahren
RankedSeatsPerLandesliste (llid, seatnumber) AS (
    WITH RECURSIVE Factors(fsid, f) AS (
        (select fsid, 0.5 from federalstate)
        UNION ALL
        SELECT fsid, f + 1
        FROM Factors f
        WHERE f < (select max(seats) from SeatsPerFederalState spfs where spfs.fsid = f.fsid)
    )

    SELECT ll.llid, rank()  OVER
        (Partition by ll.fsid Order by azfs.votes/f.f desc) as seatnumber
    FROM PartiesBeyondFivePercent ps -- pid votes
    NATURAL JOIN LandesListe ll
    INNER JOIN AggregatedZweitstimmenForLL azfs ON azfs.llid = ll.llid
    INNER JOIN Factors f ON f.fsid = ll.fsid
    WHERE ll.year = 2013
),

-- calculates the number of seats for each Landesliste according to the seat ranking an the totoal number of available seats --> RESULT STEP 2
SeatsPerLandelisteByZweitstimme(llid, seats) AS (
    SELECT llid, Count(*) as numberOfSeats
    from RankedSeatsPerLandesliste
    NATURAL JOIN LandesListe ll
    NATURAL JOIN SeatsPerFederalState spfs
    where seatnumber <= spfs.seats
    group by llid
),

---------------- STEP ZWISCHENERGEBNIS: minimum Number of Seats per Party ----------------
--calculates the number of Wahklkreis wins per Landesliste
WahlkreisesiegePerPartyPerFS (pid, fsid, seats) AS (
    select pid, wk.fsid, count(*)
    from WahlkreisWinners wks
    join Wahlkreis wk ON wks.wkid = wk.wkid
    join Federalstate fs ON wk.fsid = fs.fsid
    group by pid, wk.fsid
),

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
    WITH RECURSIVE Factors(f) AS (
        VALUES (0.5)
        UNION ALL
        SELECT f + 1
        FROM Factors f
        WHERE f < (400)
    )

    SELECT pbfp.pid, rank()  OVER (Order by pbfp.votes/f.f desc) as seatnumberTotal,    --rank overall seats in Bundestag
    rank()  OVER (Partition by pbfp.pid Order by pbfp.votes/f.f desc) as seatnumberParty    --rank within the Party
    FROM PartiesBeyondFivePercent pbfp , Factors f
),

--calculates the final number of seats for Bundestag
TotalNumberOfSeats (seats) AS (
    SELECT max(seatnumberTotal) as seats        -- take the last seat,  fullfilling the minimum requirement for the last party
    from RankedSeatsPerParty rspp
    NATURAL JOIN MinimumSeatsPerParty mspp
    where rspp.seatnumberParty = mspp.minSeats      -- select the first seat, fullfilling the minimum requirement for each party
),

--calculates the final number of seats per Party in Bundestag  --> RESULT STEP 3
TotalNumberOfSeatsPerParty(pid,seats) AS (
    select pid, max(seatnumberParty)                --take the last seat getting into Bundestag
    from RankedSeatsPerParty
    where seatnumberTotal <= (SELECT * from TotalNumberOfSeats) --select the seats, which are in Bundestag
    group by pid
),

---------------- STEP 4: final number of Seats per Landesliste ----------------
-- creates the seat ranking for each Landesliste and within its Party based on Zweitstimmen
RankedSeatsPerLandesliste2 (llid, seatnumberInParty, seatnumberLL) AS (
    WITH RECURSIVE Factors(fsid, f) AS (
        (select fsid, 0.5 from federalstate)
        UNION ALL
        SELECT fsid, f + 1
        FROM Factors f
        WHERE f < (select max(seats)+20 from SeatsPerFederalState spfs where spfs.fsid = f.fsid)
    )

    SELECT ll.llid,
        rank()  OVER (Partition by p.pid Order by azfs.votes/f.f desc) as seatnumberInParty,        --rank within Party
        rank()  OVER (Partition by p.pid, ll.llid Order by azfs.votes/f.f desc) as seatnumberInLL   --rank within Landesliste
    FROM PartiesBeyondFivePercent p -- pid votes
    NATURAL JOIN LandesListe ll
    INNER JOIN AggregatedZweitstimmenForLL azfs ON azfs.llid = ll.llid
    INNER JOIN Factors f ON f.fsid = ll.fsid
    WHERE ll.year = 2013
),

-- removes the seats used by Direktkandidaturen and re-ranks the remaining seats by the number within the Party
RemainingRankedSeatsPerLandesliste (llid, seatnumberInParty) AS (
    SELECT rspll.llid,
    rank()  OVER (Partition by ll.pid  Order by rspll.seatnumberInParty asc) as seatnumberInParty       --rerank the remaining seats
    FROM RankedSeatsPerLandesliste2 rspll
    JOIN Landesliste ll ON ll.llid=rspll.llid
    Left Outer JOIN WahlkreisesiegePerPartyPerFS wkspll ON wkspll.pid=ll.pid and wkspll.fsid=ll.fsid
    where rspll.seatnumberLL > coalesce(wkspll.seats,0)                         --remove seats won by Direktkandidaturen
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
    FROM Landesliste ll
    LEFT OUTER JOIN WahlkreisesiegePerPartyPerFS wkspll ON ll.pid = wkspll.pid AND ll.fsid = wkspll.fsid
    LEFT OUTER JOIN AdditionalSeatsToDirektmandatePerLandeliste astdkpll ON ll.llid = astdkpll.llid
    WHERE ll.year = 2013 AND ll.pid in (select pid from PartiesBeyondFivePercent) AND (coalesce(wkspll.seats,0)+coalesce(astdkpll.seats,0)) >0
),

---------------- STEP 5: List of Delegates for Bundestag ----------------
--unions the Direktkandidaturen with the Listenplätzen
 MergedCandidates (idno, fsid, pid, wkid, rank) AS (
    (select wks.idno, wk.fsid, wks.pid, wk.wkid, 0 as position      -- 0 to come before the Landeslistenplätze (which start with 1)
     from WahlkreisWinners wks
     NATURAL JOIN Wahlkreis wk)
    UNION
    (select c.idno, ll.fsid, ll.pid, NULL as wkid,llp.position as rank
     from Candidates c
     NATURAL JOIN Landeslistenplatz llp
     NATURAL JOIN Landesliste ll
     WHERE ll.year = 2013 AND ll.pid in (select pid from PartiesBeyondFivePercent)
           AND  not exists (select * from WahlkreisWinners wks where wks.idno = c.idno) -- remove Landeslistenplätze which won a Direktmandat
     )
 ),

--ranks the unioned Candidates
MergedRankedCandidates (idno, fsid, pid, wkid,  rank)  AS (
    SELECT mc.idno, mc.fsid,  mc.pid, mc.wkid,
           rank() OVER (Partition by mc.fsid, mc.pid Order by mc.rank asc) as rank      --re-rank to match with number of seats, (all Direktmandate have rank 0 from MergedCandidates)
    FROM MergedCandidates mc
),

-- selecte the Candidates which get a seat in Bundestag --> RESULT STEP 5
Delegates (idno, fsid, pid, wkid, rankInFS) AS (
    SELECT mrc.idno, mrc.fsid, mrc.pid, mrc.wkid, mrc.rank
    FROM MergedRankedCandidates mrc
    LEFT OUTER JOIN Landesliste ll ON mrc.fsid = ll.fsid AND mrc.pid=ll.pid
    NATURAL JOIN SeatsPerLandesliste spll
    WHERE mrc.pid is NULL or spll.seats >= rank                     --take only candidates who have ll-rank <= ll-number of seats
)

------------------------------ TESTING ------------------------------
---------- STEP 1: Seats per Federalstate ----------
----Ranked Seats
-- select fs.name, rspfs.seatnumber
-- FROM RankedSeatsperFederalState rspfs
-- NATURAL JOIN FederalState fs
-- ORDER BY rspfs.seatnumber

----Seats per fs
-- SELECT fs.name, spfs.seats
-- from SeatsPerFederalstate spfs
-- NATURAL JOIN FederalState fs
-- ORDER BY fs.fsid

---------------- STEP 2: Seats per Landesliste for each Federalstate ----------------
----Ranked seats
-- SELECT rspll.seatnumber, fs.name, p.name
-- FROM RankedSeatsPerLandesliste rspll
-- NATURAL JOIN Landesliste ll
-- NATURAL JOIN Federalstate fs
-- JOIN Party p on ll.pid = p.pid
-- WHERE fs.name='Thüringen'

----Number of Seats per Landesliste
-- SELECT spllpzw.seats, fs.name, p.name
-- FROM SeatsPerLandelisteByZweitstimme spllpzw
-- NATURAL JOIN Landesliste ll
-- NATURAL JOIN Federalstate fs
-- JOIN Party p on ll.pid = p.pid
-- WHERE fs.name='Thüringen'
-- ORDER BY spllpzw.seats desc

---------------- STEP ZWISCHENERGEBNIS: minimum Number of Seats per Party ----------------
---Minimum seats per Party per Federalstate
-- SELECT mspppf.minSeats, fs.name, p.name
-- FROM MinimumSeatsPerPartyPerFederalstate mspppf
-- NATURAL JOIN Landesliste ll
-- NATURAL JOIN Federalstate fs
-- JOIN Party p on ll.pid = p.pid
-- WHERE fs.name='Thüringen'

----Minimum seats per Party in Bundestag
-- SELECT mspp.minSeats, p.name
-- FROM MinimumSeatsPerParty mspp
-- NATURAL JOIN Party p


---------------- STEP 3: final number of Seats per Party ----------------

----ranked Seats in Bundestag, total and in Party
-- SELECT p.name, rspp.seatnumberTotal, rspp.seatnumberParty
-- FROM RankedSeatsPerParty rspp
-- NATURAL JOIN Party p
-- ORDER BY rspp.seatnumberTotal

----total number of seats in Bundestag for Party
-- SELECT p.name, tnospp.seats
-- FROM TotalNumberOfSeatsPerParty tnospp
-- NATURAL JOIN Party p
-- ORDER BY tnospp.seats desc


---------------- STEP 4: final number of Seats per Landesliste ----------------
----ranks seats fro each Landesliste within Party and LL
-- SELECT fs.name, p.name, rspll.seatnumberInParty, rspll.seatnumberLL
-- FROM RankedSeatsPerLandesliste2 rspll
-- NATURAL JOIN Landesliste ll
-- NATURAL JOIN Federalstate fs
-- JOIN Party p on ll.pid = p.pid
-- WHERE fs.name='Thüringen' AND p.name='CDU'

----total number of seats per Landesliste
-- SELECT fs.name, p.name, spll.seats
-- FROM SeatsPerLandesliste spll
-- NATURAL JOIN Landesliste ll
-- NATURAL JOIN Federalstate fs
-- JOIN Party p on ll.pid = p.pid
-- WHERE p.name='CDU'

---------------- STEP 5: List of Delegates for Bundestag ----------------
SELECT  c.Lastname, c.Firstname, p.name AS party, fs.name AS federalstate, d.rankInFS
FROM Delegates d
NATURAL JOIN Candidates c
NATURAL JOIN Federalstate fs
JOIN Party p ON p.pid=d.pid
WHERE p.name='CDU'
ORDER BY c.Lastname, c.Firstname





