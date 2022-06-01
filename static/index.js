var token = '';
var r = Math.round(Math.random()*100);

$(document).ready(function(){
    hash = location.hash.substring(1) || "";
    processAuth(function() {
        if(hash.indexOf("code=") == 0) {
            getTokenRedirect(loginRequest)
                .then(response => {
                    token = response.accessToken;
                    location.hash = "";
                    console.log("redirect [" + hash + "] "+r)
                    setup();
                }).catch(error => {
                    console.error(error);
                });
        } else {
            console.log("direct ["+hash+"] "+r)
            if(hash && hash != "#") {
                token = hash
                localStorage.setItem("token", token);
            } else {
                token = localStorage.getItem("token");
            }
            location.hash = "";
            setup();
        }
    });
});

var state = {};
var waitTimer;

function setup() {
    $.ajaxSetup({
        beforeSend: function (xhr) {
            if(token) {
                xhr.setRequestHeader('Authorization', 'Bearer ' + token);
            }
        }
    });
    waitTimer = wait();
    $("#action").click(function() {
        $("#action").prop("disabled", true);
        waitTimer = wait();
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
    $("#user").click(function() {
        clearInterval(waitTimer)
        if($("main").is(":visible")) {
            updateColors("empty");
            $("#user").text("❌")
        } else {
            waitTimer = wait();
            $.get("/state").then(response => {
                $("#user").text("👤")
                update(state, response, waitTimer)
            }, auth);
        }
        if(localStorage.getItem("reset-token")) {
            generateCode();
            localStorage.removeItem("reset-token")
            $("#copy-button").prop("disabled", false);
        }
        $("main").toggle();
        $("#user-page").toggle();
    })
    $("#reset-button").click(function() {
        localStorage.removeItem("token");
        localStorage.setItem("reset-token", true);
        waitTimer = wait();
        $.ajax("/token", { type: "DELETE" }).then(response => {
            update(state, response, waitTimer)
        }, auth);
    });
    $("#copy-button").click(function() {
        navigator.clipboard.writeText(url);
    });
    setTimeout(function() {
        $(window).focus(function () {
            if ($("main").is(":visible")) {
                waitTimer = wait();
                var updating = false;
                setTimeout(() => {
                    if(!updating){
                        reset();
                    }
                }, 200);
                $.get("/state").then(response => {
                    if ($("main").is(":visible")) {
                        updating = true;
                        update(state, response, waitTimer);
                    }
                }, auth);
            }
        })
    }, 2000);
    if(localStorage.getItem("reset-token")) {
        $.get("/state");
        $("#user").click();
    } else {
        $.get("/state").then(response => {
            update(state, response, waitTimer)
        }, auth);
    }
};

function updateTexts(day, action, status, message) {
    $("#day").text(day);
    $("#action").text(action);
    $("#status").text(status);
    $("#message").text(message);
}

function reset() {
    updateColors("empty");
    updateTexts("", "", "", "");
    $("#action").hide().prop("disabled", true);
    $("#smiley").text("").show()
}

const waitSequence = ["🤨", "🤔", "🥴", "🥵"];

var url;

function generateCode() {
    if(!url) {
        url = "https://ponyparker.herokuapp.com/#" + sha256(token)
        new QRCode(document.getElementById("qrcode"), {
            text: url,
            width: 300,
            height: 300,
            colorDark: "#000000",
            colorLight: "#ffffff00",
            correctLevel: QRCode.CorrectLevel.H
        });
    }
}

function wait() {
    var i = 0;
    clearInterval(waitTimer)
    return setInterval(function() {
        reset();
        if(++i == waitSequence.length) {
            $.get("/state").then(response => {
                update(state, response, waitTimer)
            }, auth);
        }
        i = i % waitSequence.length;
        $("#smiley").text(waitSequence[i]);
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
    updateLock(function(lockReason) {
        clearInterval(waitTimer)
        $("#action").prop("disabled", false).show();
        day = new Date().getHours() < 14 ? "Aujourd'hui" : "Demain"
        $("#smiley").hide()
        if (lockReason) {
            state.status = "refused";
            updateTexts(day, "XXXXXXX", "Place bloquée", lockReason);
            $("#action").hide().prop("disabled", true);
            $("#smiley").text("🚫").show();
        } else {
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
                    break;
                case 4:
                    state.status = "refused";
                    updateTexts(day, "XXXXXXX", "Place occupée", response.winner ? "par " + response.winner : "");
                    $("#action").hide().prop("disabled", true);
                    $("#smiley").text("🙁").show();
                    break;
                }
        }
        updateColors(state.status);
    });
}

var lockUpdated = null;
var lockReason = null;

function updateLock(nextStep) {
    if (lockUpdated == null || lockUpdated < new Date().getTime() - 5 * 60 * 1000) {
        $.get("/locks.ics").then(response => {
            var plannedDay = new Date(new Date().getTime()+(24-14)*3600*1000).toDateString();
            lockReason =
                Object.values(ical.parseICS(response))
                    .filter(ev => ev.type == "VEVENT")
                    .filter(ev => ev.start.toDateString() == plannedDay)
                    .map(ev => ev.summary)
                    .shift()
            lockUpdated = new Date().getTime()
            nextStep(lockReason)
        }, auth);
    } else {
        nextStep(lockReason)
    }
}

function auth(error) {
    if(error.status == 401 || error.status == 418) {
        console.log("auth error "+r)
        signIn();
    }
    if(error.status == 403) {
        localStorage.removeItem("token");
        clearInterval(waitTimer);
        reset();
        $("#smiley").text("⛔");
    }
}
