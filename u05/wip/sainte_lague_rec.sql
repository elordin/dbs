WITH RECURSIVE

Sitze(n, cond, pid, mandates) AS (

    WITH RECURSIVE
        -- Required for Sainte Lague Calculation
        -- RECURSIVE
        Factors(f) AS (
            VALUES (0.5)
            UNION ALL
            SELECT f + 1
            FROM Factors
            WHERE f < (598 * (SELECT 1.25 * MAX(votes) / SUM(votes)
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
        UnausgeglicheneUeberhangsmandate AS (
            SELECT pid, wk.mandate - rd.mandate AS uhms
            FROM RegularDistribution rd INNER JOIN (
                    SELECT supportedby AS pid, COUNT(wkid) AS mandate
                    FROM WahlkreisSieger
                    WHERE supportedby IS NOT NULL
                    GROUP BY supportedby
                ) wk ON rd.pid = wk.pid
            WHERE rd.mandate < wk.mandate
        )

    SELECT 598,
          (SELECT 1 > ALL(SELECT uhms FROM UnausgeglicheneUeberhangsmandate)),
          rd.pid, rd.mandate
    FROM RegularDistribution rd LEFT JOIN UnausgeglicheneUeberhangsmandate u
      ON rd.pid = u.pid

UNION ALL


    SELECT n + 1, Tmp.cond, Tmp.pid, Tmp.mandates
    FROM Sitze JOIN (
        WITH RECURSIVE
            Factors(f) AS (
                VALUES (0.5)
                UNION ALL
                SELECT f + 1
                FROM Factors
                WHERE f < ((n + 1) * (SELECT 1.25 * MAX(votes) / SUM(votes)
                                         FROM PartiesBeyondFivePercent))
            ),
            RegularDistribution(pid, mandate) AS (
                SELECT pid, COUNT(quotient) AS mandate
                FROM (
                    SELECT az.pid, az.votes / f.f AS quotient
                      FROM PartiesBeyondFivePercent az, Factors f
                      ORDER BY quotient DESC
                      LIMIT (n + 1)) r
                GROUP BY pid;
            ),
            UnausgeglicheneUeberhangsmandate(pid, uhms) AS (
                SELECT pid, wk.mandate - rd.mandate AS uhms
                FROM RegularDistribution rd INNER JOIN (
                        SELECT supportedby AS pid, COUNT(wkid) AS mandate
                        FROM WahlkreisSieger
                        WHERE supportedby IS NOT NULL
                        GROUP BY supportedby
                    ) wk ON rd.pid = wk.pid
                WHERE rd.mandate < wk.mandate
            )
        SELECT (n + 1),
          (SELECT 1 > ALL(SELECT uhms FROM UnausgeglicheneUeberhangsmandate)),
          rd.pid, rd.mandate
        FROM RegularDistribution rd LEFT JOIN UnausgeglicheneUeberhangsmandate u
            ON rd.pid = u.pid
    ) ON Sitze.pid = Tmp.pid
    WHERE Sitze.cond


--    SELECT n + 1, SUM(uhm) = 0, v1, v2
--    FROM T
--    WHERE cond
)
SELECT pid, mandates
FROM Sitze
WHERE cond
