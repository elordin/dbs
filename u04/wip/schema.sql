-- DROP MATERIALIZED VIEW IF EXISTS ResultsZweitstimme  CASCADE;
-- DROP MATERIALIZED VIEW IF EXISTS ResultsErststimme   CASCADE;
-- DROP TABLE IF EXISTS ResultsErststimmeManualArchive  CASCADE;
-- DROP TABLE IF EXISTS ResultsZweitstimmeManualArchive CASCADE;
-- DROP TABLE IF EXISTS CitizenRegistration             CASCADE;
-- DROP VIEW  IF EXISTS Stimmzettel                     CASCADE;
-- DROP TABLE IF EXISTS StimmzettelData                 CASCADE;
-- DROP VIEW  IF EXISTS Wahlschein                      CASCADE;
-- DROP TABLE IF EXISTS WahlscheinData                  CASCADE;
-- DROP TABLE IF EXISTS Vote                            CASCADE;
-- DROP TABLE IF EXISTS Candidacy                       CASCADE;
-- DROP TABLE IF EXISTS PartyMembership                 CASCADE;
-- DROP TABLE IF EXISTS Landeslistenplatz               CASCADE;
-- DROP TABLE IF EXISTS Landesliste                     CASCADE;
-- DROP VIEW  IF EXISTS BriefWahlBezirk                 CASCADE;
-- DROP TABLE IF EXISTS BriefWahlBezirkData             CASCADE;
-- DROP VIEW  IF EXISTS DirektWahlBezirk                CASCADE;
-- DROP TABLE IF EXISTS DirektWahlBezirkData            CASCADE;
-- DROP TABLE IF EXISTS Wahlbezirk                      CASCADE;
-- DROP TABLE IF EXISTS Wahlkreis                       CASCADE;
-- DROP TABLE IF EXISTS Party                           CASCADE;
-- DROP VIEW  IF EXISTS Candidates                      CASCADE;
-- DROP TABLE IF EXISTS CandidatesData                  CASCADE;
-- DROP TABLE IF EXISTS hasVoted                        CASCADE;
-- DROP TABLE IF EXISTS Citizen                         CASCADE;
-- DROP TABLE IF EXISTS ElectionYear                    CASCADE;
-- DROP TABLE IF EXISTS FederalState                    CASCADE;

CREATE TABLE IF NOT EXISTS FederalState (
    fsid SERIAL PRIMARY KEY,
    name VARCHAR(255) UNIQUE NOT NULL,
    outline POLYGON
);

-- voting system?
CREATE TABLE IF NOT EXISTS ElectionYear (
    year INT PRIMARY KEY
);

CREATE TABLE IF NOT EXISTS Citizen (
    idno VARCHAR(32) PRIMARY KEY,
    title VARCHAR(63) NOT NULL DEFAULT '',
    firstname VARCHAR(255) NOT NULL,
    lastname VARCHAR(255) NOT NULL,
    dateofbirth DATE NOT NULL,
    gender CHAR NOT NULL,
    CHECK (gender in ('m', 'f', 'p')),
    canvote BOOLEAN NOT NULL DEFAULT true,
    authtoken VARCHAR(255)
);

CREATE TABLE IF NOT EXISTS hasVoted (
    year INT NOT NULL REFERENCES ElectionYear(Year) ON DELETE CASCADE,
    idno VARCHAR(255) NOT NULL REFERENCES Citizen(idno) ON DELETE CASCADE,
    hasvoted BOOLEAN NOT NULL DEFAULT true,
    PRIMARY KEY (year, idno)
);

CREATE TABLE IF NOT EXISTS CandidatesData (
    idno VARCHAR(32) PRIMARY KEY REFERENCES Citizen(idno) ON DELETE CASCADE
);


CREATE OR REPLACE VIEW Candidates AS (
    SELECT *
    FROM CandidatesData NATURAL JOIN Citizen
);

CREATE TABLE IF NOT EXISTS Party (
    pid SERIAL PRIMARY KEY,
    name VARCHAR(255) UNIQUE NOT NULL,
    shorthand VARCHAR(32) UNIQUE NOT NULL,
    website VARCHAR(255) NOT NULL DEFAULT '',
    colourcode VARCHAR(15) NOT NULL,
    isminority BOOLEAN NOT NULL DEFAULT false
);

CREATE TABLE IF NOT EXISTS Wahlkreis (
    wkid SERIAL PRIMARY KEY,
    wknr INT NOT NULL,
    name VARCHAR(255) NOT NULL,
    outline POLYGON,
    fsid INT NOT NULL REFERENCES FederalState(fsid) ON DELETE CASCADE,
    year INT NOT NULL REFERENCES ElectionYear(year) ON DELETE CASCADE,
    UNIQUE (wknr, year)
);

