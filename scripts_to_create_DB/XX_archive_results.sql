INSERT INTO Results_AggregatedZweitstimmenForLL_Old
SELECT (select year from electionyear where iscurrent=true) as year, r.*
	FROM Results_AggregatedZweitstimmenForLL_Current r;

INSERT INTO Results_RankedCandidatesFirstVotes_Old
SELECT (select year from electionyear where iscurrent=true) as year, r.*
	FROM Results_RankedCandidatesFirstVotes_Current r;

INSERT INTO Results_WahlkreisWinnersFirstVotes_Old
SELECT (select year from electionyear where iscurrent=true) as year, r.*
	FROM Results_WahlkreisWinnersFirstVotes_Current r;

INSERT INTO Results_PartiesQualified_Old
SELECT (select year from electionyear where iscurrent=true) as year, r.*
	FROM Results_PartiesQualified_Current r;

INSERT INTO Results_AggregatedZweitstimmenForLLQualified_Old
SELECT (select year from electionyear where iscurrent=true) as year, r.*
	FROM Results_AggregatedZweitstimmenForLLQualified_Current r;

INSERT INTO Results_WahlkreisesiegePerPartyPerFS_Old
SELECT (select year from electionyear where iscurrent=true) as year, r.*
	FROM Results_WahlkreisesiegePerPartyPerFS_Current r;

INSERT INTO Results_SeatsPerFederalState_Old
SELECT (select year from electionyear where iscurrent=true) as year, r.*
	FROM Results_SeatsPerFederalState_Current r;

INSERT INTO Results_FVandSVSeatsPerPartyPerFederalstate_Old
SELECT (select year from electionyear where iscurrent=true) as year, r.*
	FROM Results_FVandSVSeatsPerPartyPerFederalstate_Current r;

INSERT INTO Results_SeatsPerLandesliste_Old
SELECT (select year from electionyear where iscurrent=true) as year, r.*
	FROM Results_SeatsPerLandesliste_Current r;

INSERT INTO Results_Delegates_Old
SELECT (select year from electionyear where iscurrent=true) as year, r.*
	FROM Results_Delegates_Current r;

INSERT INTO Results_TotalNumberOfSeatsPerParty_Old
SELECT (select year from electionyear where iscurrent=true) as year, r.*
	FROM Results_TotalNumberOfSeatsPerParty_Current r;

INSERT INTO Results_NarrowWahlkreisWinsAndLosings_Old
SELECT (select year from electionyear where iscurrent=true) as year, r.*
	FROM Results_NarrowWahlkreisWinsAndLosings_Current r;

INSERT INTO Results_VoterparticipationPerWK_Old
SELECT (select year from electionyear where iscurrent=true) as year, r.*
	FROM Results_VoterparticipationPerWK_Current r;

