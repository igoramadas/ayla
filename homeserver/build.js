var expresser, filename, fs, privateSettings, privateSettingsObj;

expresser = require("expresser");
fs = require("fs");
groc = require("groc");
lodash = expresser.libs.lodash;

// GENERATE SAMPLE FOR SETTINGS.PRIVATE.JSON

filename = expresser.utils.getFilePath("settings.private.json");

if (filename != null) {
    privateSettings = fs.readFileSync(filename, {encoding: "utf8"});
    privateSettingsObj = expresser.utils.minifyJson(privateSettings);

    var reset = function(source) {
        var prop, value;

        for (prop in source) {
            value = source[prop];
            if (lodash.keys(value).length > 0) {
                reset(source[prop]);
            } else {
                source[prop] = value.constructor.toString().split(" ")[1].replace("()", "");
            }
        }
    };

    reset(privateSettingsObj);

    filename = __dirname + "/settings.private.json.sample";
    fs.writeFileSync(filename, JSON.stringify(privateSettingsObj, null, 4));
}

// GENERATE SAMPLE FOR CRON.API.JSON

filename = expresser.utils.getFilePath("cron.api.json");

if (filename != null) {
    cronApiJson = fs.readFileSync(filename, {encoding: "utf8"});
    cronApiJsonObj = expresser.utils.minifyJson(cronApiJson);

    var reset = function(source) {
        var prop, value;

        for (prop in source) {
            value = source[prop];
            if (lodash.keys(value).length > 0) {
                reset(source[prop]);
            } else if (prop == "description") {
                source[prop] = "Run " + source["callback"];
            }
            if (source["args"]) {
                delete source["args"];
            } else if (source["schedule"] && lodash.isArray(source["schedule"])) {
                source["schedule"] = 600;
            }
        }
    };

    reset(cronApiJsonObj);

    filename = __dirname + "/cron.api.json.sample";
    fs.writeFileSync(filename, JSON.stringify(cronApiJsonObj, null, 4));
}

// UPDATE DOCUMENTATION

groc.CLI("", function(err, results) {console.log("Groc result", err, results)});