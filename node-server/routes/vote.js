var express = require('express');
var router = express.Router();

const TOKEN_LENGTH = 64;

function sanitize(input) {
    return input;
}


router.get('/', function (req, res) {
    if (!req.cookies.token || typeof(req.cookies.token) != 'string') {
        res.render('auth');
    } else {
        // get cookie in db
        req.db.connect(function (err) {
            if (err) {
                res.status(500).render("error", {error: err});
            } else {
                req.db.query(
                    "SELECT * FROM Tokens WHERE token = $1 AND address = $2",
                    ([req.cookies.token, req.connection.remoteAddress]).map(sanitize),
                    function (err, result) {
                        if (err) {
                            res.status(500).render("error", {error: err});
                        } else if (result.rowCount != 1) {
                            res.cookie('token', '');
                            res.render('auth');
                        } else {
                            var dwbid = result.dwbid;
                            req.db.query("SELECT * FROM Votables NATURAL JOIN Wahlbezirk NATURAL JOIN DirektwahlbezirkData WHERE dwbid = $1 ORDER BY ll_pname",
                                [sanitize(dwbid)], function (err, result) {
                                if (err) {
                                    res.status(500).render("error", {error: err});
                                } else {
                                    res.render('vote', { votables: result.rows });
                                }
                            });
                        }
                    }
                );
            }
        });
    }
});


router.post('/', function (req, res) {
    var erststimme = req.body.erststimme;
    var zweitstimme = req.body.zweitstimme;

    if (!erststimme || !zweitstimme) {
        res.status(500).render("error", {error: err});
    } else if (!req.cookies.token || typeof(req.cookies.token) != 'string') {
        res.redirect('/vote');
    } else {
        // get cookie in db
        req.db.connect(function (err) {
            if (err) {
                res.status(500).render("error", {error: err});
            } else {
                req.db.query(
                    "SELECT * FROM Tokens WHERE token = $1 AND address = $2",
                    ([req.cookies.token, req.connection.remoteAddress]).map(sanitize),
                    function (err, result) {
                        if (err) {
                            res.status(500).render("error", {error: err});
                        } else if (result.rowsCount < 1) {
                            res.cookie('token', '');
                            res.redirect('/vote');
                        } else {
                            // validate voted Candidate and Landesliste are actually votable for this person

                            req.db.query(
                               "BEGIN;" +
                               "DELETE FROM Tokens WHERE token = $1 AND address = $2;" +
                               "INSERT INTO Stimmzettel (dwbid, gender, age, erststimme, zweitstimme)" +
                               "                 VALUES ($3,    $4,     $5,  $6,         $7);" +
                               "COMMIT;",
                                ([req.cookies.token,
                                 req.connection.remoteAddress,
                                 result.rows[0].dwbid,
                                 result.rows[0].gender,
                                 result.rows[0].age,
                                 erststimme,
                                 zweitstimme]).map(sanitize), function (err, result) {
                                if (err) {
                                    res.status(500).render("error", {error: err});
                                } else {
                                    res.cookie('token', '').redirect('/voted');
                                }
                            });

                        }
                });
            }
        });
    }
});



router.post('/auth', function (req, res) {
    var idno = req.body.idno;
    var pin = req.body.pin;

    if (!idno || !pin) {
        res.status(500).render("error", {error: "Parameters missing"});
        return;
    }

    if (req.cookies.token && typeof(req.cookies.token) == 'string' && req.cookies.token.length == TOKEN_LENGTH) {
        res.redirect('/vote');
        return;
    }

    req.db.connect(function (err) {
        if (err) {
            res.status(500).render("error", {error: err});
        } else {
            req.db.query("SELECT random_string(" + TOKEN_LENGTH + ") AS token, dwbid, FLOOR(EXTRACT(DAYS FROM (now() - dateofbirth)) / 365) AS age, gender, hasvoted " +
                         "FROM CitizenRegistration NATURAL JOIN Citizen NATURAL JOIN hasVoted NATURAL JOIN ElectionYear WHERE iscurrent AND idno = $1 AND authtoken = $2", ([idno, pin]).map(sanitize), function (err, result) {
                if (err)
                    res.status(500).render("error", {error: err});
                if (!result ||
                    !result.rowCount ||
                     result.rowCount != 1 ||
                    !result.rows[0] ||
                    !result.rows[0].dwbid) {

                    console.log(result);

                    res.render('auth', { error: 'Personalausweis-Nr. konnte nicht gefunden werden oder die PIN ist falsch.'});
                } else if (result.rows[0].hasvoted) {
                    res.render('auth', { error: 'Sie haben bereits gewählt.'});
                } else {
                    var token = result.rows[0].token;
                    console.log(result.rows[0]);
                    req.db.query("BEGIN; " +
                                 "UPDATE hasVoted SET hasvoted = true WHERE idno = $1;" +
                                 "INSERT INTO Tokens (token, age, gender, dwbid, address) VALUES ($1, $2, $3, $4, $5);" +
                                 "COMMIT;",
                        ([idno, token, result.rows[0].age, result.rows[0].gender, result.rows[0].dwbid, req.connection.remoteAddress ]).map(sanitize), function (err, result) {
                        if (err) {
                            res.status(500).render("error", {error: err});
                        } else {
                            console.log(result);
                            res.cookie('token', token).redirect('/vote');
                        }
                    });
                }
            });
        }
    });
});


module.exports = router;
