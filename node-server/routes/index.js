var express = require('express');
var router = express.Router();


router.get('/vote', function (req, res) {
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
                    [req.cookies.token, req.connection.remoteAddress],
                    function (err, result) {
                        if (err) {
                            res.status(500).render("error", {error: err});
                        } else if (result.rowsCount < 1) {
                            res.cookie('token', '');
                            res.render('auth');
                        } else {
                            res.render('vote', {});
                        }
                });
            }
        });
    }
});


router.post('/vote', function () {
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
                    [req.cookies.token, req.connection.remoteAddress],
                    function (err, result) {
                        if (err) {
                            res.status(500).render("error", {error: err});
                        } else if (result.rowsCount < 1) {
                            res.cookie('token', '');
                            res.redirect('/vote');
                        } else {
                            req.db.query(
                               "BEGIN;" +
                               "DELETE FROM Tokens WHERE token = $1 AND address = $2;" +
                               "INSERT INTO Stimmzettel (dwbid, gender, age, erststimme, zweitstimme)" +
                               "                 VALUES ($3,    $4,     $5,  $6,         $7);" +
                               "COMMIT;",
                                [req.cookies.token,
                                 req.connection.remoteAddress,
                                 result.rows[0].dwbid,
                                 result.rows[0].gender,
                                 result.rows[0].age,
                                 erststimme,
                                 zweitstimme], function (err, result) {
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
        res.status(500).render("error", {error: err});
        return;
    }

    if (req.cookies.token && typeof(req.cookies.token) == 'string') {
        res.redirect('/vote');
    }

    req.db.connect(function (err) {
        if (err) {
            res.status(500).render("error", {error: err});
        } else {
            req.db.query("SELECT dwbid FROM CitizenRegistration WHERE idno = $1 AND authtoken = $2", [idno, pin], function (err, result) {
                if (err ||
                    result.rowsCount != 1 ||
                    !result.rows[0] ||
                    !result.rows[0].dwbid) {
                    res.status(500).render("error", {error: err});
                } else {
                    var dwbid = result.rows[0].dwbid;
                    req.db.query("INSERT INTO Tokens (token, dwbid) SELECT *, $1 FROM tokenGenerator() LIMIT 1", [dbwid], function (err, result) {
                        if (err) {
                            res.status(500).render("error", {error: err});
                        } else {
                            res.cookie('token', token).redirect('/vote');
                        }
                    });
                }
            });
        }
    });
});

function maxYearInDB() {
    return 2013;
}

function parseYear(yearString, db) {
    if (yearString === undefined || !parseInt(yearString)) {
        return false; // max year in db
    } else {
        var y = parseInt(yearString),
         year = (y < 49) ? y + 2000 : ((y < 100) ? y + 1900 : y);
        return year;
    }
}

function renderForDBQuery(req, res, query, template, year, title, locals, transformator) {
    req.db.connect(function (err) {
        if (err) {
            res.status(500).render("error", {error: err});
        } else {
            req.db.query(query,
            function (err, result) {
                if (err) {
                    res.status(500).render("error", {error: err});
                } else {
                    locals = locals || {};
                    locals.data = transformator === undefined ? result.rows : transformator(result);
                    locals.year = year;
                    locals.title = title;
                    res.render(template, locals);
                }
                req.db.end();
            });
        }
    });
}

router.get('/', function(req, res, next) {
    // get most recent election
    var year = maxYearInDB();
    res.redirect(301, '/overview/' + year);
});

router.get(/^\/overview(\/([0-9]{2}|[0-9]{4}))?\/?$/i, function(req, res, next) {
    var year = parseYear(req.params[1]);
    res.send('Overview');
});

// Q1: Seat distributions

router.get(/^\/q1(\/([0-9]{2}|[0-9]{4}))?\/?$/i, function(req, res, next) {
    res.redirect(302, '/seat-distribution/' + (req.params[1] || ''));
});

router.get(/^\/seat-distribution\/?$/i, function(req, res, next) {
    res.redirect(303, '/seat-distribution/' + maxYearInDB());
});

router.get(/^\/seat-distribution\/([0-9]{2}|[0-9]{4})\/?$/i, function(req, res, next) {
    var year = parseYear(req.params[0]);
    if (!year) {
        res.status(404).render(error, {error: "Error: Invalid year format - " + req.params[0]});
    } else {
        renderForDBQuery(req, res, 'SELECT * FROM Results_View_Seatdistribution_Bundestag WHERE year = ' + year,
            'seat-distribution', year, 'Sitzverteilung ' + year);
    }
});

// Q2: Delegates of the Bundestag

router.get(/^\/q2(\/([0-9]{2}|[0-9]{4}))?\/?$/i, function(req, res, next) {
    res.redirect(301, '/delegates/' + (req.params[1] || ''));
});

router.get(/^\/delegates\/?$/i, function(req, res, next) {
    res.redirect(301, '/delegates/' + maxYearInDB());
});

router.get(/^\/delegates\/([0-9]{2}|[0-9]{4})(\/([0-9]+))?\/?$/i, function(req, res, next) {
    var year = parseYear(req.params[0]);
    var page = parseInt(req.params[2]);
    if (!year) {
        res.status(404).render(error, {error: "Error: Invalid year format - " + req.params[0]});
    } else {
        // TODO: Ordering
        renderForDBQuery(req, res, 'SELECT * FROM Results_View_Delegates WHERE year = ' + year +
            ' ORDER BY fs_name, lastname, firstname ASC',
            'delegates', year, 'Abegordnete ' + year, {
                page: page === undefined || page < 1 ? 1 : page,
            });
    }
});

// Q3: Wahlkreis overview

router.get(/^\/q3(\/([0-9]{2}|[0-9]{4}))?\/?$/i, function (req, res, next) {
    res.redirect(301, '/wahlkreise/' + req.params[1] || '');
});

router.get(/^\/wahlkreise\/?$/i, function(req, res, next) {
    res.redirect(301, '/wahlkreise/' + maxYearInDB());
});

router.get(/^\/wahlkreise\/([0-9]{2}|[0-9]{4})\/?$/i, function (req, res, next) {
    var year = parseYear(req.params[0]);
    if (!year) {
        res.status(404).render('error', {error: "Error: Invalid year format - " + req.params[0]});
    } else {
        renderForDBQuery(req, res,
            'SELECT wk.wkid, wk.name AS name, wk.wknr, fs.fsid, fs.name AS fs_name ' +
            'FROM Wahlkreis wk JOIN FederalState fs ON wk.fsid = fs.fsid ' +
            'WHERE year = ' + year + ' ORDER BY wk.wknr ASC',

            'wahlkreise-all', year, unescape('Wahlkreise ' + year + ' - %DCbersicht'), {},
            function (result) {
                var rows = result.rows;
                var grouped = [];
                rows.map(function (elem) {
                    if (grouped[elem.fsid]) {
                        grouped[elem.fsid].push(elem);
                    } else {
                        grouped[elem.fsid] = [elem];
                    }
                });
                return grouped;
            });
    }
});

router.get(/^\/wahlkreise\/([0-9]{2}|[0-9]{4})\/([0-9]{1,3})\/?$/, function (req, res, next) {
    var year = parseYear(req.params[0]),
        wknr = parseInt(req.params[1]);
    if (!year) {
        res.status(404).render('error', {error: "Error: Invalid year format - " + req.params[0]});
    } else if (!wknr) {
        res.status(404).render('error', {error: "Error: Invalid wknr format - " + req.params[1]});
    } else {
        req.db.connect(function (err) {
            if (err) {
                res.status(500).render("error", {error: err});
            } else {
                req.db.query("SELECT * FROM Results_View_WahlkreisOverview_FirstVoteWinners WHERE year = " + year + " AND wknr = " + wknr,
                function (err, result1) {
                    if (err) {
                        res.status(500).render("error", {error: err});
                    } else {
                        req.db.query("SELECT * FROM Results_View_WahlkreisOverview_SecondVoteDistribution WHERE year = " + year + " AND wknr = " + wknr + ' ORDER BY votesabs DESC',
                        function (err, result2) {
                            if (err) {
                                res.status(500).render("error", {error: err});
                            } else {
                                if (result1.rows.length < 1 && result2.rows.length < 1) {
                                    res.redirect('/wahlkreise/' + year);
                                    return;
                                }
                                var wkname = result1.rows[0] && result1.rows[0].wk_name ||
                                             result2.rows[0] && result2.rows[0].wk_name;
                                var locals = {
                                    year: year,
                                    title: 'Wahlkreise ' + year + ' - ' + wkname,
                                    data: {
                                        first: result1.rows,
                                        second: result2.rows
                                    }
                                };
                                res.render('wahlkreise-single', locals);
                            }
                            req.db.end();
                        });
                    }
                });
            }
        });
    }
});

// Q4: Wahlkreis winners

router.get(/^\/q4(\/([0-9]{2}|[0-9]{4}))?\/?$/i, function (req, res, next) {
    res.redirect(301, '/wahlkreise/' + req.params[1] ? req.params[1] : maxYearInDB() + '/');
});

router.get(/^\/wahlkreise(\/|-)winners\/?$/i, function(req, res, next) {
    res.redirect(301, '/wahlkreise/' + maxYearInDB() + '/winners/');
});

router.get(/^\/wahlkreise\/([0-9]{2}|[0-9]{4})\/winners\/?$/i, function(req, res, next) {
    var year = parseYear(req.params[0]);
    if (!year) {
        res.status(404).render(error, {error: "Error: Invalid year format - " + req.params[0]});
    } else {
        renderForDBQuery(req, res, 'SELECT * FROM Results_View_Wahlkreiswinners WHERE year = ' + year,
            'wahlkreise-winners', year, 'Wahlkreis-Sieger ' + year, {},
            function (result) {
                var rows = result.rows;
                var grouped = [];
                rows.map(function (elem) {
                    if (grouped[elem.fsid]) {
                        grouped[elem.fsid].push(elem);
                    } else {
                        grouped[elem.fsid] = [elem];
                    }
                });
                return grouped;
            });
    }
});

// Q5: Überhangsmandate

router.get(/^\/q5(\/([0-9]{2}|[0-9]{4}))?\/?$/i, function(req, res, next) {
    res.redirect(301, '/ueberhangmandate/' + (req.params[1] || ''));
});

router.get(/^\/ueberhangmandate\/?$/i, function(req, res, next) {
    res.redirect(301, '/ueberhangmandate/' + maxYearInDB());
});

router.get(/^\/ueberhangmandate\/([0-9]{2}|[0-9]{4})\/?$/i, function(req, res, next) {
    var year = parseYear(req.params[0]);
    if (!year) {
        res.status(404).render('error', {error: "Error: Invalid year format - " + req.params[0]});
    } else {
        renderForDBQuery(req, res, 'SELECT * FROM Results_View_UeberhangsMandate WHERE year = ' + year,
            'ueberhangmandate', year, '&Uuml;berhangmandate ' + year);
    }
});

// Q6: Closest winners

router.get(/^\/q6(\/([0-9]{2}|[0-9]{4}))?\/?$/i, function(req, res, next) {
    res.redirect(301, '/closest-winners/' + (req.params[1] || ''));
});

router.get(/^\/closest-winners\/?$/, function(req, res, next) {
    res.redirect(301, '/closest-winners/' + maxYearInDB());
});

router.get(/^\/closest-winners\/([0-9]{2}|[0-9]{4})\/?$/, function(req, res, next) {
    var year = parseYear(req.params[0]);
    if (!year) {
        res.status(404).render('error', {error: "Error: Invalid year format - " + req.params[0]});
    } else {
        renderForDBQuery(req, res, 'SELECT DISTINCT pid, p_name, p_shorthand FROM Results_View_NarrowWahlkreisWinsAndLosings WHERE year = ' + year,
            'closest-winners-all', year, 'Knappste Sieger ' + year);
    }
});

router.get(/^\/closest-winners(\/([0-9]{2}|[0-9]{4}))?(\/([A-Za-z0-9%\+]+))?\/?$/, function(req, res, next) {
    var year = parseYear(req.params[1]);
    var shorthand = req.params[3];
    console.log(shorthand);
    if (!year) {
        res.status(404).render('error', {error: "Error: Invalid year format - " + req.params[0]});
    } else {
        renderForDBQuery(req, res, 'SELECT * FROM Results_View_NarrowWahlkreisWinsAndLosings WHERE year = ' + year + ' AND LOWER(p_shorthand) = LOWER(\'' + shorthand + '\')' ,
            'closest-winners-single', year, 'Knappste Sieger ' + year + ' - ' + shorthand, {});
    }
});



// Q7: Wahlkreis overview again

router.get(/^\/q7(\/([0-9]{2}|[0-9]{4}))?\/wk\/([0-9]{1,3})\/slow\/?$/, function(req, res, next) {
    res.redirect(301, '');
});

router.get(/^\/wahlkreise(\/[0-9]{2}|[0-9]{4})\/wk\/([0-9]{1,3})\/slow\/?$/, function(req, res, next) {
    var year = parseYear(req.params[1]);
    if (!year) {
        res.status(404).render(error, {error: "Error: Invalid year format - " + req.params[0]});
    } else {
        renderForDBQuery(req, res, 'SELECT * FROM Ueberhangsmandate WHERE year = ' + year,
            'ueberhangsmandate');
    }
});


module.exports = router;
