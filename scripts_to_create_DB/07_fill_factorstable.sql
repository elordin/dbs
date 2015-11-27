WITH RECURSIVE Factors2(f) AS (
    Values(0.5)
    UNION ALL
    (SELECT f.f + 1
    FROM Factors2 f
    WHERE f.f < 598
    )
)

INSERT INTO Factors
SELECT f
FROM Factors2

-- DROP TABLE Factors;




