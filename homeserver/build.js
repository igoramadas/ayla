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

// UPDATE DOCUMENTATION

groc.CLI("", function(err, results) {console.log("Groc result", err, results)});