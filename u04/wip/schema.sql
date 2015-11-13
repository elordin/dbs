DROP TRIGGER IF EXISTS CandidacyCounterStimmzettel       ON Stimmzettel CASCADE;
DROP TRIGGER IF EXISTS CandidacyCounterWahlschein        ON Wahlschein  CASCADE;
DROP TRIGGER IF EXISTS LandeslisteCounterStimmzettel     ON Stimmzettel CASCADE;
DROP TRIGGER IF EXISTS LandeslisteCounterWahlschein      ON Wahlschein  CASCADE;
DROP FUNCTION IF EXISTS incErststimme()                  CASCADE;
DROP FUNCTION IF EXISTS decErststimme()                  CASCADE;
DROP FUNCTION IF EXISTS incZweitstimmeWahlbezirk()       CASCADE;
DROP FUNCTION IF EXISTS decZweitstimmeWahlbezirk()       CASCADE;
DROP FUNCTION IF EXISTS incZweitstimmeDirektWahlbezirk() CASCADE;
DROP FUNCTION IF EXISTS decZweitstimmeDirektWahlbezirk() CASCADE;
DROP TABLE IF EXISTS AccumulatedZweitstimmenFS           CASCADE;
DROP TABLE IF EXISTS AccumulatedZweitstimmenWK           CASCADE;
DROP TABLE IF EXISTS CitizenRegistration                 CASCADE;
DROP VIEW  IF EXISTS Vote                                CASCADE;
DROP TABLE IF EXISTS Stimmzettel                         CASCADE;
DROP TABLE IF EXISTS Wahlschein                          CASCADE;
DROP TABLE IF EXISTS Candidacy                           CASCADE;
-- DROP TABLE IF EXISTS PartyMembership                  CASCADE;
DROP TABLE IF EXISTS Landeslistenplatz                   CASCADE;
DROP TABLE IF EXISTS Landesliste                         CASCADE;
DROP VIEW  IF EXISTS BriefWahlBezirk                     CASCADE;
DROP TABLE IF EXISTS BriefWahlBezirkData                 CASCADE;
DROP VIEW  IF EXISTS DirektWahlBezirk                    CASCADE;
DROP TABLE IF EXISTS DirektWahlBezirkData                CASCADE;
DROP TABLE IF EXISTS Wahlbezirk                          CASCADE;
DROP TABLE IF EXISTS Wahlkreis                           CASCADE;
DROP TABLE IF EXISTS Party                               CASCADE;
DROP VIEW  IF EXISTS Candidates                          CASCADE;
DROP TABLE IF EXISTS CandidatesData                      CASCADE;
DROP TABLE IF EXISTS hasVoted                            CASCADE;
DROP TABLE IF EXISTS Citizen                             CASCADE;
DROP TABLE IF EXISTS ElectionYear                        CASCADE;
DROP TABLE IF EXISTS FederalState                        CASCADE;

CREATE TABLE IF NOT EXISTS FederalState (
    fsid SERIAL PRIMARY KEY,
    name VARCHAR(255) UNIQUE NOT NULL,
    outline POLYGON,
    citizencount INT NOT NULL
);

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
    CHECK (gender in ('m', 'f', 'n', '-')),
    canvote BOOLEAN NOT NULL DEFAULT true,
    authtoken VARCHAR(255)
);

