$.fn.colorPicker = function (conf) {

    // Default colours to be used in case no data is specified.
    var defaultColours = [
        "#FFFFFF", "#FFFFAA", "#FFFF55", "#FFFF00",
        "#FFAAFF", "#FFAAAA", "#FFAA55", "#FFAA00",
        "#FF55FF", "#FF55AA", "#FF5555", "#FF5500",
        "#FF00FF", "#FF00AA", "#FF0055", "#FF0000",
        "#AAFFFF", "#AAFFAA", "#AAFF55", "#AAFF00",
        "#AAAAFF", "#AAAAAA", "#AAAA55", "#AAAA00",
        "#AA55FF", "#AA55AA", "#AA5555", "#AA5500",
        "#AA00FF", "#AA00AA", "#AA0055", "#AA0000",
        "#55FFFF", "#55FFAA", "#55FF55", "#55FF00",
        "#55AAFF", "#55AAAA", "#55AA55", "#55AA00",
        "#5555FF", "#5555AA", "#555555", "#555500",
        "#5500FF", "#5500AA", "#550055", "#550000",
        "#00FFFF", "#00FFAA", "#00FF55", "#00FF00",
        "#00AAFF", "#00AAAA", "#00AA55", "#00AA00",
        "#0055FF", "#0055AA", "#005555", "#005500",
        "#0000FF", "#0000AA", "#000055"
    ];

    // Default configuration.
    var config = $.extend({
        id: "jquery-colourpicker",
        title: "Choose a colour...",
        colours: defaultColours
    }, conf);

    // Helper to get text color (black or white).
    var hexInvert = function (hex) {
        hex = hex.replace("#", "");

        var r = hex.substr(0, 2);
        var g = hex.substr(2, 2);
        var b = hex.substr(4, 2);

        return 0.212671 * r + 0.715160 * g + 0.072169 * b < 0.5 ? "#FFFFFF" : "#000000"
    };

    var docBody = $(document.body);
    var colorPicker = $("#" + config.id);

    // Add the colorPicker dialogue, if not added yet.
    if (!colorPicker.length) {
        colorPicker = $(document.createElement("div"));
        colorPicker.attr("id", config.id);
        colorPicker.appendTo(document.body).hide();

        // Remove the colorPicker if you click outside.
        docBody.on("click", function(e) {
            var target = $(e.target);
            if (!(target.is("#" + config.id) || target.parents("#" + config.id).length)) {
                if (!target.hasClass("colourpicker")) {
                    colorPicker.hide();
                }
            }
        });
    }

    // For every select passed to the plugin...
    return this.each(function () {
        var source = $(this);
        var dataColours = source.data("colours");
        var colours = config.colours;
        var list = "";

        // If source is already set up then stop there.
        if (source.hasClass("colourpicker")) {
            return;
        }

        // Set field properties and class.
        source.attr("type", "text").addClass("colourpicker");

        // Get colours from data field in case there's one.
        if (dataColours && dataColours.length > 0) {
            colours = dataColours;
        }

        // Iterate colours to create list options.
        for (var c = 0; c < colours.length; c++) {
            list += '<li><a rel="' + colours[c] + '" style="background: ' + colours[c] + '">' + colours[c] + '</a></li>';
        }

        // When you click the field, show the color picker.
        source.on("click", function() {
            var pos	= source.offset();
            colorPicker.empty();

            colorPicker.html("<ul>" + list + "</ul>").css({
                left: (pos.left + source.outerWidth()) + "px",
                top: pos.top + "px"
            }).show();

            // When you click a colour in the color picker...
            $("a", colorPicker).off("click");

            $("a", colorPicker).on("click", function () {
                var hex = $(this).attr("rel");
                source.val(hex);
                source.css({background: hex, color: hexInvert(hex)});
                source.change();
                colorPicker.hide();

                return false;
            });
        });

        // Reflect changes on the field to match its background color.
        source.on("change", function() {
            var hex = source.val();
            source.css({background: hex, color: hexInvert(hex)});
        });

        source.change();
    });
};