const myMSALObj = new msal.PublicClientApplication(msalConfig);

let username = "";

myMSALObj.handleRedirectPromise()
    .then(handleResponse)
    .catch((error) => {
        console.error(error);
    });

function selectAccount () {

    const currentAccounts = myMSALObj.getAllAccounts();
    if (currentAccounts.length === 0) {
        return;
    } else if (currentAccounts.length >= 1) {
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
