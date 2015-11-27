var express = require('express');
var router = express.Router();

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
        res.status(404).render(error, {error: "Error: Invalid year format - " + req.params[0]});
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
                        console.log("!");
                        grouped[elem.fsid].push(elem);
                    } else {
                        grouped[elem.fsid] = [elem];
                    }
                });
                return grouped;
            });
    }
});

router.get(/^\/wahlkreise\/([0-9]{2}|[0-9]{4})\/([0-9]{3})\/?$/, function (req, res, next) {
    var year = parseYear(req.params[0]),
        wkid = parseInt(req.params[1]);
    if (!year) {
        res.status(404).render(error, {error: "Error: Invalid year format - " + req.params[0]});
    } else if (!wkid) {
        res.status(404).render(error, {error: "Error: Invalid wkid format - " + req.params[1]});
    } else {
        renderForDBQuery(req, res,
            'SELECT * FROM Results_View_WahlkreisOverview_FirstVoteWinners WHERE year = ' + year + ' AND wkid = ' + wkid,
            'wahlkreise-single', year, 'Wahlkreis Ergebnisse ' + year + ' - Wahlkreis ' + wkid);
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
            'wahlkreise-winners', year, 'Wahlkreis-Sieger ' + year);
    }
});

// Q5: Überhangsmandate

router.get(/^\/q5(\/([0-9]{2}|[0-9]{4}))?\/?$/i, function(req, res, next) {
    res.redirect(301, 'ueberhangsmandate/' + req.params[1]);
});

router.get(/^\/ueberhangsmandate\/?$/i, function(req, res, next) {
    res.redirect(301, 'ueberhangsmandate/' + maxYearInDB());
});

router.get(/^\/ueberhangsmandate\/([0-9]{2}|[0-9]{4})\/?$/i, function(req, res, next) {
    var year = parseYear(req.params[0]);
    if (!year) {
        res.status(404).render(error, {error: "Error: Invalid year format - " + req.params[0]});
    } else {
        renderForDBQuery(req, res, 'SELECT * FROM Results_View_UeberhangsMandate WHERE year = ' + year,
            'ueberhangsmandate', year, 'Ueberhangsmandate ' + year);
    }
});

// Q6: Closest winners

router.get(/^\/q6(\/([0-9]{2}|[0-9]{4}))?\/?$/i, function(req, res, next) {
    res.redirect(301, '');
});

router.get(/^\/closest-winners(\/([0-9]{2}|[0-9]{4}))?\/?$/, function(req, res, next) {
    var year = parseYear(req.params[1]);
    if (!year) {
        res.status(404).render(error, {error: "Error: Invalid year format - " + req.params[0]});
    } else {
        renderForDBQuery(req, res, 'SELECT * FROM Ueberhangsmandate WHERE year = ' + year,
            'closest-winners');
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
