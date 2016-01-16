var express = require('express');
var router = express.Router();

var query_routes = require('./query');
var vote_routes = require('./vote');

router.use('/', query_routes);
router.use('/vote', vote_routes);
router.use('/impressum', function (req, res) {
    res.render('impressum');
});

module.exports = router;
