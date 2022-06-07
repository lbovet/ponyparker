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
    if(!mobileCheck()) {
        $(".top-tool").show();
    }
});

window.mobileCheck = function () {
    let check = false;
    (function (a) { if (/(android|bb\d+|meego).+mobile|avantgo|bada\/|blackberry|blazer|compal|elaine|fennec|hiptop|iemobile|ip(hone|od)|iris|kindle|lge |maemo|midp|mmp|mobile.+firefox|netfront|opera m(ob|in)i|palm( os)?|phone|p(ixi|re)\/|plucker|pocket|psp|series(4|6)0|symbian|treo|up\.(browser|link)|vodafone|wap|windows ce|xda|xiino/i.test(a) || /1207|6310|6590|3gso|4thp|50[1-6]i|770s|802s|a wa|abac|ac(er|oo|s\-)|ai(ko|rn)|al(av|ca|co)|amoi|an(ex|ny|yw)|aptu|ar(ch|go)|as(te|us)|attw|au(di|\-m|r |s )|avan|be(ck|ll|nq)|bi(lb|rd)|bl(ac|az)|br(e|v)w|bumb|bw\-(n|u)|c55\/|capi|ccwa|cdm\-|cell|chtm|cldc|cmd\-|co(mp|nd)|craw|da(it|ll|ng)|dbte|dc\-s|devi|dica|dmob|do(c|p)o|ds(12|\-d)|el(49|ai)|em(l2|ul)|er(ic|k0)|esl8|ez([4-7]0|os|wa|ze)|fetc|fly(\-|_)|g1 u|g560|gene|gf\-5|g\-mo|go(\.w|od)|gr(ad|un)|haie|hcit|hd\-(m|p|t)|hei\-|hi(pt|ta)|hp( i|ip)|hs\-c|ht(c(\-| |_|a|g|p|s|t)|tp)|hu(aw|tc)|i\-(20|go|ma)|i230|iac( |\-|\/)|ibro|idea|ig01|ikom|im1k|inno|ipaq|iris|ja(t|v)a|jbro|jemu|jigs|kddi|keji|kgt( |\/)|klon|kpt |kwc\-|kyo(c|k)|le(no|xi)|lg( g|\/(k|l|u)|50|54|\-[a-w])|libw|lynx|m1\-w|m3ga|m50\/|ma(te|ui|xo)|mc(01|21|ca)|m\-cr|me(rc|ri)|mi(o8|oa|ts)|mmef|mo(01|02|bi|de|do|t(\-| |o|v)|zz)|mt(50|p1|v )|mwbp|mywa|n10[0-2]|n20[2-3]|n30(0|2)|n50(0|2|5)|n7(0(0|1)|10)|ne((c|m)\-|on|tf|wf|wg|wt)|nok(6|i)|nzph|o2im|op(ti|wv)|oran|owg1|p800|pan(a|d|t)|pdxg|pg(13|\-([1-8]|c))|phil|pire|pl(ay|uc)|pn\-2|po(ck|rt|se)|prox|psio|pt\-g|qa\-a|qc(07|12|21|32|60|\-[2-7]|i\-)|qtek|r380|r600|raks|rim9|ro(ve|zo)|s55\/|sa(ge|ma|mm|ms|ny|va)|sc(01|h\-|oo|p\-)|sdk\/|se(c(\-|0|1)|47|mc|nd|ri)|sgh\-|shar|sie(\-|m)|sk\-0|sl(45|id)|sm(al|ar|b3|it|t5)|so(ft|ny)|sp(01|h\-|v\-|v )|sy(01|mb)|t2(18|50)|t6(00|10|18)|ta(gt|lk)|tcl\-|tdg\-|tel(i|m)|tim\-|t\-mo|to(pl|sh)|ts(70|m\-|m3|m5)|tx\-9|up(\.b|g1|si)|utst|v400|v750|veri|vi(rg|te)|vk(40|5[0-3]|\-v)|vm40|voda|vulc|vx(52|53|60|61|70|80|81|83|85|98)|w3c(\-| )|webc|whit|wi(g |nc|nw)|wmlb|wonu|x700|yas\-|your|zeto|zte\-/i.test(a.substr(0, 4))) check = true; })(navigator.userAgent || navigator.vendor || window.opera);
    return check;
};

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
                    $("#smiley").text("🚘").show();
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
