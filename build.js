var a, expresser, filename, fs, privateSettings, privateSettingsObj, maxDepth;

expresser = require("expresser");
fs = require("fs");
groc = require("groc");
lodash = expresser.libs.lodash;

// GENERATE SAMPLE FOR SETTINGS.PRIVATE.JSON

filename = expresser.utils.getFilePath("settings.private.json");

maxDepth = 4;

getValueType = function(v) {
    return v.constructor.toString().split(" ")[1].replace("()", "");
};

if (filename != null) {
    privateSettings = fs.readFileSync(filename, {encoding: "utf8"});
    privateSettingsObj = expresser.utils.minifyJson(privateSettings);

    var reset = function(source, depth) {
        if (depth > maxDepth) return;

        var prop, value;

        for (prop in source) {
            value = source[prop];

            if (lodash.isObject(value)) {
                reset(source[prop], depth + 1);
            } else if (lodash.isArray(value)) {
                for (a = 0; a < value.length; a++) {
                    if (lodash.isObject(value[a])) {
                        reset(value[a], depth + 1);
                    } else {
                        value[a] = getValueType(value[a]);
                    }
                }
            } else {
                source[prop] = getValueType(value);
            }
        }
    };

    reset(privateSettingsObj, 0);

    filename = __dirname + "/settings.private.json.sample";
    fs.writeFileSync(filename, JSON.stringify(privateSettingsObj, null, 4));
}

// UPDATE DOCUMENTATION

groc.CLI("", function(err, results) {console.log("Groc result", err, results)});