CREATE TABLE IF NOT EXISTS hasVoted (
    year INT NOT NULL REFERENCES ElectionYear(Year) ON DELETE CASCADE,
    idno VARCHAR(255) NOT NULL REFERENCES Citizen(idno) ON DELETE CASCADE,
    hasvoted BOOLEAN NOT NULL DEFAULT false,
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

--

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
    fsid INT NOT NULL REFERENCES FederalState(fsid) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS Landeslistenplatz (
    llid INT NOT NULL REFERENCES LandesListe(llid) ON DELETE CASCADE,
    idno VARCHAR(32) NOT NULL REFERENCES CandidatesData(idno) ON DELETE CASCADE,
    position INT NOT NULL,
    UNIQUE (llid, position),
    PRIMARY KEY (llid, idno)
);

-- CREATE TABLE IF NOT EXISTS PartyMembership (
--     pid INT NOT NULL REFERENCES Party(pid) ON DELETE CASCADE,
--     idno VARCHAR(32) NOT NULL REFERENCES CandidatesData(idno) ON DELETE CASCADE,
--     PRIMARY KEY (pid, idno)
-- );

CREATE TABLE IF NOT EXISTS Candidacy (
    -- CID to reference from Vote using a single value rather than the two value FK (wkid, idno)
    cid SERIAL PRIMARY KEY,
    wkid INT NOT NULL REFERENCES Wahlkreis(wkid) ON DELETE CASCADE,
    idno VARCHAR(255) NOT NULL REFERENCES CandidatesData(idno) ON DELETE CASCADE,
    supportedby INT REFERENCES Party(pid) ON DELETE SET NULL,
    votes INT NOT NULL DEFAULT 0
    -- check unique (idno, wkid->year)
    -- check member of supportedby
);

CREATE UNIQUE INDEX candidacy_constraint_support_max_one_per_wk
ON Candidacy(wkid, supportedby)
WHERE supportedby IS NOT NULL;


CREATE TABLE IF NOT EXISTS Wahlschein (
    wsid SERIAL PRIMARY KEY,

    wbid INT NOT NULL REFERENCES Wahlbezirk(wbid) ON DELETE CASCADE,
    issuedon DATE NOT NULL,
    gender CHAR NOT NULL,
    CHECK (gender in ('m', 'f', 'n', '-')),
    age INT NOT NULL,
    CHECK (age >= 18),
    CHECK (age < 150),
    erststimme INT REFERENCES Candidacy(cid) ON DELETE SET NULL,
    zweitstimme INT REFERENCES LandesListe(llid) ON DELETE SET NULL

    -- TODO: check erststimme zweitstimme same year as briefwahlbezirks wahlkreis year
);

CREATE TABLE IF NOT EXISTS Stimmzettel (
    szid SERIAL PRIMARY KEY,
    dwbid INT NOT NULL REFERENCES DirektWahlBezirkData(dwbid) ON DELETE CASCADE,
    gender CHAR NOT NULL,
    CHECK (gender in ('m', 'f', 'n', '-')),
    age INT NOT NULL,
    CHECK (age >= 18),
    CHECK (age < 150),
    erststimme INT REFERENCES Candidacy(cid) ON DELETE SET NULL,
    zweitstimme INT REFERENCES LandesListe(llid) ON DELETE SET NULL
    -- TODO: check erststimme zweitstimme same year as direktwahlbezirks wahlkreis year
);


CREATE OR REPLACE VIEW Vote AS (
    SELECT gender, age, erststimme, zweitstimme
    FROM Wahlschein
    UNION
    SELECT gender, age, erststimme, zweitstimme
    FROM Stimmzettel
);

CREATE TABLE IF NOT EXISTS CitizenRegistration (
    idno VARCHAR(32) NOT NULL REFERENCES Citizen(idno),
    dwbid INT NOT NULL REFERENCES DirektWahlBezirkData(dwbid),
    PRIMARY KEY (idno, dwbid)
);

-- Massive TODO:
-- On Wahlschein creation verify Year association for corrosponding Vote
-- On Stimmzettel creation verify Year association for corrosponding Vote
    -- Vote Erststimme is votable in this year in the associated Wahlkreis
    -- Wahlkreis -> DirektWahlbezirk -> Stimmzettel -> Candidacy -> Wahlkreis
    -- Wahlkreis -> BriefWahlbezirk -> Wahlbezirk -> Wahlschein -> Candidacy -> Wahlkreis

    -- Vote Zweitstimme is votable in this year in the associated FederalState
    -- Federalstate -> Wahlkreis -> Direktwahlbezirk -> Stimmzettel -> LandesListe -> FederalState
    -- Federalstate -> Wahlkreis -> Briefwahlbezirk -> Wahlbezirk -> Wahlschein -> LandesListe -> FederalState

CREATE TABLE IF NOT EXISTS AccumulatedZweitstimmenWB (
    wbid INT NOT NULL REFERENCES Wahlbezirk(wbid),
    llid INT NOT NULL REFERENCES LandesListe(llid),
    votes INT NOT NULL DEFAULT 0,
    PRIMARY KEY (wbid, llid)
);

CREATE TABLE IF NOT EXISTS AccumulatedZweitstimmenWK (
    wkid INT REFERENCES Wahlkreis(wkid),
    llid INT REFERENCES LandesListe(llid),
    votes INT NOT NULL DEFAULT 0,
    PRIMARY KEY (wkid, llid)
);

CREATE TABLE IF NOT EXISTS AccumulatedZweitstimmenFS (
    -- fsid INT REFERENCES FederalState(fsid),
    llid INT PRIMARY KEY REFERENCES LandesListe(llid),
    votes INT NOT NULL DEFAULT 0
);

CREATE OR REPLACE FUNCTION handleLandesListenInsert() RETURNS TRIGGER AS $insertll$
    DECLARE
        _wkid INT;
        _wbid INT;
    BEGIN
        INSERT INTO AccumulatedZweitstimmenFS (llid) VALUES (NEW.llid);
        FOR _wkid IN SELECT wkid
                     FROM Wahlkreis
                     WHERE fsid = NEW.fsid
        LOOP
            INSERT INTO AccumulatedZweitstimmenWK (wkid, llid) VALUES (_wkid, NEW.llid);
        END LOOP;
        FOR _wbid IN SELECT wbid
                    FROM Wahlbezirk NATURAL JOIN Wahlkreis
                    WHERE fsid = NEW.fsid
        LOOP
            INSERT INTO AccumulatedZweitstimmenWB (wbid, llid) VALUES (_wbid, NEW.llid);
        END LOOP;
        RETURN NEW;
    END;
$insertll$
LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION incErststimme() RETURNS TRIGGER AS $inc$
    BEGIN
        UPDATE Candidacy SET votes = votes + 1 WHERE cid = TG_ARGV[0];
        RETURN NEW;
    END;
$inc$
LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION decErststimme() RETURNS TRIGGER AS $dec$
    BEGIN
        UPDATE Candidacy SET votes = votes - 1 WHERE cid = TG_ARGV[0];
        RETURN NEW;
    END;
$dec$
LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION incZweitstimmeWahlbezirk() RETURNS TRIGGER AS $inc$
    BEGIN
        UPDATE AccumulatedZweitstimmenWB
        SET votes = votes + 1
        WHERE wbid = TG_ARGV[0]
          AND llid = TG_ARGV[1];
        -- TODO: Removed fsid from AccumulatedZweitstimmenFS
        UPDATE AccumulatedZweitstimmenFS
        SET votes = votes + 1 WHERE llid = TG_ARGV[1];
        UPDATE AccumulatedZweitstimmenWK
        SET votes = votes + 1 WHERE wkid IN (
            SELECT wkid
            FROM Wahlbezirk
            WHERE wbid = TG_ARGV[0]
        ) AND llid = TG_ARGV[1];
        RETURN NEW;
    END;
$inc$
LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION decZweitstimmeWahlbezirk() RETURNS TRIGGER AS $dec$
    BEGIN
        UPDATE AccumulatedZweitstimmenWB
        SET votes = votes - 1
        WHERE wbid = TG_ARGV[0]
          AND llid = TG_ARGV[1];
        UPDATE AccumulatedZweitstimmenFS
        SET votes = votes - 1 WHERE fsid IN (
            SELECT fsid
            FROM Wahlbezirk NATURAL JOIN Wahlkreis
            WHERE wbid = TG_ARGV[0]
        ) AND llid = TG_ARGV[1];
        UPDATE AccumulatedZweitstimmenWK
        SET votes = votes - 1 WHERE wkid IN (
            SELECT wkid
            FROM Wahlbezirk
            WHERE wbid = TG_ARGV[0]
        ) AND llid = TG_ARGV[1];
        RETURN NEW;
    END;
$dec$
LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION incZweitstimmeDirektWahlbezirk() RETURNS TRIGGER AS $inc$
    BEGIN
        UPDATE AccumulatedZweitstimmenWB
        SET votes = votes + 1 WHERE wbid IN (
            SELECT wbid
            FROM Wahlbezirk NATURAL JOIN DirektWahlBezirkData
            WHERE dwbid = TG_ARGV[0]
        ) AND llid = TG_ARGV[1];
        UPDATE AccumulatedZweitstimmenWK
        SET votes = votes + 1 WHERE wkid IN (
            SELECT wkid
            FROM Wahlbezirk NATURAL JOIN DirektWahlBezirkData
            WHERE dwbid = TG_ARGV[0]
        ) AND llid = TG_ARGV[1];
        UPDATE AccumulatedZweitstimmenFS
        SET votes = votes + 1 WHERE fsid IN (
            SELECT fsid
            FROM Wahlkreis NATURAL JOIN Wahlbezirk NATURAL JOIN DirektWahlBezirkData
            WHERE dwbid = TG_ARGV[0]
        ) AND llid = TG_ARGV[1];
        RETURN NEW;
    END;
$inc$
LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION decZweitstimmeDirektWahlbezirk() RETURNS TRIGGER AS $dec$
    BEGIN
        UPDATE AccumulatedZweitstimmenWB
        SET votes = votes - 1 WHERE wbid IN (
            SELECT wbid
            FROM Wahlbezirk NATURAL JOIN DirektWahlBezirkData
            WHERE dwbid = TG_ARGV[0]
        ) AND llid = TG_ARGV[1];
        UPDATE AccumulatedZweitstimmenWK
        SET votes = votes - 1 WHERE wkid IN (
            SELECT wkid
            FROM Wahlbezirk NATURAL JOIN DirektWahlBezirkData
            WHERE dwbid = TG_ARGV[0]
        ) AND llid = TG_ARGV[1];
        UPDATE AccumulatedZweitstimmenFS
        SET votes = votes - 1 WHERE fsid IN (
            SELECT fsid
            FROM Wahlkreis NATURAL JOIN Wahlbezirk NATURAL JOIN DirektWahlBezirkData
            WHERE dwbid = TG_ARGV[0]
        ) AND llid = TG_ARGV[1];
        RETURN NEW;
    END;
$dec$
LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION handleWahlscheinInsert() RETURNS TRIGGER AS $wsin$
    BEGIN
        PERFORM incErststimme(NEW.erststimme);
        PERFORM incZweitstimmeWahlbezirk(NEW.wbid, NEW.zweitstimme);
    END;
$wsin$
LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION handleStimmzettelInsert() RETURNS TRIGGER AS $wsin$
    BEGIN
        PERFORM incErststimme(NEW.erststimme);
        PERFORM incZweitstimmeDirektWahlbezirk(NEW.dwbid, NEW.zweitstimme);
    END;
$wsin$
LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION handleWahlscheinUpdate() RETURNS TRIGGER AS $wsin$
    BEGIN
        PERFORM decErststimme(OLD.erststimme);
        PERFORM incErststimme(NEW.erststimme);
        PERFORM decZweitstimmeWahlbezirk(OLD.wbid, OLD.zweitstimme);
        PERFORM incZweitstimmeWahlbezirk(NEW.wbid, NEW.zweitstimme);
    END;
$wsin$
LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION handleStimmzettelUpdate() RETURNS TRIGGER AS $wsin$
    BEGIN
        PERFORM decErststimme(OLD.erststimme);
        PERFORM incErststimme(NEW.erststimme);
        PERFORM decZweitstimmeDirektWahlbezirk(OLD.dwbid, OLD.zweitstimme);
        PERFORM incZweitstimmeDirektWahlbezirk(NEW.dwbid, NEW.zweitstimme);
    END;
$wsin$
LANGUAGE plpgsql;

CREATE TRIGGER OnLandeslistenInsert
    AFTER INSERT ON LandesListe
    FOR EACH ROW
    EXECUTE PROCEDURE handleLandesListenInsert();

CREATE TRIGGER OnWahlscheinInsert
    AFTER INSERT ON Wahlschein
    FOR EACH ROW
    EXECUTE PROCEDURE handleWahlscheinInsert();

CREATE TRIGGER OnStimmzettelInsert
    AFTER INSERT ON Stimmzettel
    FOR EACH ROW
    EXECUTE PROCEDURE handleStimmzettelInsert();

CREATE TRIGGER OnWahlscheinUpdate
    AFTER UPDATE ON Wahlschein
    FOR EACH ROW
    EXECUTE PROCEDURE handleWahlscheinUpdate();

CREATE TRIGGER OnStimmzettelUpdate
    AFTER UPDATE ON Stimmzettel
    FOR EACH ROW
    EXECUTE PROCEDURE handleStimmzettelUpdate();

CREATE OR REPLACE FUNCTION initalizeHasVoted(_year INT) RETURNS VOID AS $init$
    BEGIN
        INSERT INTO hasVoted (year, indo) SELECT _year, idno
                FROM Citizen
                WHERE canvote;
    END;
$init$
LANGUAGE plpgsql;
