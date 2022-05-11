var token = '';
var r = Math.round(Math.random()*100);

$(document).ready(function(){
    hash = location.hash.substring(1) || "";
    processAuth(function() {
        if(hash.indexOf("code=") == 0) {
            getTokenRedirect(loginRequest)
                .then(response => {
                    token = response.accessToken;
                    if(!localStorage.getItem("token")) {
                        localStorage.setItem("token", sha256(token));
                    }
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

var waitTimer;

function setup() {
    $.ajaxSetup({
        beforeSend: function (xhr) {
            if(token) {
                xhr.setRequestHeader('Authorization', 'Bearer ' + token);
            }
        }
    });
    var state = {};
    waitTimer = wait(waitTimer);
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
    $("#user").click(function() {
        if($("main").is(":visible")) {
            updateColors("empty");
            $("#user").text("❌")
        } else {
            waitTimer = wait(waitTimer);
            $.get("/state").then(response => {
                $("#user").text("👤")
                update(state, response, waitTimer)
            }, auth);
        }
        generateCode();
        $("main").toggle();
        $("#user-page").toggle();
    })
    $("#reset-button").click(function() {
        localStorage.removeItem("token");
        localStorage.setItem("reset", true);
        waitTimer = wait(waitTimer);
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
                waitTimer = wait(waitTimer);
                var updating = false;
                setTimeout(() => {
                    if(!updating){
                        reset();
                    }
                }, 200);
                $.get("/state").then(response => {
                    updating = true;
                    update(state, response, waitTimer);
                }, auth);
            }
        })
    }, 2000);
    if(localStorage.getItem("reset")) {
        localStorage.removeItem("reset")
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
        url = "https://ponyparker.herokuapp.com/#" + localStorage.getItem("token")
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
