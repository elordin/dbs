DROP VIEW Stimmzettel;
DROP TABLE IF EXISTS StimmzettelData;
DROP VIEW Wahlschein;
DROP TABLE IF EXISTS WahlscheinData;
DROP TABLE IF EXISTS Vote;
DROP TABLE IF EXISTS Candidacy;
DROP TABLE IF EXISTS PartyMembership;
DROP TABLE IF EXISTS Landeslistenplatz;
DROP TABLE IF EXISTS Landesliste;
DROP VIEW BriefWahlBezirk;
DROP TABLE IF EXISTS BriefWahlBezirkData;
DROP VIEW DirektWahlBezirk;
DROP TABLE IF EXISTS DirektWahlBezirkData;
DROP TABLE IF EXISTS Wahlbezirk;
DROP TABLE IF EXISTS Wahlkreis;
DROP TABLE IF EXISTS Party;
DROP VIEW Candidates;
DROP TABLE IF EXISTS CandidatesData;
DROP TABLE IF EXISTS hasVoted;
DROP TABLE IF EXISTS Citizen;
DROP TABLE IF EXISTS ElectionYear;
DROP TABLE IF EXISTS FederalState;

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
    title VARCHAR(63),
    firstname VARCHAR(255) NOT NULL,
    lastname VARCHAR(255) NOT NULL,
    dateofbirth DATE NOT NULL,
    gender CHAR NOT NULL,
    CHECK (gender in ('m', 'f')),
    canvote BOOLEAN NOT NULL DEFAULT true,
    authtoken VARCHAR(255)
);

CREATE TABLE IF NOT EXISTS hasVoted (
    year INT NOT NULL REFERENCES ElectionYear(Year) ON DELETE CASCADE,
    idno VARCHAR(255) REFERENCES Citizen(idno) ON DELETE CASCADE,
    hasvoted BOOLEAN NOT NULL DEFAULT true,
    PRIMARY KEY (year, idno)
);

CREATE TABLE IF NOT EXISTS CandidatesData (
    idno VARCHAR(32) PRIMARY KEY REFERENCES Citizen(idno) ON DELETE SET NULL
);


CREATE VIEW Candidates AS (
    SELECT *
    FROM CandidatesData NATURAL JOIN Citizen
);

CREATE TABLE IF NOT EXISTS Party (
    pid SERIAL PRIMARY KEY,
    name VARCHAR(255) UNIQUE NOT NULL,
    shorthand VARCHAR(32) UNIQUE NOT NULL,
    website VARCHAR(255),
    colourcode VARCHAR(15) NOT NULL,
    isminority BOOLEAN NOT NULL DEFAULT false
);

CREATE TABLE IF NOT EXISTS Wahlkreis (
    wkid SERIAL PRIMARY KEY,
    wknr INT NOT NULL,
    name VARCHAR(255) NOT NULL,
    outline POLYGON,
    fsid INT REFERENCES FederalState(fsid) ON DELETE SET NULL,
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

CREATE VIEW DirektWahlBezirk AS (
    SELECT *
    FROM Wahlbezirk NATURAL JOIN DirektWahlBezirkData
);

CREATE TABLE IF NOT EXISTS BriefWahlBezirkData (
    bwbid INT PRIMARY KEY,
    wbid INT NOT NULL REFERENCES Wahlbezirk(wbid) ON DELETE CASCADE
);

CREATE VIEW BriefWahlBezirk AS (
    SELECT *
    FROM Wahlbezirk NATURAL JOIN BriefWahlBezirkData
);

CREATE TABLE IF NOT EXISTS LandesListe (
    llid SERIAL PRIMARY KEY,
    year INT NOT NULL REFERENCES ElectionYear(year) ON DELETE CASCADE,
    pid INT NOT NULL REFERENCES Party(pid) ON DELETE CASCADE,
    fsid INT NOT NULL REFERENCES FederalState(fsid) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS Landeslistenplatz (
    llid INT NOT NULL REFERENCES LandesListe(llid) ON DELETE CASCADE,
    idno VARCHAR(32) NOT NULL REFERENCES CandidatesData(idno) ON DELETE CASCADE,
    position INT UNIQUE NOT NULL,
    PRIMARY KEY (llid, idno)
);

-- CREATE VIEW votableBySecondVote AS (
--     SELECT year, pid, fsid
--     FROM Landesliste
-- );

CREATE TABLE IF NOT EXISTS PartyMembership (
    pid INT NOT NULL REFERENCES Party(pid) ON DELETE CASCADE,
    idno VARCHAR(32) NOT NULL REFERENCES CandidatesData(idno) ON DELETE CASCADE,
    PRIMARY KEY (pid, idno)
);

-- CID?
CREATE TABLE IF NOT EXISTS Candidacy (
    cid INT PRIMARY KEY,
    wkid INT NOT NULL REFERENCES Wahlkreis(wkid) ON DELETE CASCADE,
    idno VARCHAR(255) NOT NULL REFERENCES CandidatesData(idno) ON DELETE CASCADE,
    supportedby INT REFERENCES Party(pid) ON DELETE SET NULL,
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
           -- FROM Candidacy NATURAL JOIN Wahlkreis
           -- WHERE Candidacy.cid = Vote.erststimme)
        -- =
          -- (SELECT year
           -- FROM LandesListe
           -- WHERE Landesliste.llid = Vote.zweitstimme)
);

CREATE TABLE IF NOT EXISTS WahlscheinData (
    vid INT PRIMARY KEY REFERENCES Vote(vid) ON DELETE CASCADE,
    bwbid INT NOT NULL REFERENCES BriefWahlBezirkData(bwbid) ON DELETE CASCADE,
    issuedon DATE NOT NULL
);

CREATE VIEW Wahlschein AS (
    SELECT *
    FROM Vote NATURAL JOIN WahlscheinData
);

CREATE TABLE IF NOT EXISTS StimmzettelData (
    vid INT PRIMARY KEY REFERENCES Vote(vid) ON DELETE CASCADE,
    dwbid INT NOT NULL REFERENCES DirektWahlBezirkData(dwbid) ON DELETE CASCADE
);

CREATE VIEW Stimmzettel AS (
    SELECT *
    FROM Vote NATURAL JOIN StimmzettelData
);
