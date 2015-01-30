$.fn.colorPicker = function (conf) {

    // Default colors to be used in case no data is specified.
    var defaultColors = [
        "#FFFFFF", "#FFFFDD", "#FFFFBB", "#FFFF99", "#FFFF77", "#FFFF55", "#FFFF33", "#FFFF11",
        "#FFEEEE", "#FFCCCC", "#FFAAAA", "#FF8888", "#FF6666", "#FF4444", "#FF2222", "#FF1111",
        "#EEFFEE", "#CCFFCC", "#AAFFAA", "#88FF88", "#66FF66", "#44FF44", "#22FF22", "#00FF00",
        "#EEEEFF", "#CCCCFF", "#AAAAFF", "#8888FF", "#6666FF", "#4444FF", "#2222FF", "#0000FF",
        "#FFEEFF", "#FFCCFF", "#FFAAFF", "#FF88FF", "#FF66FF", "#FF44FF", "#FF22FF", "#FF00FF",
        "#EEFFFF", "#CCFFFF", "#AAFFFF", "#88FFFF", "#66FFFF", "#44FFFF", "#22FFFF", "#00FFFF",
        "#EEEEEE", "#CCCCCC", "#AAAAAA", "#888888", "#666666", "#444444", "#222222", "#000000"
    ];

    // Default configuration.
    var config = $.extend({
        id: "jquery-colorpicker",
        title: "Choose a color...",
        colors: defaultColors
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
                if (!target.hasClass("colorpicker")) {
                    colorPicker.hide();
                }
            }
        });
    }

    // For every select passed to the plugin...
    return this.each(function () {
        var source = $(this);

        // If source is already set up then stop here.
        if (source.hasClass("colorpicker")) {
            return;
        }

        var dataColors = source.data("colors");
        var colors = config.colors;
        var isInput = source.prop("tagName") === "INPUT";

        // Set field properties and class.
        source.attr("type", "text").addClass("colorpicker");

        if (isInput) {
            source.attr("type", "text");
        }

        // Get colors from data field in case there's one.
        if (dataColors && dataColors.length > 0) {
            colors = dataColors;
        }

        // When you click the field, show the color picker.
        source.on("click", function(e) {
            e.preventDefault();
            source.blur();

            var val = source.val();
            var title = $(document.createElement("div"));
            var ul = $(document.createElement("ul"));
            var li, a;

            // Clear color picker box.
            colorPicker.empty();

            // Iterate colors to create list options.
            for (var c = 0; c < colors.length; c++) {
                li = $(document.createElement("li"));
                li.attr("rel", colors[c]).css("background", colors[c]);

                if (val == colors[c]) {
                    li.addClass("selected");
                }

                ul.append(li);
            }

            // Set title.
            title.html(source.attr("title"));

            // Append colors to HTML.
            colorPicker.append(title).append(ul).show();

            // Unbind previous click events.
            $("li", colorPicker).off("click");

            // When you click a color in the color picker...
            $("li", colorPicker).on("click", function () {
                var hex = $(this).attr("rel");
                source.val(hex);
                source.css({background: hex, color: hexInvert(hex)});
                source.change();
                colorPicker.hide();

                return false;
            });

            return true;
        });

        // Reflect changes on the field to match its background color.
        source.on("change", function() {
            var hex = source.val();
            source.css({background: hex, color: hexInvert(hex)});
            return true;
        });

        source.change();
    });
};
