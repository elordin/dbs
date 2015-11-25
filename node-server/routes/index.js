var express = require('express');
var router = express.Router();

function parseYear(yearString) {
    function yearExists(year) {
        return true;
    }

    function maxYearInDB() {
        return 2013;
    }

    if (yearString === undefined || !parseInt(yearString)) {
        return maxYearInDB(); // max year in db
    } else {
        var y = parseInt(yearString),
         year = (y < 49) ? y + 2000 : ((y < 100) ? y + 1900 : y);
        if (yearExists(year))
            return year;
        else
            return false;
    }
}

router.get('/', function(req, res, next) {
    // get most recent election
    var year = parseYear();
    res.redirect(301, '/overview/' + year);
});

router.get(/^\/overview(\/([0-9]{2}|[0-9]{4}))?\/?$/i, function(req, res, next) {
    var year = parseYear(req.params[1]);
    // get overview data for year
    req.db.connect(function (err) {
        if (err) {
            res.render("error", {error: err});
        } else {
            req.db.query('SELECT * FROM AccumulatedZweitstimmenWK;', function (err, result) {
                if (err) {
                    res.render("error", {error: err});
                } else {
                    res.json(result.rows);
                }
            });
        }
        // req.db.end();
    });
});

// Q1: Seat distributions

router.get(/^\/q1(\/([0-9]{2}|[0-9]{4}))?\/?$/i, function(req, res, next) {
    res.redirect(301, '');
});

router.get(/^\/seat-distribution(\/([0-9]{2}|[0-9]{4}))?\/?$/i, function(req, res, next) {
    var year = parseYear(req.params[1]);
    // get overview data for year
    req.db.connect(function (err) {
        if (err) {
            res.render("error", {error: err});
        } else {
            req.db.query('SELECT * FROM SeatDistribution;', function (err, result) {
                if (err) {
                    res.render("error", {error: err});
                } else {
                    res.json(result.rows);
                }
            });
        }
        // req.db.end();
    });
});

// Q2: Delegates of the Bundestag

router.get(/^\/q2(\/([0-9]{2}|[0-9]{4}))?\/?$/i, function(req, res, next) {
    res.redirect(301, '');
});

router.get(/^\/delegates(\/([0-9]{2}|[0-9]{4}))?\/?$/i, function(req, res, next) {
    var year = parseYear(req.params[1]);
    // get overview data for year
    res.render('delegates', { year: year, data: [] });
});

// Q3: Wahlkreis overview

router.get(/^\/q3(\/([0-9]{2}|[0-9]{4}))?\/?$/i, function(req, res, next) {
    res.redirect(301, '');
});

router.get(/^\/wahlkreise(\/([0-9]{2}|[0-9]{4}))?\/?$/i, function(req, res, next) {
    var year = parseYear(req.params[1]);
    // get overview data for year
    res.render('wahlkreise-all', { year: year, data: [] });
});

router.get(/^\/q3(\/([0-9]{2}|[0-9]{4}))?\/wk\/([0-9]{1,3})\/?$/i, function(req, res, next) {
    res.redirect(301, '');
});

router.get(/^\/wahlkreise(\/([0-9]{2}|[0-9]{4}))?\/wk\/([0-9]{1,3})\/?$/i, function(req, res, next) {
    var year = parseYear(req.params[1]);
    // get overview data for year
    res.render('wahlkreise-single', { year: year, data: [] });
});

// Q4: Wahlkreis winners

router.get(/^\/q4(\/([0-9]{2}|[0-9]{4}))?\/?$/i, function(req, res, next) {
    res.redirect(301, '');
});

router.get(/^\/wahlkreise(\/([0-9]{2}|[0-9]{4}))?\/winners\/?$/i, function(req, res, next) {
    var year = parseYear(req.params[1]);
    // get overview data for year
    res.render('wahlkreise-single', { year: year, data: [] });
});

// Q5: Überhangsmandate

router.get(/^\/q5(\/([0-9]{2}|[0-9]{4}))?\/?$/i, function(req, res, next) {
    res.redirect(301, '');
});

router.get(/^\/ueberhangsmandate(\/([0-9]{2}|[0-9]{4}))?\/?$/i, function(req, res, next) {
    var year = parseYear(req.params[1]);
    // get overview data for year
    res.render('ueberhangsmandate', { year: year, data: [] });
});

// Q6: Closest winners

router.get(/^\/q6(\/([0-9]{2}|[0-9]{4}))?\/?$/i, function(req, res, next) {
    res.redirect(301, '');
});

router.get(/^\/closest-winners(\/([0-9]{2}|[0-9]{4}))?\/?$/, function(req, res, next) {
    var year = parseYear(req.params[1]);
    // get overview data for year
    res.render('wahlkreise-single', { year: year, data: [] });
});

router.get(/^\/q6(\/([0-9]{2}|[0-9]{4}))?\/([A-Za-z_]+)\/?$/i, function(req, res, next) {
    res.redirect(301, '');
});

router.get(/^\/closest-winners(\/([0-9]{2}|[0-9]{4}))?\/([A-Za-z_]+)\/?$/, function(req, res, next) {
    var year = parseYear(req.params[1]);
    // get overview data for year
    res.render('wahlkreise-single', { year: year, data: [] });
});

// Q7: Wahlkreis overview again

router.get(/^\/q7(\/([0-9]{2}|[0-9]{4}))?\/wk\/([0-9]{1,3})\/slow\/?$/, function(req, res, next) {
    res.redirect(301, '');
});

router.get(/^\/wahlkreise(\/([0-9]{2}|[0-9]{4}))?\/wk\/([0-9]{1,3})\/slow\/?$/, function(req, res, next) {
    var year = parseYear(req.params[1]);
    // get overview data for year
    res.render('wahlkreise-single', { year: year, data: [] });
});


module.exports = router;
