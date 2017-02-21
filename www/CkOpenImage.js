var exec = require('cordova/exec');

exports.open = function(url, title, options, successCallback, errorCallback) {
    if (title == undefined) {
        title = '';
    }

    if (typeof options == "undefined") {
        options = {};
    }

    exec(successCallback, errorCallback, "CkOpenImage", "open", [url, title, options]);
};
