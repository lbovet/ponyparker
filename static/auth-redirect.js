const myMSALObj = new msal.PublicClientApplication(msalConfig);

let username = "";

function processAuth(nextStep) {
    if (location.hostname === "localhost" || location.hostname === "127.0.0.1") {
        return nextStep();
    }
    myMSALObj.handleRedirectPromise()
        .then(handleResponse)
        .catch((error) => {
            console.error(error);
        })
        .finally(nextStep);
}

function selectAccount () {
    const currentAccounts = myMSALObj.getAllAccounts();
    if (currentAccounts.length === 0) {
        return;
    } else {
        username = currentAccounts[0].username;
    }
}

function handleResponse(response) {
    if (response !== null) {
        username = response.account.username;
    } else {
        selectAccount();
    }
}

function signIn() {
    myMSALObj.loginRedirect(loginRequest);
}

function getTokenRedirect(request) {
    request.account = myMSALObj.getAccountByUsername(username);
    return myMSALObj.acquireTokenSilent(request)
        .catch(error => {
            console.warn("silent token acquisition fails. acquiring token using redirect");
            if (error instanceof msal.InteractionRequiredAuthError) {
                // fallback to interaction when silent call fails
                return myMSALObj.acquireTokenRedirect(request);
            } else {
                console.warn(error);
            }
        });
}
