

$(document).ready(function(){
    token = Math.round(Math.random() * 10);
    $.ajaxSetup({
        beforeSend: function (xhr) {
            xhr.setRequestHeader('Authorization', 'Bearer ' + token);
        }
    });
    var state = {};
    var waitTimer;
    waitTimer = wait(waitTimer);
    $.get("/state").then(response => {
        update(state, response, waitTimer)
    }, auth);
    $("#action").click(function() {
        $("#action").prop("disabled", true);
        waitTimer = wait(waitTimer);
        if (state.status == "confirmable" || state.status == "placeable") {
            $.post("/bid").then(response => {
                update(state, response, waitTimer)
            }, auth);
        }
        if (state.status == "placed" || state.status == "confirmed") {
            $.ajax("/bid", { type: "DELETE"}).then(response => {
                update(state, response, waitTimer)
            }, auth);
        }
    })
    $(window).focus(function () {
        waitTimer = wait(waitTimer);
        reset();
        $.get("/state").then(response => {
            update(state, response, waitTimer)
        }, auth);
    })
});

function updateTexts(day, action, status, message) {
    $("#day").text(day);
    $("#action").text(action);
    $("#status").text(status);
    $("#message").text(message);
}

var waitSequence = ["🤨", "🤔", "🥴", "🥵"];

function reset() {
    updateColors("empty");
    updateTexts("", "", "", "");
    $("#action").hide();
    $("#smiley").text("");
    $("#smiley").show()
    $("#action").prop("disabled", true);
}

function wait(waitTimer) {
    var i = 0;
    clearInterval(waitTimer)
    return setInterval(function() {
        reset();
        i = (i + 1) % waitSequence.length;
        $("#smiley").text(waitSequence[i])
    }, 2000);
}

function updateColors(status) {
    const className =
        (status == "confirmable" || status == "placeable") ?
        "empty" : status
    updateStatusClass($("body"), "status-" + className + "-background");
    updateStatusClass($("html"), "status-" + className + "-background");
    updateStatusClass($(".navbar"), "status-" + className + "-control");
    updateStatusClass($("#action"), "status-" + className + "-control");
    updateStatusClass($("#smiley"), "status-" + className + "-text");
    $("#action").addClass("status-" + status + "-control");
}

function updateStatusClass(element, className) {
    $(element).removeClass(function (index, className) {
        return (className.match(/(^|\s)status-\S+/g) || []).join(' ');
    });
    $(element).addClass(className)
}

function update(state, response, waitTimer) {
    clearInterval(waitTimer)
    $("#action").prop("disabled", false).show();
    day = new Date().getHours() < 14 ? "Aujourd'hui" : "Demain"
    $("#smiley").hide()
    console.log(response)
    switch (response.reservation_state) {
        case 0:
            state.status = "confirmable";
            updateTexts(day, "Réserver", "", "");
            break;
        case 1:
            state.status = "placeable";
            updateTexts(day, "Demander", "", "");
            break;
        case 2:
            state.status = "placed";
            updateTexts(day, "Annuler", "Réservation demandée", "");
            break;
        case 3:
            state.status = "confirmed";
            updateTexts(day, "Annuler", "Réservation confirmée", "pour " + response.winner);
            if (new Date().getHours() < 14 || new Date().getHours() >= 20) {
                $("#action").hide().prop("disabled", true);
                $("#smiley").text("🙂").show()
            }
            break;
        case 4:
            state.status = "refused";
            updateTexts(day, "XXXXXXX", "Place occupée", "par " + response.winner);
            $("#action").hide().prop("disabled", true);
            $("#smiley").text("🙁").show();
            break;
    }
    updateColors(state.status)
}

function auth(error) {
    if(error.status == 401) {
        signIn();
    }
}