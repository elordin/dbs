-- Victors per Wahlkreis
    -- Disregards decision by lot when two candidates have the exact same number of votes.
WahlkreisSieger AS (
    SELECT wk.wkid, c1.idno, c1.supportedby
    FROM Wahlkreis wk NATURAL JOIN Candidacy c1 INNER JOIN Candidacy c2 ON c1.wkid = c2.wkid
    WHERE wk.year = @year
    GROUP BY wk.wkid, c1.idno, c1.supportedby, c1.votes
    HAVING c1.votes = MAX(c2.votes)
    -- LIMIT 1
),

-- Parties that managed to have more than 5% or more than 3 Direktmandate or are Minority Parties
PartiesBeyondFivePercent(pid, votes) AS (
    SELECT a1.pid, a1.votes
    FROM Party p NATURAL JOIN AggegratedVotesZS a1 JOIN AggegratedVotesZS a2 ON a1.year = a2.year
    GROUP BY a1.pid, a1.votes, p.isminority
    HAVING p.isminority -- minority parties are exempted from 5% threshold
        OR a1.votes > SUM(a2.votes) * 0.05
        OR 2 < (SELECT COUNT(DISTINCT wkid)
                FROM WahlkreisSieger
                WHERE supportedby = a1.pid)
),

-- Required for Sainte Lague Calculation
-- RECURSIVE
Factors(f) AS (
    VALUES (0.5)
    UNION ALL
    SELECT f + 1
    FROM Factors
    WHERE f < (@seatcount * (SELECT 1.000 * MAX(votes) / SUM(votes)
                             FROM PartiesBeyondFivePercent))
),

-- Seat Distribution for 598 seats using Sainte Lague
RegularDistribution AS (
    SELECT pid, COUNT(quotient) AS mandate
    FROM (
        SELECT az.pid, az.votes / f.f AS quotient
          FROM PartiesBeyondFivePercent az, Factors f
          ORDER BY quotient DESC
          LIMIT 598) r
    GROUP BY pid;
),

-- Überhangsmandate
Ueberhangsmandate AS (
    SELECT pid, wk.mandate - rd.mandate AS uhms
    FROM RegularDistribution rd INNER JOIN (
            SELECT supportedby AS pid, COUNT(wkid) AS mandate
            FROM WahlkreisSieger
            WHERE supportedby IS NOT NULL
            GROUP BY supportedby
        ) wk ON rd.pid = wk.pid
    WHERE rd.mandate < wk.mandate
),

MandateMitUerberhang AS (
    SELECT rd.pid, rd.mandate + COALESCE(uhms, 0) AS Mandate
    FROM RegularDistribution rd LEFT OUTER JOIN Ueberhangsmandate um
        ON rd.pid = um.pid
),

AusgleichRequired AS (
    SELECT 0 = ALL(SELECT uhms FROM Ueberhangsmandate)
    -- SELECT 0 < ANY(SELECT rd.mandate = mmu.mandate
    --                FROM RegularDistribution rd INNER JOIN MandateMitUerberhang mmu
    --                     ON rd.pid = mmu.pid)
),

WHILE AusgleichRequired
    SITZZAHL++
    Berechne Neu: RegularDistribution, MandateMitUerberhang

-- UNION ALL FOREACH Party
--     Landeslistensitze = Zweitstimmensitze - Direktmandate
--     Divide Landeslistensitze By Federal State (ignoring certain votes, see §BWG Abs 1)
--     UNION ALL FOREACH FederalState
--         SELECT idno, pid
--         FROM LandesListe
--         WHERE NOT IN WahlkreisSieger
--         LIMIT Sitze_fsid
-- UNION
--   SELECT idno, supportedby AS pid
--   FROM WahlkreisSieger
