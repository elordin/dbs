BEGIN;

CREATE TABLE IF NOT EXISTS Tokens (
    token VARCHAR(64) PRIMARY KEY,
    age INT NOT NULL,
    CHECK (age >= 18),
    CHECK (age < 150),
    gender CHAR NOT NULL,
    CHECK (gender in ('m', 'f', 'n', '-')),
    dwbid INT NOT NULL REFERENCES DirektWahlBezirkData(dwbid),
    address VARCHAR(255) NOT NULL
);

-- Taken from: http://stackoverflow.com/questions/3970795/how-do-you-create-a-random-string-in-postgresql
CREATE OR REPLACE FUNCTION random_string(length integer) RETURNS TEXT AS
$$
DECLARE
  chars text[] := '{0,1,2,3,4,5,6,7,8,9,A,B,C,D,E,F,G,H,I,J,K,L,M,N,O,P,Q,R,S,T,U,V,W,X,Y,Z,a,b,c,d,e,f,g,h,i,j,k,l,m,n,o,p,q,r,s,t,u,v,w,x,y,z}';
  result text := '';
  i integer := 0;
BEGIN
  if length < 0 then
    raise exception 'Given length cannot be less than 0';
  end if;
  for i in 1..length loop
    result := result || chars[1+random()*(array_length(chars, 1)-1)];
  end loop;
  IF (SELECT COUNT(*) > 0 FROM Tokens WHERE token = result)
  THEN return random_string(length);
  ELSE return result;
  END IF;
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION random_pin(length integer) RETURNS TEXT AS
$$
DECLARE
  digits text[] := '{0,1,2,3,4,5,6,7,8,9}';
  result text := '';
  i integer := 0;
BEGIN
  if length < 0 then
    raise exception 'Given length cannot be less than 0';
  end if;
  for i in 1..length loop
    result := result || digits[1+random()*(array_length(digits, 1)-1)];
  end loop;
  return result;
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION generate_new_pins() RETURNS INTEGER AS
$$
DECLARE
    _idno VARCHAR;
BEGIN
    FOR _idno IN SELECT idno FROM citizen LOOP
        UPDATE citizen SET authtoken = random_pin(4) WHERE idno = _idno;
    END LOOP;
    RETURN 1;
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE VIEW Votables(wkid,
    cid, c_idno, c_firstname, c_lastname, c_age,
    llid, ll_pid, ll_pname, ll_pshorthand) AS (

    SELECT
        wk.wkid,
        cas.cid, cas.idno, cis.firstname, cis.lastname,
        FLOOR(EXTRACT(DAYS FROM (now() - cis.dateofbirth)) / 365) AS age,
        lls.llid, lls.pid, p.name, p.shorthand

    FROM
        Candidacy cas NATURAL JOIN Citizen cis NATURAL JOIN Wahlkreis wk FULL OUTER JOIN LandesListe lls
        ON cas.supportedby = lls.pid AND wk.fsid = lls.fsid AND wk.year = lls.year
        INNER JOIN Party p
        ON cas.supportedby = p.pid AND lls.pid = p.pid
);

COMMIT;