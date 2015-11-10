WITH RECURSIVE
    Factors(f) AS (
        VALUES (0.5)
        UNION
        SELECT f + 1
        FROM Factors
        WHERE f < 299
    ),
    AggegratedVotesZS(pid, votes) AS (
    VALUES
        (1, 100),
        (2, 100),
        (3, 100)
    )

SELECT pid, COUNT(product)
FROM (SELECT az.pid, az.votes * f.f AS product
      FROM AggegratedVotesZS az, Factors f
      ORDER BY product DESC
      LIMIT 299) r
GROUP BY pid;
