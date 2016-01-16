var express = require('express');
var router = express.Router();

const TOKEN_LENGTH = 64;

function sanitize(input) {
    return input;
}


/**
 *  Requires open db connection
 */
function runMultipleQueries(req, res, queryList, resultList, callback) {
    if (queryList.length < 1) {
        // execute callback
        callback(req, res, resultList);
        req.db.end();
    } else {
        // run next query
        req.db.query(queryList[0].query || "", (queryList[0].args || []).map(sanitize), function (err, result) {
            if (err) {
                res.status(500).render("error", {error: err});
            } else {
                var newQueryList = queryList.slice(1, queryList.length),
                    newResultList = resultList;
                    newResultList.push(result);
                runMultipleQueries(
                    req, res, newQueryList, newResultList, callback);
            }
        });
    }
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
                            var dwbid = result.rows[0].dwbid;
                            req.db.query("SELECT * FROM WahlscheinEntries WHERE dwbid = $1 ORDER BY ll_pname",
                                [sanitize(dwbid)], function (err, result) {
                                if (err) {
                                    res.status(500).render("error", {error: err});
                                } else if (result.rows.length < 2) {
                                    res.status(451).send("You do not have a choice whom to vote for, so we voted for you!");
                                } else {
                                    console.log(result.rows[0]);
                                    res.render('vote', {
                                        votables: result.rows,
                                        wk_name: result.rows[0].wk_name,
                                        wknr: result.rows[0].wknr,
                                        fs_name: result.rows[0].fs_name
                                    });
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
    var erststimme = parseInt(req.body.erststimme);
    var zweitstimme = parseInt(req.body.zweitstimme);

    if (!erststimme || !zweitstimme ||
        typeof erststimme != 'number' ||
        typeof zweitstimme != 'number' ||
        isNaN(erststimme) || isNaN(zweitstimme)) {
        res.status(500).send("invalid format");
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

                            runMultipleQueries(req, res, [
                                {
                                    query: "BEGIN;",
                                    args: []
                                },
                                {
                                    query: "DELETE FROM Tokens WHERE token = $1 AND address = $2;",
                                    args: [req.cookies.token, req.connection.remoteAddress]
                                },
                                {
                                    query: "INSERT INTO Stimmzettel (dwbid, gender, age, erststimme, zweitstimme) " +
                                           "VALUES ($1, $2, $3, $4, $5);",
                                    args: [
                                        result.rows[0].dwbid,
                                        result.rows[0].gender,
                                        result.rows[0].age,
                                        erststimme,
                                        zweitstimme
                                    ]
                                },
                                {
                                    query: "COMMIT;",
                                    args: []
                                },
                            ], [], function (results) {
                                res.cookie('token', '').redirect('/voted');
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

                    res.render('auth', { error: 'Personalausweis-Nr. konnte nicht gefunden werden oder die PIN ist falsch.'});
                } else if (result.rows[0].hasvoted) {
                    res.render('auth', { error: 'Sie haben bereits gewählt.'});
                } else {
                    var token = result.rows[0].token;
                    runMultipleQueries(req, res,
                        [
                            {
                                query: "BEGIN;",
                                args: []
                            }, {
                                query: "UPDATE hasVoted SET hasvoted = true WHERE idno = $1;",
                                args: [idno]
                            }, {
                                query: "INSERT INTO Tokens (token, age, gender, dwbid, address) VALUES ($1, $2, $3, $4, $5);",
                                args: [
                                    token,
                                    result.rows[0].age,
                                    result.rows[0].gender,
                                    result.rows[0].dwbid,
                                    req.connection.remoteAddress
                                ]
                            }, {
                                query: "COMMIT;",
                                args: []
                            }
                        ], [], function (req, res, results) {
                            res.cookie('token', token).redirect('/vote');
                        });
                }
            });
        }
    });
});


module.exports = router;
