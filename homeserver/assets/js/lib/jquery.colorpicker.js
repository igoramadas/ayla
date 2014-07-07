$.fn.colorpicker = function (conf) {
    var defaultColors = [
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

    var config = $.extend({
        id: "jquery-colorpicker",
        title: "Pick a colour",
        openTxt: "Open colour picker"
    }, conf);

    // Helper to invert a hex color.
    var hexInvert = function (hex) {
        var r = hex.substr(0, 2);
        var g = hex.substr(2, 2);
        var b = hex.substr(4, 2);

        return 0.212671 * r + 0.715160 * g + 0.072169 * b < 0.5 ? "FFFFFF" : "000000"
    };

    // Add the colorpicker dialogue if not added
    var colorpicker = $("#" + config.id);

    if (!colorpicker.length) {
        var colorpicker = $(document.createElement("div"));
        colorpicker.attr("id", config.id);
        colorpicker.appendTo(document.body).hide();

        // Remove the colorpicker if you click outside it (on body)
        $(document.body).on("click", function(event) {
            if (!($(event.target).is('#' + config.id) || $(event.target).parents('#' + config.id).length)) {
                colorpicker.hide();
            }
        });
    }

    // For every select passed to the plugin...
    return this.each(function () {
        var select = $(this);
        var val = select.val() || "#FF0000";
        var input = $(document.createElement("input"));
        var colors = [];
        var loc = "";

        // Append input to document.
        input.attr("type", "text").addClass("colorpicker").val(val).insertAfter(select);

        // No options? Use default colours.
        if ($("option", select).length < 1) {
            colors = defaultColors;
        } else {
            $("option", select).each(function () {
                colors.push(option.val());
            });
        }

        // Iterate colors to create list options.
        for (var c = 0; c < colors.length; c++) {
            loc += '<li><a rel="' + colors[c] + '" style="background: #' + colors[c] + '">' + colors[c] + '</a></li>';
        }

        // Remove select.
        select.remove();

        // If user wants to, change the input's BG to reflect the newly selected colour
        input.on("change", function(e) {
            input.css({background: "#" + input.val()});
        });

        input.change();

        // When you click the icon
        input.on("click", function(e) {
            var pos	= input.offset();
            var heading	= config.title ? '<h2>' + config.title + '</h2>' : '';

            colorpicker.html(heading + '<ul>' + loc + '</ul>').css({
                position: 'absolute',
                left: pos.left + 'px',
                top: pos.top + 'px'
            }).show();

            console.warn(colorpicker);
            console.warn(pos);

            // When you click a colour in the colorpicker
            $('a', colorpicker).off("click");
            $('a', colorpicker).click(function () {
                // The hex is stored in the link's rel-attribute
                var hex = $(this).attr('rel');

                input.val(hex);

                // If user wants to, change the input's BG to reflect the newly selected colour
                input.css({background: '#' + hex, color: '#' + hexInvert(hex)});

                // Trigger change-event on input
                input.change();

                // Hide the colorpicker and return false
                colorpicker.hide();

                return false;
            });
        });
    });
};
