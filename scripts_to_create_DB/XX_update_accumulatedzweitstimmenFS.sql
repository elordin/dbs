WITH ACCZWWK (llid, votes) AS (
    select llid, sum(votes)
    from AccumulatedZweitstimmenWK azwwk
    group by llid
)

update accumulatedzweitstimmenfs
set votes = ACCZWWK.votes
from ACCZWWK
where accumulatedzweitstimmenfs.llid = ACCZWWK.llid;
