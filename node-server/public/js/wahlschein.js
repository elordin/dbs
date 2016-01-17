window.onload = function () {

    var submitButton = document.getElementById('submitButton');

    submitButton.addEventListener('click', function (e) {

        e.preventDefault();
        e.stopPropagation();

        showModal();

    });
};


function showModal() {

    var overlay = document.createElement('div');
        overlay.classList.add('overlay');

    var modal = document.createElement('div');
        modal.classList.add('card');
        modal.classList.add('modal');

    var title = document.createElement('h2');
        title.innerHTML = 'Sie w&auml;hlen:';

    var titleES = document.createElement('h3');
        titleES.innerHTML = 'Erststimme:';

    var spanES = radioLabelTextSpan("erststimme");

    var titleZS = document.createElement('h3');
        titleZS.innerHTML = 'Zweitstimme:';

    var spanZS = radioLabelTextSpan("zweitstimme");

    var commitButton = document.createElement('button');
        commitButton.classList.add('green');
        commitButton.innerHTML = 'Ja, Stimmzettel abgeben';
    var abortButton = document.createElement('button');
        abortButton.classList.add('red');
        abortButton.innerHTML = 'Nein, ich möchte meine Entscheidung noch einmal ändern';

    abortButton.addEventListener('click', function (e) {
        document.body.removeChild(overlay);
        document.body.removeChild(modal);
    });

    commitButton.addEventListener('click', function (e) {
        var form = document.getElementById('stimmzettel');
        form.submit();
    });

    overlay.addEventListener('click', function (e) {
        document.body.removeChild(overlay);
        document.body.removeChild(modal);
    });


    modal.appendChild(title);
    modal.appendChild(titleES);
    modal.appendChild(spanES);
    modal.appendChild(titleZS);
    modal.appendChild(spanZS);
    modal.appendChild(commitButton);
    modal.appendChild(abortButton);

    document.body.appendChild(overlay);
    document.body.appendChild(modal);

}


function radioLabelTextSpan(radioGroupName) {
    var radios = document.body.querySelectorAll('input[type="radio"][name="' + radioGroupName + '"]');
    var checkedRadios = Array.prototype.filter.call(radios, function (radio) {
        return radio.checked;
    });
    if (checkedRadios.length != 1)
        return document.querySelector('.validity input[type="radio"][name="' + radioGroupName + '"]').nextElementSibling.cloneNode(true);
    else
        return checkedRadios[0].nextElementSibling.cloneNode(true);
}
