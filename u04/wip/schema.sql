CREATE TABLE FederalState (
    fsid INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(255) UNIQUE NOT NULL,
    outline POLYGON
);

-- voting system?
CREATE TABLE ElectionYear (
    year INT PRIMARY KEY
);

CREATE TABLE Citizen (
    idno VARCHAR(32) PRIMARY KEY,
    title VARCHAR(63),
    firstname VARCHAR(255) NOT NULL,
    lastname VARCHAR(255) NOT NULL,
    dateofbirth DATE NOT NULL,
    gender CHAR NOT NULL,
    CHECK gender in ('m', 'f'),
    canvote BOOLEAN NOT NULL DEFAULT true,
    authtoken VARCHAR(255)
);

CREATE TABLE hasVoted (
    year INT NOT NULL,
    idno VARCHAR(255) NOT NULL,
    FOREIGN KEY year REFERENCES ElectionYear(Year),
    FOREIGN KEY idno REFERENCES Citizen(idno),
    hasvoted BOOLEAN NOT NULL DEFAULT true,
    PRIMARY KEY (year, citizen)
);

CREATE TABLE CandidatesData (
    idno VARCHAR(32),
    FOREIGN KEY idno REFERENCES Citizen(idno)
);

CREATE VIEW Candidates AS (
    SELECT *
    FROM Candidates NATURAL JOIN Citizen
)

CREATE TABLE Party (
    pid INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(255) UNIQUE NOT NULL,
    shorthand VARCHAR(32) UNIQUE NOT NULL,
    website VARCHAR(255),
    colourcode VARCHAR(15) NOT NULL,
    isminority BOOLEAN NOT NULL DEFAULT false
);

CREATE TABLE Wahlkreis (
    wkid INT PRIMARY KEY AUTO_INCREMENT,
    wknr INT NOT NULL,
    name VARCHAR(255) NOT NULL,
    outline POLYGON,
    fsid INT NOT NULL,
    FOREIGN KEY fsid REFERENCES FederalState(fsid),
    year INT NOT NULL,
    FOREIGN KEY year REFERENCES ElectionYear(year),
    CHECK UNIQUE (wknr, year)
)

CREATE TABLE Wahlbezirk (
    wbid INT PRIMARY KEY,
    wkid INT NOT NULL,
    FOREIGN KEY wkid REFERENCES Wahlkreis(wkid)
)

CREATE TABLE DirektWahlBezirkData (
    dwbid INT PRIMARY KEY,
    wbid INT NOT NULL,
    FOREIGN KEY wbid REFERENCES Wahlbezirk(wbid)
);

CREATE VIEW DirektWahlBezirk AS (
    SELECT *
    FROM Wahlbezirk NATURAL JOIN DirektWahlBezirkData
);

CREATE TABLE BriefWahlBezirkData (
    bwbid INT PRIMARY KEY,
    wbid INT NOT NULL,
    FOREIGN KEY wbid REFERENCES Wahlbezirk(wbid)
);

CREATE VIEW BriefWahlBezirk AS (
    SELECT *
    FROM Wahlbezirk NATURAL JOIN BriefWahlBezirkData
);

CREATE TABLE LandesListe (
    llid INT PRIMARY KEY AUTO_INCREMENT,
    year INT NOT NULL,
    FOREIGN KEY year REFERENCES ElectionYear(year),
    pid INT NOT NULL,
    FOREIGN KEY pid REFERENCES Party(pid),
    fsid INT NOT NULL,
    FOREIGN KEY fsid REFERENCES FederalState(fsid)
);

CREATE TABLE Landeslistenplatz (
    llid INT NOT NULL,
    FOREIGN KEY llid REFERENCES LandesListe(llid),
    idno INT NOT NULL,
    FOREIGN KEY idno REFERENCES CandidatesData(idno),
    position INT UNIQUE NOT NULL,
    PRIMARY KEY (llid, idno)
);

-- CREATE VIEW votableBySecondVote AS (
--     SELECT year, pid, fsid
--     FROM Landesliste
-- );

CREATE TABLE PartyMembership (
    pid INT NOT NULL,
    FOREIGN KEY pid REFERENCES Party(pid),
    idno INT NOT NULL,
    FOREIGN KEY idno REFERENCES CandidatesData(idno),
    PRIMARY KEY (pid, idno)
);

-- CID?
CREATE TABLE Candidacy (
    cid INT PRIMARY KEY,
    wkid INT NOT NULL,
    FOREIGN KEY wkid REFERENCES Wahlkreis(wkid),
    idno VARCHAR(255) NOT NULL,
    FOREIGN KEY idno REFERENCES CandidatesData(idno),
    supportedby INT,
    FOREIGN KEY supportedby REFERENCES Party(pid),
    CHECK     EXISTS (SELECT pid
                      FROM PartyMembership
                      WHERE PartyMembership.idno = Candidacy.idno
                        AND PartyMembership.pid  = Candidacy.supportedby),
    CHECK NOT EXISTS (SELECT *
                      FROM PartyMembership
                      WHERE PartyMembership.idno = Candidacy.idno),
                        AND PartyMembership.pid <> Candidacy.supportedby
    CHECK UNIQUE (wkid, idno)
);

-- SAME YEAR CONSTRAINT?
CREATE TABLE Vote (
    vid INT PRIMARY KEY AUTO_INCREMENT,
    gender CHAR NOT NULL,
    CHECK gender in ('m', 'f'),
    age INT NOT NULL,
    CHECK age >= 18,
    CHECK age < 150,
    erststimme INT NOT NULL,
    zweitstimme INT NOT NULL,
    FOREIGN KEY erststimme REFERENCES Candidacy(cid),
    FOREIGN KEY zweistimme REFERENCES LandesListe(llid),
    CHECK (SELECT year
           FROM Candidacy NATURAL JOIN Wahlkreis
           WHERE Candidacy.cid = Vote.erststimme)
        =
          (SELECT year
           FROM LandesListe
           WHERE Landesliste.llid = Vote.zweitstimme)
);

CREATE TABLE WahlscheinData (
    vid PRIMARY KEY,
    FOREIGN KEY vid REFERENCES Vote(vid),
    bwbid INT NOT NULL,
    FOREIGN KEY bwbid REFERENCES BriefWahlBezirkData(bwbid),
    issuedon DATE NOT NULL
);

CREATE VIEW Wahlschein AS (
    SELECT *
    FROM Vote NATURAL JOIN WahlscheinData
);

CREATE TABLE StimmzettelData (
    vid PRIMARY KEY,
    FOREIGN KEY vid REFERENCES Vote(vid),
    dwbid INT NOT NULL,
    FOREIGN KEY dwbid REFERENCES DirektWahlBezirkData(dwbid)
);

CREATE VIEW Stimmzettel AS (
    SELECT *
    FROM Vote NATURAL JOIN StimmzettelData
);
