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

COMMIT;
