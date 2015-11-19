var express = require('express');
var router = express.Router();

router.get(/^\/overview\/([0-9]{2}|[0-9]{4})\/?$/, function(req, res, next) {
    // get overview data for req.params[0]
    res.json({ year: req.params[0], data: [] });
});

router.get(/^\/seat-distribution\/([0-9]{2}|[0-9]{4})\/?$/, function(req, res, next) {
    // get overview data for req.params[0]
    res.json({ year: req.params[0], data: [] });
});

module.exports = router;
