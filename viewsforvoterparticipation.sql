CREATE OR REPLACE VIEW Results_VoterparticipationPerWK_Current(wkid, elective, voted) AS
(
	WITH Results_NumberOfElectivesPerWK(wkid, sum) AS (
		SELECT wk.wkid, count(*) as sum
		FROM Citizenregistration cr
		JOIN Direktwahlbezirk dwb ON cr.dwbid = dwb.dwbid
		JOIN Wahlkreis wk ON dwb.wkid = wk.wkid
		WHERE wk.year= (select year from electionyear where iscurrent=true)
		GROUP BY wk.wkid
	),

	Results_NumberOfVotesPerWK(wkid, sum) AS (
		SELECT wk.wkid, count(*) as sum
		FROM hasvoted hv
		JOIN Citizenregistration cr ON hv.idno = cr.idno
		JOIN Direktwahlbezirk dwb ON cr.dwbid = dwb.dwbid
		JOIN Wahlkreis wk ON dwb.wkid = wk.wkid
		WHERE hv.year= (select year from electionyear where iscurrent=true) AND wk.year= (select year from electionyear where iscurrent=true)
		GROUP BY wk.wkid
	)
	SELECT rnoe.wkid, rnoe.sum, rnov.sum
	FROM Results_NumberOfElectivesPerWK rnoe
	JOIN Results_NumberOfVotesPerWK rnov ON rnoe.wkid=rnoe.wkid
);

CREATE TABLE IF NOT EXISTS Results_VoterparticipationPerWK_Old (
	year INT NOT NULL REFERENCES ElectionYear(year) ON DELETE CASCADE,
	wkid INT REFERENCES Wahlkreis(wkid),
	elective INT NOT NULL DEFAULT 0,
	voted INT NOT NULL DEFAULT 0
);

CREATE OR REPLACE VIEW Results_VoterparticipationPerWK  (year, wkid, elective, voted) AS (
	SELECT *
	FROM Results_VoterparticipationPerWK_Old 
	UNION ALL
	SELECT (select year from electionyear where iscurrent=true) as year, r.*
	FROM Results_VoterparticipationPerWK_Current r
);

CREATE OR REPLACE VIEW Results_View_Results_View_WahlkreisOverview_Voterparticipation (year, wkid, wk_name, elective, voted, participationrate) AS (
	SELECT rvppwk.year, rvppwk.wkid, wk.name, rvppwk.elective, rvppwk.voted, ((rvppwk.voted*1.0)/(rvppwk.elective*1.0))*100.0 as participationrate
	FROM Results_VoterparticipationPerWK rvppwk
	JOIN Wahlkreis wk ON wk.wkid = rvppwk.wkid
);