CREATE TABLE IF NOT EXISTS Wahlbezirk (
    wbid INT PRIMARY KEY,
    wkid INT NOT NULL REFERENCES Wahlkreis(wkid) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS DirektWahlBezirkData (
    dwbid INT PRIMARY KEY,
    wbid INT NOT NULL REFERENCES Wahlbezirk(wbid) ON DELETE CASCADE
);

CREATE OR REPLACE VIEW DirektWahlBezirk AS (
    SELECT *
    FROM Wahlbezirk NATURAL JOIN DirektWahlBezirkData
);

CREATE TABLE IF NOT EXISTS BriefWahlBezirkData (
    bwbid INT PRIMARY KEY,
    wbid INT NOT NULL REFERENCES Wahlbezirk(wbid) ON DELETE CASCADE
);

CREATE OR REPLACE VIEW BriefWahlBezirk AS (
    SELECT *
    FROM Wahlbezirk NATURAL JOIN BriefWahlBezirkData
);

CREATE TABLE IF NOT EXISTS LandesListe (
    llid SERIAL PRIMARY KEY,
    year INT NOT NULL REFERENCES ElectionYear(year) ON DELETE CASCADE,
    pid INT NOT NULL REFERENCES Party(pid) ON DELETE CASCADE,
    fsid INT NOT NULL REFERENCES FederalState(fsid) ON DELETE CASCADE,
    votes INT NOT NULL DEFAULT 0
);

CREATE TABLE IF NOT EXISTS Landeslistenplatz (
    llid INT NOT NULL REFERENCES LandesListe(llid) ON DELETE CASCADE,
    idno VARCHAR(32) NOT NULL REFERENCES CandidatesData(idno) ON DELETE CASCADE,
    position INT NOT NULL,
    UNIQUE (llid, position),
    PRIMARY KEY (llid, idno)
);

CREATE TABLE IF NOT EXISTS PartyMembership (
    pid INT NOT NULL REFERENCES Party(pid) ON DELETE CASCADE,
    idno VARCHAR(32) NOT NULL REFERENCES CandidatesData(idno) ON DELETE CASCADE,
    PRIMARY KEY (pid, idno)
);

CREATE TABLE IF NOT EXISTS Candidacy (
    -- CID to reference from Vote using a single value rather than the two value FK (wkid, idno)
    cid SERIAL PRIMARY KEY,
    wkid INT NOT NULL REFERENCES Wahlkreis(wkid) ON DELETE CASCADE,
    idno VARCHAR(255) NOT NULL REFERENCES CandidatesData(idno) ON DELETE CASCADE,
    supportedby INT REFERENCES Party(pid) ON DELETE SET NULL,
    votes INT NOT NULL DEFAULT 0
    -- EXISTS (SELECT *
    --         FROM PartyMembership
    --         WHERE PartyMembership.idno = Candidacy.idno
    --           AND PartyMembership.pid  = Candidacy.supportedby),
    -- NOT EXISTS (SELECT *
    --             FROM PartyMembership
    --             WHERE PartyMembership.idno = Candidacy.idno
    --               AND PartyMembership.pid <> Candidacy.supportedby),
    UNIQUE (wkid, idno)
);

-- CREATE CONSTRAINT TRIGGER members_only { BEFORE INSERT OR BEFORE UPDATE OF idno, supportedby }
-- ON Candidacy
-- WHEN (NOT EXISTS (SELECT *
--                   FROM PartyMembership
--                   WHERE PartyMembership.idno = NEW.idno
--                     AND PartyMembership.pid  = NEW.supportedby))
-- EXECUTE PROCEDURE throw new IntegrityViolationError;

-- CREATE CONSTRAINT TRIGGER max_support { BEFORE INSERT OR BEFORE UPDATE OF supportedby }
-- ON Candidacy
-- WHEN (EXISTS (SELECT *
--                   FROM PartyMembership
--                   WHERE PartyMembership.idno = NEW.idno
--                     AND PartyMembership.pid <> NEW.supportedby))
-- EXECUTE PROCEDURE throw new IntegrityViolationError;

-- SAME YEAR CONSTRAINT?
CREATE TABLE IF NOT EXISTS Vote (
    vid SERIAL PRIMARY KEY,
    gender CHAR NOT NULL,
    CHECK (gender in ('m', 'f')),
    age INT NOT NULL,
    CHECK (age >= 18),
    CHECK (age < 150),
    erststimme INT REFERENCES Candidacy(cid) ON DELETE SET NULL,
    zweitstimme INT REFERENCES LandesListe(llid) ON DELETE SET NULL
    -- CHECK (SELECT year
    --        FROM Candidacy NATURAL JOIN Wahlkreis
    --        WHERE Candidacy.cid = Vote.erststimme)
    --     =
    --       (SELECT year
    --        FROM LandesListe
    --        WHERE Landesliste.llid = Vote.zweitstimme)
);

CREATE TABLE IF NOT EXISTS WahlscheinData (
    vid INT PRIMARY KEY REFERENCES Vote(vid) ON DELETE CASCADE,
    bwbid INT NOT NULL REFERENCES BriefWahlBezirkData(bwbid) ON DELETE CASCADE,
    issuedon DATE NOT NULL
);

CREATE OR REPLACE VIEW Wahlschein AS (
    SELECT *
    FROM Vote NATURAL JOIN WahlscheinData
);

CREATE TABLE IF NOT EXISTS StimmzettelData (
    vid INT PRIMARY KEY REFERENCES Vote(vid) ON DELETE CASCADE,
    dwbid INT NOT NULL REFERENCES DirektWahlBezirkData(dwbid) ON DELETE CASCADE
);

CREATE OR REPLACE VIEW Stimmzettel AS (
    SELECT *
    FROM Vote NATURAL JOIN StimmzettelData
);

CREATE TABLE IF NOT EXISTS CitizenRegistration (
    idno VARCHAR(32) NOT NULL REFERENCES Citizen(idno),
    dwbid INT NOT NULL REFERENCES DirektWahlBezirkData(dwbid),
    PRIMARY KEY (idno, dwbid)
);


-- Election Results

CREATE FUNCTION incLandeliste(zweitstimme INT) AS (
    UPDATE TABLE Landesliste
    SET votes = votes + 1
    WHERE Landesliste.llid = zweitstimme
);

CREATE FUNCTION decLandeliste(zweitstimme INT) AS (
    UPDATE TABLE Landesliste
    SET votes = votes - 1
    WHERE Landesliste.llid = zweitstimme
);

CREATE FUNCTION incCandidacy(erststimme INT) AS (
    UPDATE TABLE Candidacy
    SET votes = votes + 1
    WHERE Candidacy.cid = erststimme
);

CREATE FUNCTION decCandidacy(zweitstimme INT) AS (
    UPDATE TABLE Candidacy
    SET votes = votes - 1
    WHERE Candidacy.cid = zweitstimme;
);

CREATE FUNCTION shiftVoteCandidacy(from INT, to INT) AS (
    decCandidacy(from);
    incCandidacy(to);
);

CREATE FUNCTION shiftVoteLandeliste(from INT, to INT) AS (
    decLandeliste(from);
    incLandeliste(to);
);

CREATE TRIGGER insertVoteToLandesliste
AFTER INSERT ON Vote
EXECUTE PROCEDURE incLandeliste(NEW.zweitstimme);

CREATE TRIGGER updateVoteToLandesliste
AFTER UPDATE ON Vote
EXECUTE PROCEDURE shiftVoteLandeliste(OLD.zweitstimme, NEW.zweitstimme)

CREATE TRIGGER insertVoteToCandidacy
AFTER INSERT ON Vote
EXECUTE PROCEDURE incCandidacy(NEW.erststimme);

CREATE TRIGGER updateVoteToCandidacy
AFTER UPDATE ON Vote
EXECUTE PROCEDURE shiftVoteCandidacy(OLD.zweitstimme, NEW.zweitstimme)

CREATE VIEW AccumulatedErststimmen AS (
    WITH Totalvotes(wkid, total) AS (
        SELECT year, wkid, SUM(votes) AS total
        FROM Candidacy
        GROUP BY year, wkid
    )
    SELECT year, wkid, idno, votes, (CAST(votes AS NUMERIC(8,7)) / total) AS percentage
    FROM Candidacy NATURAL JOIN Totalvotes
);

CREATE VIEW AccumulatedZweistimmen AS (

);


CREATE TABLE ZweitstimmenArchive (
    year INT NOT NULL REFERENCES ElectionYear(year),
    fsid INT NOT NULL REFERENCES FederalState(fsid),
    pid INT NOT NULL REFERENCES Party(pid),
    votes INT NOT NULL,
    CHECK (votes > 0),
    PRIMARY KEY (year, fsid, pid)
);
