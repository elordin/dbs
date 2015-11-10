WITH RECURSIVE
    Factors(f) AS (
        VALUES (0.5)
        UNION
        SELECT f + 1
        FROM Factors
        WHERE f < 299
    ),
    AggegratedVotesZS(pid, votes, year) AS (
    VALUES
        (1, 100, 2013),
        (2, 100, 2013),
        (3, 10, 2013)
    ),
    PartiesToConsider(pid, votes) AS (
        SELECT a1.pid, a1.votes
        FROM AggegratedVotesZS a1 JOIN AggegratedVotesZS a2 ON a1.year = a2.year
        GROUP BY a1.pid, a1.votes
        HAVING a1.votes > SUM(a2.votes) * 0.05
    )

SELECT pid, COUNT(product)
FROM (SELECT az.pid, az.votes * f.f AS product
      FROM PartiesToConsider az, Factors f
      ORDER BY product DESC
      LIMIT 299) r
GROUP BY pid;
