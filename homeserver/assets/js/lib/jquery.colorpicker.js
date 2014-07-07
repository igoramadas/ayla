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
        id: "jquery-colorpicker",  // id of colorpicker container
        title: "Pick a colour",    // Default dialogue title
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
        colorpicker = $('<div id="' + config.id + '"></div>').appendTo(document.body).hide();

        // Remove the colorpicker if you click outside it (on body)
        $(document.body).click(function(event) {
            if (!($(event.target).is('#' + config.id) || $(event.target).parents('#' + config.id).length)) {
                colorpicker.hide();
            }
        });
    }

    // For every select passed to the plug-in
    return this.each(function () {
        var select = $(this);
        var input = $('<input type="text" class="colorpicker" name="' + select.attr('name') + '" value="' + select.val() + '" />').insertAfter(select);
        var loc = "";

        // No options? Create default colours.
        if ($("option", select).length < 1) {
            for (var c = 0; c < defaultColors.length; c++) {
                select.append('<option value="' + defaultColors[c] + '">' + defaultColors[c] + '</option>');
            }
        }

        // Build a list of colours based on the colours in the select
        $("option", select).each(function () {
            var option	= $(this);
            var hex		= option.val();
            var title	= option.text();

            loc += '<li><a title="'
                + title
                + '" rel="'
                + hex
                + '" style="background: #'
                + hex
                + '; colour: '
                + hexInvert(hex)
                + ';">'
                + title
                + '</a></li>';
        });

        // Remove select
        select.remove();

        // If user wants to, change the input's BG to reflect the newly selected colour
        input.change(function () {
            input.css({background: '#' + input.val(), color: '#' + hexInvert(input.val())});
        });

        input.change();

        // When you click the icon
        input.click(function () {
            // Show the colorpicker next to the icon and fill it with the colours in the select that used to be there
            var pos	= input.offset();
            var heading	= config.title ? '<h2>' + config.title + '</h2>' : '';

            colorpicker.html(heading + '<ul>' + loc + '</ul>').css({
                position: 'absolute',
                left: pos.left + 'px',
                top: pos.top + 'px'
            }).show();

            // When you click a colour in the colorpicker
            $('a', colorpicker).unbind("click");
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

            return false;
        });
    });
};