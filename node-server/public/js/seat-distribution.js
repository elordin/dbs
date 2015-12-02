window.onload = function () {
    var seatsTotal = data.reduce(function (i, e) {
        return i + parseInt(e.seats);
    }, 0);
    var radius = 200;
    var seatOffset = 0;

    var svg = d3.select('.pie-chart')
        .append('svg')
        .attr('width', '400px')
        .attr('height', '200px');

    function makeChart(d,i) {
        var angle1 = (1 - seatOffset / seatsTotal) * Math.PI;
        var xsi = Math.floor(100 * (200 + Math.cos(angle1) * 100)) / 100;
        var ysi = Math.floor(100 * (200 - Math.sin(angle1) * 100)) / 100;
        var xso = Math.floor(100 * (200 + Math.cos(angle1) * 200)) / 100;
        var yso = Math.floor(100 * (200 - Math.sin(angle1) * 200)) / 100;
        seatOffset += parseInt(d.seats);

        var path = 'M' + xsi + ' ' + ysi +
                  ' L' + xso + ' ' + yso;

        var angle2 = (1 - seatOffset / seatsTotal) * Math.PI;
        var xei = Math.floor(100 * (200 + Math.cos(angle2) * 100)) / 100;
        var yei = Math.floor(100 * (200 - Math.sin(angle2) * 100)) / 100;
        var xeo = Math.floor(100 * (200 + Math.cos(angle2) * 200)) / 100;
        var yeo = Math.floor(100 * (200 - Math.sin(angle2) * 200)) / 100;

        var minAngle = (2 / 180 * 2 * Math.PI);

        var steps = Math.floor(100 * ((angle1 - angle2) / minAngle)) / 100;

        var fwd = [];
        var bwd = [];

        var angle, x, y, j;
        for (j = 1; j < steps; j++) {
            angle = angle1 - minAngle * j;
            // fwd.push({
                x = Math.floor(100 * (200 + Math.cos(angle) * 200)) / 100;
                y = Math.floor(100 * (200 - Math.sin(angle) * 200)) / 100;
                path += ' L' + x + ' ' + y;
        }

        path += ' L' + xeo + ' ' + yeo +
                ' L' + xei + ' ' + yei;


        for (j = 1; j < steps; j++) {
            angle = angle2 + minAngle * j;
            // fwd.push({
                x = Math.floor(100 * (200 + Math.cos(angle) * 100)) / 100;
                y = Math.floor(100 * (200 - Math.sin(angle) * 100)) / 100;
                path += ' L' + x + ' ' + y;
        }

        path += ' Z';
        return path;
    }

    svg.selectAll('.data-point').data(data).enter()
        .append('path')
        .attr('d', makeChart)
        .attr('fill', function (d) { return d.colourcode; })
        .attr('stroke', '#fff')
        .attr('stroke-width', '1px')
        .attr('data-party', function (d) { return d.name; })
        .attr('data-shorthand', function (d) { return d.shorthand; })
        .attr('data-seats', function (d) { return d.seats; })
        .attr('class', function (d) { return d.shorthand + ' data-point'; })
        .on('mouseover', function (d, i) {
            d3.select(this).attr('stroke-width', '4px');
            svg.append('text')
                .attr('class', 'tooltip')
                .text(d.shorthand)
                .attr('x', 200)
                .attr('y', 130)
                .attr('style', 'text-anchor: middle; dominant-baseline: hanging;')
                .attr('fill', '#333');
            svg.append('text')
                .attr('class', 'tooltip')
                .text(d.seats)
                .attr('x', 200)
                .attr('y', 150)
                .attr('style', 'text-anchor: middle; dominant-baseline: hanging;')
                .attr('fill', '#333');
        })
        .on('mouseout', function (d, i) {
            d3.select(this).attr('stroke-width', '1px');
            d3.selectAll('.tooltip').remove();
        });

    var tableBody = document.getElementById('seats');
    var sortable = Sortable.create(tableBody, {
        sort: true,  // sorting inside list
        delay: 0, // time in milliseconds to define when the sorting should start
        disabled: false, // Disables the sortable if set to true.
        animation: 150,  // ms, animation speed moving items when sorting, `0` — without animation
        scroll: true, // or HTMLElement
        scrollSensitivity: 30, // px, how near the mouse must be to an edge to start scrolling.
        scrollSpeed: 10, // px

        handle: '.handle',

        // dragging ended
        onEnd: function (e) {
            for (var i = 0, out = []; i < data.length; i++) {
                if (e.oldIndex < e.newIndex) {
                    if (i < e.oldIndex) {
                        out.push(data[i]);
                    } else if (i >= e.oldIndex && i < e.newIndex) {
                        out.push(data[i + 1]);
                    } else if (i == e.newIndex) {
                        out.push(data[e.oldIndex]);
                    } else if (i > e.newIndex) {
                        out.push(data[i]);
                    }
                } else {
                    if (i < e.newIndex) {
                        out.push(data[i]);
                    } else if (i == e.newIndex) {
                        out.push(data[e.oldIndex]);
                    } else if (i > e.newIndex && i <= e.oldIndex) {
                        out.push(data[i - 1]);
                    } else if (i > e.oldIndex) {
                        out.push(data[i]);
                    }
                }
            }
            data = out;
            seatOffset = 0;
            svg.selectAll('.data-point').data(data).attr('d', makeChart)
                .attr('fill', function (d) { return d.colourcode; })
                .attr('data-party', function (d) { return d.name; })
                .attr('data-shorthand', function (d) { return d.shorthand; })
                .attr('data-seats', function (d) { return d.seats; })
                .attr('class', function (d) { return d.shorthand + ' data-point'; })
                .on('mouseover', function (d, i) {
                    d3.select(this).attr('stroke-width', '4px');
                    svg.append('text')
                        .attr('class', 'tooltip')
                        .text(d.name)
                        .attr('x', 200)
                        .attr('y', 130)
                        .attr('style', 'text-anchor: middle; dominant-baseline: hanging;')
                        .attr('fill', '#333');
                    svg.append('text')
                        .attr('class', 'tooltip')
                        .text(d.seats)
                        .attr('x', 200)
                        .attr('y', 150)
                        .attr('style', 'text-anchor: middle; dominant-baseline: hanging;')
                        .attr('fill', '#333');
                });
        }
    });
};
