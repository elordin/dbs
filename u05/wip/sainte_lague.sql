WITH RECURSIVE
    AggegratedVotesZS(pid, votes, year) AS (
    VALUES
        (1, 100, 2013),
        (2, 150, 2013),
        (3, 10, 2013)
    ),
    PartiesToConsider(pid, votes) AS (
        SELECT a1.pid, a1.votes
        FROM AggegratedVotesZS a1 JOIN AggegratedVotesZS a2 ON a1.year = a2.year
        GROUP BY a1.pid, a1.votes
        HAVING a1.votes > SUM(a2.votes) * 0.05
    ),
    Factors(f) AS (
        VALUES (0.5)
        UNION
        SELECT f + 1
        FROM Factors
        WHERE f < (300 * (SELECT 1.000 * MAX(votes) / SUM(votes) FROM PartiesToConsider))
    )

SELECT pid, COUNT(quotient)
FROM (
    SELECT az.pid, az.votes / f.f AS quotient
      FROM PartiesToConsider az, Factors f
      ORDER BY quotient DESC
      LIMIT 299) r
GROUP BY pid;
