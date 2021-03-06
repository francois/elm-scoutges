import './main.css';
import { Elm } from './Main.elm';
import * as serviceWorker from './serviceWorker';

function storageAvailable(type) {
    var storage;
    try {
        storage = window[type];
        var x = '__storage_test__';
        storage.setItem(x, x);
        storage.removeItem(x);
        return true;
    } catch(e) {
        return e instanceof DOMException && (
            // everything except Firefox
            e.code === 22 ||
            // Firefox
            e.code === 1014 ||
            // test name field too, because code might not be present
            // everything except Firefox
            e.name === 'QuotaExceededError' ||
            // Firefox
            e.name === 'NS_ERROR_DOM_QUOTA_REACHED') &&
            // acknowledge QuotaExceededError only if there's something already stored
            (storage && storage.length !== 0);
    }
}

var token = null;
if (storageAvailable("localStorage")) {
  token = localStorage.getItem("jwt-token");
  if (token === undefined) {
    token = null;
  }
}

let app = Elm.Main.init({
  node: document.getElementById('root'),
  flags: { token, now: Date.now() }
});

app.ports.manageJwtToken.subscribe(function(tuple) {
  if (storageAvailable("localStorage")) {
    if (tuple[0] == "set") {
      localStorage.setItem("jwt-token", tuple[1]);
    } else if (tuple[0] == "clear" ) {
      localStorage.removeItem("jwt-token");
    }
  }
});

// If you want your app to work offline and load faster, you can change
// unregister() to register() below. Note this comes with some pitfalls.
// Learn more about service workers: https://bit.ly/CRA-PWA
serviceWorker.unregister();
