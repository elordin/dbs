window.onload = function () {

    var submitButton = document.getElementById('submit');

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

    overlay.addEventListener('click', function (e) {
        document.body.removeChild(overlay);
        document.body.removeChild(modal);
    });

    console.log(spanES);
    console.log(spanZS);

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
    Array.prototype.map.call(radios, function (radio) {
        if (radio.checked) {
            return radio.nextElementSibling.cloneNode(true);
        }
    });
    return false;
}
