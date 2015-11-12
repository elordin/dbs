WITH RECURSIVE
    AggegratedVotesZS (year, pid, votes) AS (
        SELECT year, pid, SUM(votes)
        FROM AccumulatedZweitstimmenFS NATURAL JOIN LandesListe
        GROUP BY year, pid
    ),
    -- Victors per Wahlkreis
        -- Disregards decision by lot when two candidates have the exact same number of votes.
    WahlkreisSieger AS (
        SELECT wk.wkid, c1.idno, c1.supportedby
        FROM Wahlkreis wk NATURAL JOIN Candidacy c1 INNER JOIN Candidacy c2 ON c1.wkid = c2.wkid
        WHERE wk.year = @year
        GROUP BY wk.wkid, c1.idno, c1.supportedby, c1.votes
        HAVING c1.votes = MAX(c2.votes)
        LIMIT 1
    ),

    DirektmandatePerParty(pid, mandate) AS (
        SELECT supportedby AS pid, COUNT(wkid) AS mandate
        FROM WahlkreisSieger
        WHERE supportedby IS NOT NULL
        GROUP BY supportedby
    ),

    -- Parties that managed to have more than 5% or more than 3 Direktmandate or are Minority Parties
    PartiesBeyondFivePercent(pid, votes) AS (
        SELECT a1.pid, a1.votes
        FROM Party p NATURAL JOIN AggegratedVotesZS a1 JOIN AggegratedVotesZS a2 ON a1.year = a2.year
        GROUP BY a1.pid, a1.votes, p.isminority
        HAVING a1.votes > 0
           AND p.isminority -- minority parties are exempted from 5% threshold
            OR a1.votes > SUM(a2.votes) * 0.05
            OR 2 < (SELECT COUNT(DISTINCT wkid)
                    FROM WahlkreisSieger
                    WHERE supportedby = a1.pid)
    ),

    SeatCount(n) AS (
        VALUES (598)
    UNION ALL
        SELECT n + 1
        FROM SeatCount
        WHERE (
                WITH RECURSIVE
                    Factors(f) AS (
                        VALUES (0.5)
                        UNION ALL
                        SELECT f + 1
                        FROM Factors
                        WHERE f < (n * (SELECT 1.250 * MAX(votes) / SUM(votes)
                                                 FROM PartiesBeyondFivePercent))
                    ),

                    -- Seat Distribution for 598 seats using Sainte Lague
                    RegularDistribution(pid, mandate) AS (
                        SELECT pid, COUNT(quotient) AS mandate
                        FROM (
                            SELECT az.pid, az.votes / f.f AS quotient
                              FROM PartiesBeyondFivePercent az, Factors f
                              ORDER BY quotient DESC
                              LIMIT 598) r
                        GROUP BY pid
                    ),

                    UnausgeglicheneUeberhangsmandate(pid, uhms) AS (
                        SELECT rd.pid, dm.mandate - rd.mandate AS uhms
                        FROM RegularDistribution rd INNER JOIN DirektmandatePerParty dm ON rd.pid = dm.pid
                        WHERE rd.mandate < dm.mandate
                    )
                -- SELECT 1 > ALL(SELECT uhms FROM UnausgeglicheneUeberhangsmandate)
                SELECT NOT 0 <  ANY(SELECT uhms FROM UnausgeglicheneUeberhangsmandate)
    )

    Factors(f) AS (
        VALUES (0.5)
        UNION ALL
        SELECT f + 1
        FROM Factors
        WHERE f < ((SELECT MAX(n) FROM SeatCount) * (SELECT 1.250 * MAX(votes) / SUM(votes)
                                 FROM PartiesBeyondFivePercent))
    ),


    Distribution AS (
        SELECT pid, COUNT(quotient) AS mandate
        FROM (
            SELECT az.pid, az.votes / f.f AS quotient
              FROM PartiesBeyondFivePercent az, Factors f
              ORDER BY quotient DESC
              LIMIT (SELECT MAX(n) FROM SeatCount)) r
        GROUP BY pid
    ),

    LandesListenSitze(pid, mandate) AS (
        SELECT d.pid, d.mandate - dm.mandate mandate
        FROM Distribution d INNER JOIN DirektmandatePerParty dm ON rd.pid = dm.pid
        WHERE rd.mandate < dm.mandate
    ),

    -- DISTRIBUTE LandesListenSitze OVER FederalStates

    -- SELECT LandesListenPlätze LIMIT BY LandesListenSitzePerFederalState
  UNION ALL
    SELECT idno, pid
    FROM WahlkreisSieger
    -- ... JOIN Candidate Names, Landeslisten etc.

-- SELECT *
-- FROM SeatCount
