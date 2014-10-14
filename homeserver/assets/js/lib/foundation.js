/*
 * Foundation Responsive Library
 * http://foundation.zurb.com
 * Copyright 2014, ZURB
 * Free to use under the MIT license.
 * http://www.opensource.org/licenses/mit-license.php
 */

(function ($, window, document, undefined) {
    'use strict';

    var header_helpers = function (class_array) {
        var i = class_array.length;
        var head = $('head');

        while (i--) {
            if(head.has('.' + class_array[i]).length === 0) {
                head.append('<meta class="' + class_array[i] + '" />');
            }
        }
    };

    header_helpers([
        'foundation-mq-small',
        'foundation-mq-medium',
        'foundation-mq-large',
        'foundation-mq-xlarge',
        'foundation-mq-xxlarge',
        'foundation-data-attribute-namespace']);

    // Enable FastClick if present

    $(function() {
        if (typeof FastClick !== 'undefined') {
            // Don't attach to body if undefined
            if (typeof document.body !== 'undefined') {
                FastClick.attach(document.body);
            }
        }
    });

    // private Fast Selector wrapper,
    // returns jQuery object. Only use where
    // getElementById is not available.
    var S = function (selector, context) {
        if (typeof selector === 'string') {
            if (context) {
                var cont;
                if (context.jquery) {
                    cont = context[0];
                    if (!cont) return context;
                } else {
                    cont = context;
                }
                return $(cont.querySelectorAll(selector));
            }

            return $(document.querySelectorAll(selector));
        }

        return $(selector, context);
    };

    // Namespace functions.

    var attr_name = function (init) {
        var arr = [];
        if (!init) arr.push('data');
        if (this.namespace.length > 0) arr.push(this.namespace);
        arr.push(this.name);

        return arr.join('-');
    };

    var add_namespace = function (str) {
        var parts = str.split('-'),
            i = parts.length,
            arr = [];

        while (i--) {
            if (i !== 0) {
                arr.push(parts[i]);
            } else {
                if (this.namespace.length > 0) {
                    arr.push(this.namespace, parts[i]);
                } else {
                    arr.push(parts[i]);
                }
            }
        }

        return arr.reverse().join('-');
    };

    // Event binding and data-options updating.

    var bindings = function (method, options) {
        var self = this,
            should_bind_events = !S(this).data(this.attr_name(true));


        if (S(this.scope).is('[' + this.attr_name() +']')) {
            S(this.scope).data(this.attr_name(true) + '-init', $.extend({}, this.settings, (options || method), this.data_options(S(this.scope))));

            if (should_bind_events) {
                this.events(this.scope);
            }

        } else {
            S('[' + this.attr_name() +']', this.scope).each(function () {
                var should_bind_events = !S(this).data(self.attr_name(true) + '-init');
                S(this).data(self.attr_name(true) + '-init', $.extend({}, self.settings, (options || method), self.data_options(S(this))));

                if (should_bind_events) {
                    self.events(this);
                }
            });
        }
        // # Patch to fix #5043 to move this *after* the if/else clause in order for Backbone and similar frameworks to have improved control over event binding and data-options updating.
        if (typeof method === 'string') {
            return this[method].call(this, options);
        }

    };

    var single_image_loaded = function (image, callback) {
        function loaded () {
            callback(image[0]);
        }

        function bindLoad () {
            this.one('load', loaded);

            if (/MSIE (\d+\.\d+);/.test(navigator.userAgent)) {
                var src = this.attr( 'src' ),
                    param = src.match( /\?/ ) ? '&' : '?';

                param += 'random=' + (new Date()).getTime();
                this.attr('src', src + param);
            }
        }

        if (!image.attr('src')) {
            loaded();
            return;
        }

        if (image[0].complete || image[0].readyState === 4) {
            loaded();
        } else {
            bindLoad.call(image);
        }
    };

    /*
     https://github.com/paulirish/matchMedia.js
     */

    window.matchMedia = window.matchMedia || (function( doc ) {

        "use strict";

        var bool,
            docElem = doc.documentElement,
            refNode = docElem.firstElementChild || docElem.firstChild,
        // fakeBody required for <FF4 when executed in <head>
            fakeBody = doc.createElement( "body" ),
            div = doc.createElement( "div" );

        div.id = "mq-test-1";
        div.style.cssText = "position:absolute;top:-100em";
        fakeBody.style.background = "none";
        fakeBody.appendChild(div);

        return function (q) {

            div.innerHTML = "&shy;<style media=\"" + q + "\"> #mq-test-1 { width: 42px; }</style>";

            docElem.insertBefore( fakeBody, refNode );
            bool = div.offsetWidth === 42;
            docElem.removeChild( fakeBody );

            return {
                matches: bool,
                media: q
            };

        };

    }( document ));

    /*
     * jquery.requestAnimationFrame
     * https://github.com/gnarf37/jquery-requestAnimationFrame
     * Requires jQuery 1.8+
     *
     * Copyright (c) 2012 Corey Frang
     * Licensed under the MIT license.
     */

    (function($) {

        // requestAnimationFrame polyfill adapted from Erik Möller
        // fixes from Paul Irish and Tino Zijdel
        // http://paulirish.com/2011/requestanimationframe-for-smart-animating/
        // http://my.opera.com/emoller/blog/2011/12/20/requestanimationframe-for-smart-er-animating

        var animating,
            lastTime = 0,
            vendors = ['webkit', 'moz'],
            requestAnimationFrame = window.requestAnimationFrame,
            cancelAnimationFrame = window.cancelAnimationFrame,
            jqueryFxAvailable = 'undefined' !== typeof jQuery.fx;

        for (; lastTime < vendors.length && !requestAnimationFrame; lastTime++) {
            requestAnimationFrame = window[ vendors[lastTime] + "RequestAnimationFrame" ];
            cancelAnimationFrame = cancelAnimationFrame ||
                window[ vendors[lastTime] + "CancelAnimationFrame" ] ||
                window[ vendors[lastTime] + "CancelRequestAnimationFrame" ];
        }

        function raf() {
            if (animating) {
                requestAnimationFrame(raf);

                if (jqueryFxAvailable) {
                    jQuery.fx.tick();
                }
            }
        }

        if (requestAnimationFrame) {
            // use rAF
            window.requestAnimationFrame = requestAnimationFrame;
            window.cancelAnimationFrame = cancelAnimationFrame;

            if (jqueryFxAvailable) {
                jQuery.fx.timer = function (timer) {
                    if (timer() && jQuery.timers.push(timer) && !animating) {
                        animating = true;
                        raf();
                    }
                };

                jQuery.fx.stop = function () {
                    animating = false;
                };
            }
        } else {
            // polyfill
            window.requestAnimationFrame = function (callback) {
                var currTime = new Date().getTime(),
                    timeToCall = Math.max(0, 16 - (currTime - lastTime)),
                    id = window.setTimeout(function () {
                        callback(currTime + timeToCall);
                    }, timeToCall);
                lastTime = currTime + timeToCall;
                return id;
            };

            window.cancelAnimationFrame = function (id) {
                clearTimeout(id);
            };

        }

    }( jQuery ));


    function removeQuotes (string) {
        if (typeof string === 'string' || string instanceof String) {
            string = string.replace(/^['\\/"]+|(;\s?})+|['\\/"]+$/g, '');
        }

        return string;
    }

    window.Foundation = {
        name : 'Foundation',

        version : '5.4.6',

        media_queries : {
            small : S('.foundation-mq-small').css('font-family').replace(/^[\/\\'"]+|(;\s?})+|[\/\\'"]+$/g, ''),
            medium : S('.foundation-mq-medium').css('font-family').replace(/^[\/\\'"]+|(;\s?})+|[\/\\'"]+$/g, ''),
            large : S('.foundation-mq-large').css('font-family').replace(/^[\/\\'"]+|(;\s?})+|[\/\\'"]+$/g, ''),
            xlarge: S('.foundation-mq-xlarge').css('font-family').replace(/^[\/\\'"]+|(;\s?})+|[\/\\'"]+$/g, ''),
            xxlarge: S('.foundation-mq-xxlarge').css('font-family').replace(/^[\/\\'"]+|(;\s?})+|[\/\\'"]+$/g, '')
        },

        stylesheet : $('<style></style>').appendTo('head')[0].sheet,

        global: {
            namespace: undefined
        },

        init : function (scope, libraries, method, options, response) {
            var args = [scope, method, options, response],
                responses = [];

            // check RTL
            this.rtl = /rtl/i.test(S('html').attr('dir'));

            // set foundation global scope
            this.scope = scope || this.scope;

            this.set_namespace();

            if (libraries && typeof libraries === 'string' && !/reflow/i.test(libraries)) {
                if (this.libs.hasOwnProperty(libraries)) {
                    responses.push(this.init_lib(libraries, args));
                }
            } else {
                for (var lib in this.libs) {
                    responses.push(this.init_lib(lib, libraries));
                }
            }

            S(window).load(function(){
                S(window)
                    .trigger('resize.fndtn.clearing')
                    .trigger('resize.fndtn.dropdown')
                    .trigger('resize.fndtn.equalizer')
                    .trigger('resize.fndtn.interchange')
                    .trigger('resize.fndtn.joyride')
                    .trigger('resize.fndtn.magellan')
                    .trigger('resize.fndtn.topbar')
                    .trigger('resize.fndtn.slider');
            });

            return scope;
        },

        init_lib : function (lib, args) {
            if (this.libs.hasOwnProperty(lib)) {
                this.patch(this.libs[lib]);

                if (args && args.hasOwnProperty(lib)) {
                    if (typeof this.libs[lib].settings !== 'undefined') {
                        $.extend(true, this.libs[lib].settings, args[lib]);
                    }
                    else if (typeof this.libs[lib].defaults !== 'undefined') {
                        $.extend(true, this.libs[lib].defaults, args[lib]);
                    }
                    return this.libs[lib].init.apply(this.libs[lib], [this.scope, args[lib]]);
                }

                args = args instanceof Array ? args : new Array(args);    // PATCH: added this line
                return this.libs[lib].init.apply(this.libs[lib], args);
            }

            return function () {};
        },

        patch : function (lib) {
            lib.scope = this.scope;
            lib.namespace = this.global.namespace;
            lib.rtl = this.rtl;
            lib['data_options'] = this.utils.data_options;
            lib['attr_name'] = attr_name;
            lib['add_namespace'] = add_namespace;
            lib['bindings'] = bindings;
            lib['S'] = this.utils.S;
        },

        inherit : function (scope, methods) {
            var methods_arr = methods.split(' '),
                i = methods_arr.length;

            while (i--) {
                if (this.utils.hasOwnProperty(methods_arr[i])) {
                    scope[methods_arr[i]] = this.utils[methods_arr[i]];
                }
            }
        },

        set_namespace: function () {

            // Description:
            //    Don't bother reading the namespace out of the meta tag
            //    if the namespace has been set globally in javascript
            //
            // Example:
            //    Foundation.global.namespace = 'my-namespace';
            // or make it an empty string:
            //    Foundation.global.namespace = '';
            //
            //

            // If the namespace has not been set (is undefined), try to read it out of the meta element.
            // Otherwise use the globally defined namespace, even if it's empty ('')
            var namespace = ( this.global.namespace === undefined ) ? $('.foundation-data-attribute-namespace').css('font-family') : this.global.namespace;

            // Finally, if the namsepace is either undefined or false, set it to an empty string.
            // Otherwise use the namespace value.
            this.global.namespace = ( namespace === undefined || /false/i.test(namespace) ) ? '' : namespace;
        },

        libs : {},

        // methods that can be inherited in libraries
        utils : {

            // Description:
            //    Fast Selector wrapper returns jQuery object. Only use where getElementById
            //    is not available.
            //
            // Arguments:
            //    Selector (String): CSS selector describing the element(s) to be
            //    returned as a jQuery object.
            //
            //    Scope (String): CSS selector describing the area to be searched. Default
            //    is document.
            //
            // Returns:
            //    Element (jQuery Object): jQuery object containing elements matching the
            //    selector within the scope.
            S : S,

            // Description:
            //    Executes a function a max of once every n milliseconds
            //
            // Arguments:
            //    Func (Function): Function to be throttled.
            //
            //    Delay (Integer): Function execution threshold in milliseconds.
            //
            // Returns:
            //    Lazy_function (Function): Function with throttling applied.
            throttle : function (func, delay) {
                var timer = null;

                return function () {
                    var context = this, args = arguments;

                    if (timer == null) {
                        timer = setTimeout(function () {
                            func.apply(context, args);
                            timer = null;
                        }, delay);
                    }
                };
            },

            // Description:
            //    Executes a function when it stops being invoked for n seconds
            //    Modified version of _.debounce() http://underscorejs.org
            //
            // Arguments:
            //    Func (Function): Function to be debounced.
            //
            //    Delay (Integer): Function execution threshold in milliseconds.
            //
            //    Immediate (Bool): Whether the function should be called at the beginning
            //    of the delay instead of the end. Default is false.
            //
            // Returns:
            //    Lazy_function (Function): Function with debouncing applied.
            debounce : function (func, delay, immediate) {
                var timeout, result;
                return function () {
                    var context = this, args = arguments;
                    var later = function () {
                        timeout = null;
                        if (!immediate) result = func.apply(context, args);
                    };
                    var callNow = immediate && !timeout;
                    clearTimeout(timeout);
                    timeout = setTimeout(later, delay);
                    if (callNow) result = func.apply(context, args);
                    return result;
                };
            },

            // Description:
            //    Parses data-options attribute
            //
            // Arguments:
            //    El (jQuery Object): Element to be parsed.
            //
            // Returns:
            //    Options (Javascript Object): Contents of the element's data-options
            //    attribute.
            data_options : function (el, data_attr_name) {
                data_attr_name = data_attr_name || 'options';
                var opts = {}, ii, p, opts_arr,
                    data_options = function (el) {
                        var namespace = Foundation.global.namespace;

                        if (namespace.length > 0) {
                            return el.data(namespace + '-' + data_attr_name);
                        }

                        return el.data(data_attr_name);
                    };

                var cached_options = data_options(el);

                if (typeof cached_options === 'object') {
                    return cached_options;
                }

                opts_arr = (cached_options || ':').split(';');
                ii = opts_arr.length;

                function isNumber (o) {
                    return ! isNaN (o-0) && o !== null && o !== "" && o !== false && o !== true;
                }

                function trim (str) {
                    if (typeof str === 'string') return $.trim(str);
                    return str;
                }

                while (ii--) {
                    p = opts_arr[ii].split(':');
                    p = [p[0], p.slice(1).join(':')];

                    if (/true/i.test(p[1])) p[1] = true;
                    if (/false/i.test(p[1])) p[1] = false;
                    if (isNumber(p[1])) {
                        if (p[1].indexOf('.') === -1) {
                            p[1] = parseInt(p[1], 10);
                        } else {
                            p[1] = parseFloat(p[1]);
                        }
                    }

                    if (p.length === 2 && p[0].length > 0) {
                        opts[trim(p[0])] = trim(p[1]);
                    }
                }

                return opts;
            },

            // Description:
            //    Adds JS-recognizable media queries
            //
            // Arguments:
            //    Media (String): Key string for the media query to be stored as in
            //    Foundation.media_queries
            //
            //    Class (String): Class name for the generated <meta> tag
            register_media : function (media, media_class) {
                if(Foundation.media_queries[media] === undefined) {
                    $('head').append('<meta class="' + media_class + '"/>');
                    Foundation.media_queries[media] = removeQuotes($('.' + media_class).css('font-family'));
                }
            },

            // Description:
            //    Add custom CSS within a JS-defined media query
            //
            // Arguments:
            //    Rule (String): CSS rule to be appended to the document.
            //
            //    Media (String): Optional media query string for the CSS rule to be
            //    nested under.
            add_custom_rule : function (rule, media) {
                if (media === undefined && Foundation.stylesheet) {
                    Foundation.stylesheet.insertRule(rule, Foundation.stylesheet.cssRules.length);
                } else {
                    var query = Foundation.media_queries[media];

                    if (query !== undefined) {
                        Foundation.stylesheet.insertRule('@media ' +
                            Foundation.media_queries[media] + '{ ' + rule + ' }');
                    }
                }
            },

            // Description:
            //    Performs a callback function when an image is fully loaded
            //
            // Arguments:
            //    Image (jQuery Object): Image(s) to check if loaded.
            //
            //    Callback (Function): Function to execute when image is fully loaded.
            image_loaded : function (images, callback) {
                var self = this,
                    unloaded = images.length;

                if (unloaded === 0) {
                    callback(images);
                }

                images.each(function () {
                    single_image_loaded(self.S(this), function () {
                        unloaded -= 1;
                        if (unloaded === 0) {
                            callback(images);
                        }
                    });
                });
            },

            // Description:
            //    Returns a random, alphanumeric string
            //
            // Arguments:
            //    Length (Integer): Length of string to be generated. Defaults to random
            //    integer.
            //
            // Returns:
            //    Rand (String): Pseudo-random, alphanumeric string.
            random_str : function () {
                if (!this.fidx) this.fidx = 0;
                this.prefix = this.prefix || [(this.name || 'F'), (+new Date).toString(36)].join('-');

                return this.prefix + (this.fidx++).toString(36);
            }
        }
    };

    $.fn.foundation = function () {
        var args = Array.prototype.slice.call(arguments, 0);

        return this.each(function () {
            Foundation.init.apply(Foundation, [this].concat(args));
            return this;
        });
    };

}(jQuery, window, window.document));
;(function ($, window, document, undefined) {
    'use strict';

    Foundation.libs.abide = {
        name : 'abide',

        version : '5.4.6',

        settings : {
            live_validate : true,
            focus_on_invalid : true,
            error_labels: true, // labels with a for="inputId" will recieve an `error` class
            timeout : 1000,
            patterns : {
                alpha: /^[a-zA-Z]+$/,
                alpha_numeric : /^[a-zA-Z0-9]+$/,
                integer: /^[-+]?\d+$/,
                number: /^[-+]?\d*(?:[\.\,]\d+)?$/,

                // amex, visa, diners
                card : /^(?:4[0-9]{12}(?:[0-9]{3})?|5[1-5][0-9]{14}|6(?:011|5[0-9][0-9])[0-9]{12}|3[47][0-9]{13}|3(?:0[0-5]|[68][0-9])[0-9]{11}|(?:2131|1800|35\d{3})\d{11})$/,
                cvv : /^([0-9]){3,4}$/,

                // http://www.whatwg.org/specs/web-apps/current-work/multipage/states-of-the-type-attribute.html#valid-e-mail-address
                email : /^[a-zA-Z0-9.!#$%&'*+\/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)+$/,

                url: /^(https?|ftp|file|ssh):\/\/(((([a-zA-Z]|\d|-|\.|_|~|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])|(%[\da-f]{2})|[!\$&'\(\)\*\+,;=]|:)*@)?(((\d|[1-9]\d|1\d\d|2[0-4]\d|25[0-5])\.(\d|[1-9]\d|1\d\d|2[0-4]\d|25[0-5])\.(\d|[1-9]\d|1\d\d|2[0-4]\d|25[0-5])\.(\d|[1-9]\d|1\d\d|2[0-4]\d|25[0-5]))|((([a-zA-Z]|\d|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])|(([a-zA-Z]|\d|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])([a-zA-Z]|\d|-|\.|_|~|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])*([a-zA-Z]|\d|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])))\.)+(([a-zA-Z]|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])|(([a-zA-Z]|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])([a-zA-Z]|\d|-|\.|_|~|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])*([a-zA-Z]|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])))\.?)(:\d*)?)(\/((([a-zA-Z]|\d|-|\.|_|~|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])|(%[\da-f]{2})|[!\$&'\(\)\*\+,;=]|:|@)+(\/(([a-zA-Z]|\d|-|\.|_|~|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])|(%[\da-f]{2})|[!\$&'\(\)\*\+,;=]|:|@)*)*)?)?(\?((([a-zA-Z]|\d|-|\.|_|~|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])|(%[\da-f]{2})|[!\$&'\(\)\*\+,;=]|:|@)|[\uE000-\uF8FF]|\/|\?)*)?(\#((([a-zA-Z]|\d|-|\.|_|~|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])|(%[\da-f]{2})|[!\$&'\(\)\*\+,;=]|:|@)|\/|\?)*)?$/,
                // abc.de
                domain: /^([a-zA-Z0-9]([a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])?\.)+[a-zA-Z]{2,6}$/,

                datetime: /^([0-2][0-9]{3})\-([0-1][0-9])\-([0-3][0-9])T([0-5][0-9])\:([0-5][0-9])\:([0-5][0-9])(Z|([\-\+]([0-1][0-9])\:00))$/,
                // YYYY-MM-DD
                date: /(?:19|20)[0-9]{2}-(?:(?:0[1-9]|1[0-2])-(?:0[1-9]|1[0-9]|2[0-9])|(?:(?!02)(?:0[1-9]|1[0-2])-(?:30))|(?:(?:0[13578]|1[02])-31))$/,
                // HH:MM:SS
                time : /^(0[0-9]|1[0-9]|2[0-3])(:[0-5][0-9]){2}$/,
                dateISO: /^\d{4}[\/\-]\d{1,2}[\/\-]\d{1,2}$/,
                // MM/DD/YYYY
                month_day_year : /^(0[1-9]|1[012])[- \/.](0[1-9]|[12][0-9]|3[01])[- \/.]\d{4}$/,
                // DD/MM/YYYY
                day_month_year : /^(0[1-9]|[12][0-9]|3[01])[- \/.](0[1-9]|1[012])[- \/.]\d{4}$/,

                // #FFF or #FFFFFF
                color: /^#?([a-fA-F0-9]{6}|[a-fA-F0-9]{3})$/
            },
            validators : {
                equalTo: function(el, required, parent) {
                    var from  = document.getElementById(el.getAttribute(this.add_namespace('data-equalto'))).value,
                        to    = el.value,
                        valid = (from === to);

                    return valid;
                }
            }
        },

        timer : null,

        init : function (scope, method, options) {
            this.bindings(method, options);
        },

        events : function (scope) {
            var self = this,
                form = self.S(scope).attr('novalidate', 'novalidate'),
                settings = form.data(this.attr_name(true) + '-init') || {};

            this.invalid_attr = this.add_namespace('data-invalid');

            form
                .off('.abide')
                .on('submit.fndtn.abide validate.fndtn.abide', function (e) {
                    var is_ajax = /ajax/i.test(self.S(this).attr(self.attr_name()));
                    return self.validate(self.S(this).find('input, textarea, select').get(), e, is_ajax);
                })
                .on('reset', function() {
                    return self.reset($(this));
                })
                .find('input, textarea, select')
                .off('.abide')
                .on('blur.fndtn.abide change.fndtn.abide', function (e) {
                    self.validate([this], e);
                })
                .on('keydown.fndtn.abide', function (e) {
                    if (settings.live_validate === true) {
                        clearTimeout(self.timer);
                        self.timer = setTimeout(function () {
                            self.validate([this], e);
                        }.bind(this), settings.timeout);
                    }
                });
        },

        reset : function (form) {
            form.removeAttr(this.invalid_attr);
            $(this.invalid_attr, form).removeAttr(this.invalid_attr);
            $('.error', form).not('small').removeClass('error');
        },

        validate : function (els, e, is_ajax) {
            var validations = this.parse_patterns(els),
                validation_count = validations.length,
                form = this.S(els[0]).closest('form'),
                submit_event = /submit/.test(e.type);

            // Has to count up to make sure the focus gets applied to the top error
            for (var i=0; i < validation_count; i++) {
                if (!validations[i] && (submit_event || is_ajax)) {
                    if (this.settings.focus_on_invalid) els[i].focus();
                    form.trigger('invalid');
                    this.S(els[i]).closest('form').attr(this.invalid_attr, '');
                    return false;
                }
            }

            if (submit_event || is_ajax) {
                form.trigger('valid');
            }

            form.removeAttr(this.invalid_attr);

            if (is_ajax) return false;

            return true;
        },

        parse_patterns : function (els) {
            var i = els.length,
                el_patterns = [];

            while (i--) {
                el_patterns.push(this.pattern(els[i]));
            }

            return this.check_validation_and_apply_styles(el_patterns);
        },

        pattern : function (el) {
            var type = el.getAttribute('type'),
                required = typeof el.getAttribute('required') === 'string';

            var pattern = el.getAttribute('pattern') || '';

            if (this.settings.patterns.hasOwnProperty(pattern) && pattern.length > 0) {
                return [el, this.settings.patterns[pattern], required];
            } else if (pattern.length > 0) {
                return [el, new RegExp(pattern), required];
            }

            if (this.settings.patterns.hasOwnProperty(type)) {
                return [el, this.settings.patterns[type], required];
            }

            pattern = /.*/;

            return [el, pattern, required];
        },

        check_validation_and_apply_styles : function (el_patterns) {
            var i = el_patterns.length,
                validations = [],
                form = this.S(el_patterns[0][0]).closest('[data-' + this.attr_name(true) + ']'),
                settings = form.data(this.attr_name(true) + '-init') || {};
            while (i--) {
                var el = el_patterns[i][0],
                    required = el_patterns[i][2],
                    value = el.value.trim(),
                    direct_parent = this.S(el).parent(),
                    validator = el.getAttribute(this.add_namespace('data-abide-validator')),
                    is_radio = el.type === "radio",
                    is_checkbox = el.type === "checkbox",
                    label = this.S('label[for="' + el.getAttribute('id') + '"]'),
                    valid_length = (required) ? (el.value.length > 0) : true,
                    el_validations = [];

                var parent, valid;

                // support old way to do equalTo validations
                if(el.getAttribute(this.add_namespace('data-equalto'))) { validator = "equalTo" }

                if (!direct_parent.is('label')) {
                    parent = direct_parent;
                } else {
                    parent = direct_parent.parent();
                }

                if (validator) {
                    valid = this.settings.validators[validator].apply(this, [el, required, parent]);
                    el_validations.push(valid);
                }

                if (is_radio && required) {
                    el_validations.push(this.valid_radio(el, required));
                } else if (is_checkbox && required) {
                    el_validations.push(this.valid_checkbox(el, required));
                } else {

                    if (el_patterns[i][1].test(value) && valid_length ||
                        !required && el.value.length < 1 || $(el).attr('disabled')) {
                        el_validations.push(true);
                    } else {
                        el_validations.push(false);
                    }

                    el_validations = [el_validations.every(function(valid){return valid;})];

                    if(el_validations[0]){
                        this.S(el).removeAttr(this.invalid_attr);
                        el.setAttribute('aria-invalid', 'false');
                        el.removeAttribute('aria-describedby');
                        parent.removeClass('error');
                        if (label.length > 0 && this.settings.error_labels) {
                            label.removeClass('error').removeAttr('role');
                        }
                        $(el).triggerHandler('valid');
                    } else {
                        this.S(el).attr(this.invalid_attr, '');
                        el.setAttribute('aria-invalid', 'true');

                        // Try to find the error associated with the input
                        var errorElem = parent.find('small.error, span.error');
                        var errorID = errorElem.length > 0 ? errorElem[0].id : "";
                        if (errorID.length > 0) el.setAttribute('aria-describedby', errorID);

                        // el.setAttribute('aria-describedby', $(el).find('.error')[0].id);
                        parent.addClass('error');
                        if (label.length > 0 && this.settings.error_labels) {
                            label.addClass('error').attr('role', 'alert');
                        }
                        $(el).triggerHandler('invalid');
                    }
                }
                validations.push(el_validations[0]);
            }
            validations = [validations.every(function(valid){return valid;})];
            return validations;
        },

        valid_checkbox : function(el, required) {
            var el = this.S(el),
                valid = (el.is(':checked') || !required);

            if (valid) {
                el.removeAttr(this.invalid_attr).parent().removeClass('error');
            } else {
                el.attr(this.invalid_attr, '').parent().addClass('error');
            }

            return valid;
        },

        valid_radio : function (el, required) {
            var name = el.getAttribute('name'),
                group = this.S(el).closest('[data-' + this.attr_name(true) + ']').find("[name='"+name+"']"),
                count = group.length,
                valid = false;

            // Has to count up to make sure the focus gets applied to the top error
            for (var i=0; i < count; i++) {
                if (group[i].checked) valid = true;
            }

            // Has to count up to make sure the focus gets applied to the top error
            for (var i=0; i < count; i++) {
                if (valid) {
                    this.S(group[i]).removeAttr(this.invalid_attr).parent().removeClass('error');
                } else {
                    this.S(group[i]).attr(this.invalid_attr, '').parent().addClass('error');
                }
            }

            return valid;
        },

        valid_equal: function(el, required, parent) {
            var from  = document.getElementById(el.getAttribute(this.add_namespace('data-equalto'))).value,
                to    = el.value,
                valid = (from === to);

            if (valid) {
                this.S(el).removeAttr(this.invalid_attr);
                parent.removeClass('error');
                if (label.length > 0 && settings.error_labels) label.removeClass('error');
            } else {
                this.S(el).attr(this.invalid_attr, '');
                parent.addClass('error');
                if (label.length > 0 && settings.error_labels) label.addClass('error');
            }

            return valid;
        },

        valid_oneof: function(el, required, parent, doNotValidateOthers) {
            var el = this.S(el),
                others = this.S('[' + this.add_namespace('data-oneof') + ']'),
                valid = others.filter(':checked').length > 0;

            if (valid) {
                el.removeAttr(this.invalid_attr).parent().removeClass('error');
            } else {
                el.attr(this.invalid_attr, '').parent().addClass('error');
            }

            if (!doNotValidateOthers) {
                var _this = this;
                others.each(function() {
                    _this.valid_oneof.call(_this, this, null, null, true);
                });
            }

            return valid;
        }
    };
}(jQuery, window, window.document));
;(function ($, window, document, undefined) {
    'use strict';

    Foundation.libs.interchange = {
        name : 'interchange',

        version : '5.4.6',

        cache : {},

        images_loaded : false,
        nodes_loaded : false,

        settings : {
            load_attr : 'interchange',

            named_queries : {
                'default' : 'only screen',
                small : Foundation.media_queries.small,
                medium : Foundation.media_queries.medium,
                large : Foundation.media_queries.large,
                xlarge : Foundation.media_queries.xlarge,
                xxlarge: Foundation.media_queries.xxlarge,
                landscape : 'only screen and (orientation: landscape)',
                portrait : 'only screen and (orientation: portrait)',
                retina : 'only screen and (-webkit-min-device-pixel-ratio: 2),' +
                    'only screen and (min--moz-device-pixel-ratio: 2),' +
                    'only screen and (-o-min-device-pixel-ratio: 2/1),' +
                    'only screen and (min-device-pixel-ratio: 2),' +
                    'only screen and (min-resolution: 192dpi),' +
                    'only screen and (min-resolution: 2dppx)'
            },

            directives : {
                replace: function (el, path, trigger) {
                    // The trigger argument, if called within the directive, fires
                    // an event named after the directive on the element, passing
                    // any parameters along to the event that you pass to trigger.
                    //
                    // ex. trigger(), trigger([a, b, c]), or trigger(a, b, c)
                    //
                    // This allows you to bind a callback like so:
                    // $('#interchangeContainer').on('replace', function (e, a, b, c) {
                    //   console.log($(this).html(), a, b, c);
                    // });

                    if (/IMG/.test(el[0].nodeName)) {
                        var orig_path = el[0].src;

                        if (new RegExp(path, 'i').test(orig_path)) return;

                        el[0].src = path;

                        return trigger(el[0].src);
                    }
                    var last_path = el.data(this.data_attr + '-last-path'),
                        self = this;

                    if (last_path == path) return;

                    if (/\.(gif|jpg|jpeg|tiff|png)([?#].*)?/i.test(path)) {
                        $(el).css('background-image', 'url('+path+')');
                        el.data('interchange-last-path', path);
                        return trigger(path);
                    }

                    return $.get(path, function (response) {
                        el.html(response);
                        el.data(self.data_attr + '-last-path', path);
                        trigger();
                    });

                }
            }
        },

        init : function (scope, method, options) {
            Foundation.inherit(this, 'throttle random_str');

            this.data_attr = this.set_data_attr();
            $.extend(true, this.settings, method, options);
            this.bindings(method, options);
            this.load('images');
            this.load('nodes');
        },

        get_media_hash : function() {
            var mediaHash='';
            for (var queryName in this.settings.named_queries ) {
                mediaHash += matchMedia(this.settings.named_queries[queryName]).matches.toString();
            }
            return mediaHash;
        },

        events : function () {
            var self = this, prevMediaHash;

            $(window)
                .off('.interchange')
                .on('resize.fndtn.interchange', self.throttle(function () {
                    var currMediaHash = self.get_media_hash();
                    if (currMediaHash !== prevMediaHash) {
                        self.resize();
                    }
                    prevMediaHash = currMediaHash;
                }, 50));

            return this;
        },

        resize : function () {
            var cache = this.cache;

            if(!this.images_loaded || !this.nodes_loaded) {
                setTimeout($.proxy(this.resize, this), 50);
                return;
            }

            for (var uuid in cache) {
                if (cache.hasOwnProperty(uuid)) {
                    var passed = this.results(uuid, cache[uuid]);

                    if (passed) {
                        this.settings.directives[passed
                            .scenario[1]].call(this, passed.el, passed.scenario[0], function () {
                                if (arguments[0] instanceof Array) {
                                    var args = arguments[0];
                                } else {
                                    var args = Array.prototype.slice.call(arguments, 0);
                                }

                                passed.el.trigger(passed.scenario[1], args);
                            });
                    }
                }
            }

        },

        results : function (uuid, scenarios) {
            var count = scenarios.length;

            if (count > 0) {
                var el = this.S('[' + this.add_namespace('data-uuid') + '="' + uuid + '"]');

                while (count--) {
                    var mq, rule = scenarios[count][2];
                    if (this.settings.named_queries.hasOwnProperty(rule)) {
                        mq = matchMedia(this.settings.named_queries[rule]);
                    } else {
                        mq = matchMedia(rule);
                    }
                    if (mq.matches) {
                        return {el: el, scenario: scenarios[count]};
                    }
                }
            }

            return false;
        },

        load : function (type, force_update) {
            if (typeof this['cached_' + type] === 'undefined' || force_update) {
                this['update_' + type]();
            }

            return this['cached_' + type];
        },

        update_images : function () {
            var images = this.S('img[' + this.data_attr + ']'),
                count = images.length,
                i = count,
                loaded_count = 0,
                data_attr = this.data_attr;

            this.cache = {};
            this.cached_images = [];
            this.images_loaded = (count === 0);

            while (i--) {
                loaded_count++;
                if (images[i]) {
                    var str = images[i].getAttribute(data_attr) || '';

                    if (str.length > 0) {
                        this.cached_images.push(images[i]);
                    }
                }

                if (loaded_count === count) {
                    this.images_loaded = true;
                    this.enhance('images');
                }
            }

            return this;
        },

        update_nodes : function () {
            var nodes = this.S('[' + this.data_attr + ']').not('img'),
                count = nodes.length,
                i = count,
                loaded_count = 0,
                data_attr = this.data_attr;

            this.cached_nodes = [];
            this.nodes_loaded = (count === 0);


            while (i--) {
                loaded_count++;
                var str = nodes[i].getAttribute(data_attr) || '';

                if (str.length > 0) {
                    this.cached_nodes.push(nodes[i]);
                }

                if(loaded_count === count) {
                    this.nodes_loaded = true;
                    this.enhance('nodes');
                }
            }

            return this;
        },

        enhance : function (type) {
            var i = this['cached_' + type].length;

            while (i--) {
                this.object($(this['cached_' + type][i]));
            }

            return $(window).trigger('resize').trigger('resize.fndtn.interchange');
        },

        convert_directive : function (directive) {

            var trimmed = this.trim(directive);

            if (trimmed.length > 0) {
                return trimmed;
            }

            return 'replace';
        },

        parse_scenario : function (scenario) {
            // This logic had to be made more complex since some users were using commas in the url path
            // So we cannot simply just split on a comma
            var directive_match = scenario[0].match(/(.+),\s*(\w+)\s*$/),
                media_query         = scenario[1];

            if (directive_match) {
                var path  = directive_match[1],
                    directive = directive_match[2];
            }
            else {
                var cached_split = scenario[0].split(/,\s*$/),
                    path             = cached_split[0],
                    directive        = '';
            }

            return [this.trim(path), this.convert_directive(directive), this.trim(media_query)];
        },

        object : function(el) {
            var raw_arr = this.parse_data_attr(el),
                scenarios = [],
                i = raw_arr.length;

            if (i > 0) {
                while (i--) {
                    var split = raw_arr[i].split(/\((.*?)(\))$/);

                    if (split.length > 1) {
                        var params = this.parse_scenario(split);
                        scenarios.push(params);
                    }
                }
            }

            return this.store(el, scenarios);
        },

        store : function (el, scenarios) {
            var uuid = this.random_str(),
                current_uuid = el.data(this.add_namespace('uuid', true));

            if (this.cache[current_uuid]) return this.cache[current_uuid];

            el.attr(this.add_namespace('data-uuid'), uuid);

            return this.cache[uuid] = scenarios;
        },

        trim : function(str) {

            if (typeof str === 'string') {
                return $.trim(str);
            }

            return str;
        },

        set_data_attr: function (init) {
            if (init) {
                if (this.namespace.length > 0) {
                    return this.namespace + '-' + this.settings.load_attr;
                }

                return this.settings.load_attr;
            }

            if (this.namespace.length > 0) {
                return 'data-' + this.namespace + '-' + this.settings.load_attr;
            }

            return 'data-' + this.settings.load_attr;
        },

        parse_data_attr : function (el) {
            var raw = el.attr(this.attr_name()).split(/\[(.*?)\]/),
                i = raw.length,
                output = [];

            while (i--) {
                if (raw[i].replace(/[\W\d]+/, '').length > 4) {
                    output.push(raw[i]);
                }
            }

            return output;
        },

        reflow : function () {
            this.load('images', true);
            this.load('nodes', true);
        }

    };

}(jQuery, window, window.document));
;(function ($, window, document, undefined) {
    'use strict';

    Foundation.libs.alert = {
        name : 'alert',

        version : '5.4.6',

        settings : {
            callback: function (){}
        },

        init : function (scope, method, options) {
            this.bindings(method, options);
        },

        events : function () {
            var self = this,
                S = this.S;

            $(this.scope).off('.alert').on('click.fndtn.alert', '[' + this.attr_name() + '] .close', function (e) {
                var alertBox = S(this).closest('[' + self.attr_name() + ']'),
                    settings = alertBox.data(self.attr_name(true) + '-init') || self.settings;

                e.preventDefault();
                if (Modernizr.csstransitions) {
                    alertBox.addClass("alert-close");
                    alertBox.on('transitionend webkitTransitionEnd oTransitionEnd', function(e) {
                        S(this).trigger('close').trigger('close.fndtn.alert').remove();
                        settings.callback();
                    });
                } else {
                    alertBox.fadeOut(300, function () {
                        S(this).trigger('close').trigger('close.fndtn.alert').remove();
                        settings.callback();
                    });
                }
            });
        },

        reflow : function () {}
    };
}(jQuery, window, window.document));
;(function ($, window, document, undefined) {
    'use strict';

    Foundation.libs.reveal = {
        name : 'reveal',

        version : '5.4.6',

        locked : false,

        settings : {
            animation: 'fadeAndPop',
            animation_speed: 250,
            close_on_background_click: true,
            close_on_esc: true,
            dismiss_modal_class: 'close-reveal-modal',
            bg_class: 'reveal-modal-bg',
            root_element: 'body',
            open: function(){},
            opened: function(){},
            close: function(){},
            closed: function(){},
            bg : $('.reveal-modal-bg'),
            css : {
                open : {
                    'opacity': 0,
                    'visibility': 'visible',
                    'display' : 'block'
                },
                close : {
                    'opacity': 1,
                    'visibility': 'hidden',
                    'display': 'none'
                }
            }
        },

        init : function (scope, method, options) {
            $.extend(true, this.settings, method, options);
            this.bindings(method, options);
        },

        events : function (scope) {
            var self = this,
                S = self.S;

            S(this.scope)
                .off('.reveal')
                .on('click.fndtn.reveal', '[' + this.add_namespace('data-reveal-id') + ']:not([disabled])', function (e) {
                    e.preventDefault();

                    if (!self.locked) {
                        var element = S(this),
                            ajax = element.data(self.data_attr('reveal-ajax'));

                        self.locked = true;

                        if (typeof ajax === 'undefined') {
                            self.open.call(self, element);
                        } else {
                            var url = ajax === true ? element.attr('href') : ajax;

                            self.open.call(self, element, {url: url});
                        }
                    }
                });

            S(document)
                .on('click.fndtn.reveal', this.close_targets(), function (e) {

                    e.preventDefault();

                    if (!self.locked) {
                        var settings = S('[' + self.attr_name() + '].open').data(self.attr_name(true) + '-init'),
                            bg_clicked = S(e.target)[0] === S('.' + settings.bg_class)[0];

                        if (bg_clicked) {
                            if (settings.close_on_background_click) {
                                e.stopPropagation();
                            } else {
                                return;
                            }
                        }

                        self.locked = true;
                        self.close.call(self, bg_clicked ? S('[' + self.attr_name() + '].open') : S(this).closest('[' + self.attr_name() + ']'));
                    }
                });

            if(S('[' + self.attr_name() + ']', this.scope).length > 0) {
                S(this.scope)
                    // .off('.reveal')
                    .on('open.fndtn.reveal', this.settings.open)
                    .on('opened.fndtn.reveal', this.settings.opened)
                    .on('opened.fndtn.reveal', this.open_video)
                    .on('close.fndtn.reveal', this.settings.close)
                    .on('closed.fndtn.reveal', this.settings.closed)
                    .on('closed.fndtn.reveal', this.close_video);
            } else {
                S(this.scope)
                    // .off('.reveal')
                    .on('open.fndtn.reveal', '[' + self.attr_name() + ']', this.settings.open)
                    .on('opened.fndtn.reveal', '[' + self.attr_name() + ']', this.settings.opened)
                    .on('opened.fndtn.reveal', '[' + self.attr_name() + ']', this.open_video)
                    .on('close.fndtn.reveal', '[' + self.attr_name() + ']', this.settings.close)
                    .on('closed.fndtn.reveal', '[' + self.attr_name() + ']', this.settings.closed)
                    .on('closed.fndtn.reveal', '[' + self.attr_name() + ']', this.close_video);
            }

            return true;
        },

        // PATCH #3: turning on key up capture only when a reveal window is open
        key_up_on : function (scope) {
            var self = this;

            // PATCH #1: fixing multiple keyup event trigger from single key press
            self.S('body').off('keyup.fndtn.reveal').on('keyup.fndtn.reveal', function ( event ) {
                var open_modal = self.S('[' + self.attr_name() + '].open'),
                    settings = open_modal.data(self.attr_name(true) + '-init') || self.settings ;
                // PATCH #2: making sure that the close event can be called only while unlocked,
                //           so that multiple keyup.fndtn.reveal events don't prevent clean closing of the reveal window.
                if ( settings && event.which === 27  && settings.close_on_esc && !self.locked) { // 27 is the keycode for the Escape key
                    self.close.call(self, open_modal);
                }
            });

            return true;
        },

        // PATCH #3: turning on key up capture only when a reveal window is open
        key_up_off : function (scope) {
            this.S('body').off('keyup.fndtn.reveal');
            return true;
        },


        open : function (target, ajax_settings) {
            var self = this,
                modal;

            if (target) {
                if (typeof target.selector !== 'undefined') {
                    // Find the named node; only use the first one found, since the rest of the code assumes there's only one node
                    modal = self.S('#' + target.data(self.data_attr('reveal-id'))).first();
                } else {
                    modal = self.S(this.scope);

                    ajax_settings = target;
                }
            } else {
                modal = self.S(this.scope);
            }

            var settings = modal.data(self.attr_name(true) + '-init');
            settings = settings || this.settings;


            if (modal.hasClass('open') && target.attr('data-reveal-id') == modal.attr('id')) {
                return self.close(modal);
            }

            if (!modal.hasClass('open')) {
                var open_modal = self.S('[' + self.attr_name() + '].open');

                if (typeof modal.data('css-top') === 'undefined') {
                    modal.data('css-top', parseInt(modal.css('top'), 10))
                        .data('offset', this.cache_offset(modal));
                }

                this.key_up_on(modal);    // PATCH #3: turning on key up capture only when a reveal window is open
                modal.trigger('open').trigger('open.fndtn.reveal');

                if (open_modal.length < 1) {
                    this.toggle_bg(modal, true);
                }

                if (typeof ajax_settings === 'string') {
                    ajax_settings = {
                        url: ajax_settings
                    };
                }

                if (typeof ajax_settings === 'undefined' || !ajax_settings.url) {
                    if (open_modal.length > 0) {
                        this.hide(open_modal, settings.css.close);
                    }

                    this.show(modal, settings.css.open);
                } else {
                    var old_success = typeof ajax_settings.success !== 'undefined' ? ajax_settings.success : null;

                    $.extend(ajax_settings, {
                        success: function (data, textStatus, jqXHR) {
                            if ( $.isFunction(old_success) ) {
                                old_success(data, textStatus, jqXHR);
                            }

                            modal.html(data);
                            self.S(modal).foundation('section', 'reflow');
                            self.S(modal).children().foundation();

                            if (open_modal.length > 0) {
                                self.hide(open_modal, settings.css.close);
                            }
                            self.show(modal, settings.css.open);
                        }
                    });

                    $.ajax(ajax_settings);
                }
            }
            self.S(window).trigger('resize');
        },

        close : function (modal) {
            var modal = modal && modal.length ? modal : this.S(this.scope),
                open_modals = this.S('[' + this.attr_name() + '].open'),
                settings = modal.data(this.attr_name(true) + '-init') || this.settings;

            if (open_modals.length > 0) {
                this.locked = true;
                this.key_up_off(modal);   // PATCH #3: turning on key up capture only when a reveal window is open
                modal.trigger('close').trigger('close.fndtn.reveal');
                this.toggle_bg(modal, false);
                this.hide(open_modals, settings.css.close, settings);
            }
        },

        close_targets : function () {
            var base = '.' + this.settings.dismiss_modal_class;

            if (this.settings.close_on_background_click) {
                return base + ', .' + this.settings.bg_class;
            }

            return base;
        },

        toggle_bg : function (modal, state) {
            if (this.S('.' + this.settings.bg_class).length === 0) {
                this.settings.bg = $('<div />', {'class': this.settings.bg_class})
                    .appendTo('body').hide();
            }

            var visible = this.settings.bg.filter(':visible').length > 0;
            if ( state != visible ) {
                if ( state == undefined ? visible : !state ) {
                    this.hide(this.settings.bg);
                } else {
                    this.show(this.settings.bg);
                }
            }
        },

        show : function (el, css) {
            // is modal
            if (css) {
                var settings = el.data(this.attr_name(true) + '-init') || this.settings,
                    root_element = settings.root_element;

                if (el.parent(root_element).length === 0) {
                    var placeholder = el.wrap('<div style="display: none;" />').parent();

                    el.on('closed.fndtn.reveal.wrapped', function() {
                        el.detach().appendTo(placeholder);
                        el.unwrap().unbind('closed.fndtn.reveal.wrapped');
                    });

                    el.detach().appendTo(root_element);
                }

                var animData = getAnimationData(settings.animation);
                if (!animData.animate) {
                    this.locked = false;
                }
                if (animData.pop) {
                    css.top = $(window).scrollTop() - el.data('offset') + 'px';
                    var end_css = {
                        top: $(window).scrollTop() + el.data('css-top') + 'px',
                        opacity: 1
                    };

                    return setTimeout(function () {
                        return el
                            .css(css)
                            .animate(end_css, settings.animation_speed, 'linear', function () {
                                this.locked = false;
                                el.trigger('opened').trigger('opened.fndtn.reveal');
                            }.bind(this))
                            .addClass('open');
                    }.bind(this), settings.animation_speed / 2);
                }

                if (animData.fade) {
                    css.top = $(window).scrollTop() + el.data('css-top') + 'px';
                    var end_css = {opacity: 1};

                    return setTimeout(function () {
                        return el
                            .css(css)
                            .animate(end_css, settings.animation_speed, 'linear', function () {
                                this.locked = false;
                                el.trigger('opened').trigger('opened.fndtn.reveal');
                            }.bind(this))
                            .addClass('open');
                    }.bind(this), settings.animation_speed / 2);
                }

                return el.css(css).show().css({opacity: 1}).addClass('open').trigger('opened').trigger('opened.fndtn.reveal');
            }

            var settings = this.settings;

            // should we animate the background?
            if (getAnimationData(settings.animation).fade) {
                return el.fadeIn(settings.animation_speed / 2);
            }

            this.locked = false;

            return el.show();
        },

        hide : function (el, css) {
            // is modal
            if (css) {
                var settings = el.data(this.attr_name(true) + '-init');
                settings = settings || this.settings;

                var animData = getAnimationData(settings.animation);
                if (!animData.animate) {
                    this.locked = false;
                }
                if (animData.pop) {
                    var end_css = {
                        top: - $(window).scrollTop() - el.data('offset') + 'px',
                        opacity: 0
                    };

                    return setTimeout(function () {
                        return el
                            .animate(end_css, settings.animation_speed, 'linear', function () {
                                this.locked = false;
                                el.css(css).trigger('closed').trigger('closed.fndtn.reveal');
                            }.bind(this))
                            .removeClass('open');
                    }.bind(this), settings.animation_speed / 2);
                }

                if (animData.fade) {
                    var end_css = {opacity: 0};

                    return setTimeout(function () {
                        return el
                            .animate(end_css, settings.animation_speed, 'linear', function () {
                                this.locked = false;
                                el.css(css).trigger('closed').trigger('closed.fndtn.reveal');
                            }.bind(this))
                            .removeClass('open');
                    }.bind(this), settings.animation_speed / 2);
                }

                return el.hide().css(css).removeClass('open').trigger('closed').trigger('closed.fndtn.reveal');
            }

            var settings = this.settings;

            // should we animate the background?
            if (getAnimationData(settings.animation).fade) {
                return el.fadeOut(settings.animation_speed / 2);
            }

            return el.hide();
        },

        close_video : function (e) {
            var video = $('.flex-video', e.target),
                iframe = $('iframe', video);

            if (iframe.length > 0) {
                iframe.attr('data-src', iframe[0].src);
                iframe.attr('src', iframe.attr('src'));
                video.hide();
            }
        },

        open_video : function (e) {
            var video = $('.flex-video', e.target),
                iframe = video.find('iframe');

            if (iframe.length > 0) {
                var data_src = iframe.attr('data-src');
                if (typeof data_src === 'string') {
                    iframe[0].src = iframe.attr('data-src');
                } else {
                    var src = iframe[0].src;
                    iframe[0].src = undefined;
                    iframe[0].src = src;
                }
                video.show();
            }
        },

        data_attr: function (str) {
            if (this.namespace.length > 0) {
                return this.namespace + '-' + str;
            }

            return str;
        },

        cache_offset : function (modal) {
            var offset = modal.show().height() + parseInt(modal.css('top'), 10);

            modal.hide();

            return offset;
        },

        off : function () {
            $(this.scope).off('.fndtn.reveal');
        },

        reflow : function () {}
    };

    /*
     * getAnimationData('popAndFade') // {animate: true,  pop: true,  fade: true}
     * getAnimationData('fade')       // {animate: true,  pop: false, fade: true}
     * getAnimationData('pop')        // {animate: true,  pop: true,  fade: false}
     * getAnimationData('foo')        // {animate: false, pop: false, fade: false}
     * getAnimationData(null)         // {animate: false, pop: false, fade: false}
     */
    function getAnimationData(str) {
        var fade = /fade/i.test(str);
        var pop = /pop/i.test(str);
        return {
            animate: fade || pop,
            pop: pop,
            fade: fade
        };
    }
}(jQuery, window, window.document));
;(function ($, window, document, undefined) {
    'use strict';

    Foundation.libs.slider = {
        name : 'slider',

        version : '5.4.6',

        settings: {
            start: 0,
            end: 100,
            step: 1,
            initial: null,
            display_selector: '',
            vertical: false,
            on_change: function(){}
        },

        cache : {},

        init : function (scope, method, options) {
            Foundation.inherit(this,'throttle');
            this.bindings(method, options);
            this.reflow();
        },

        events : function() {
            var self = this;

            $(this.scope)
                .off('.slider')
                .on('mousedown.fndtn.slider touchstart.fndtn.slider pointerdown.fndtn.slider',
                    '[' + self.attr_name() + ']:not(.disabled, [disabled]) .range-slider-handle', function(e) {
                    if (!self.cache.active) {
                        e.preventDefault();
                        self.set_active_slider($(e.target));
                    }
                })
                .on('mousemove.fndtn.slider touchmove.fndtn.slider pointermove.fndtn.slider', function(e) {
                    if (!!self.cache.active) {
                        e.preventDefault();
                        if ($.data(self.cache.active[0], 'settings').vertical) {
                            var scroll_offset = 0;
                            if (!e.pageY) {
                                scroll_offset = window.scrollY;
                            }
                            self.calculate_position(self.cache.active, (e.pageY ||
                                e.originalEvent.clientY ||
                                e.originalEvent.touches[0].clientY ||
                                e.currentPoint.y)
                                + scroll_offset);
                        } else {
                            self.calculate_position(self.cache.active, e.pageX ||
                                e.originalEvent.clientX ||
                                e.originalEvent.touches[0].clientX ||
                                e.currentPoint.x);
                        }
                    }
                })
                .on('mouseup.fndtn.slider touchend.fndtn.slider pointerup.fndtn.slider', function(e) {
                    self.remove_active_slider();
                })
                .on('change.fndtn.slider', function(e) {
                    self.settings.on_change();
                });

            self.S(window)
                .on('resize.fndtn.slider', self.throttle(function(e) {
                    self.reflow();
                }, 300));
        },

        set_active_slider : function($handle) {
            this.cache.active = $handle;
        },

        remove_active_slider : function() {
            this.cache.active = null;
        },

        calculate_position : function($handle, cursor_x) {
            var self = this,
                settings = $.data($handle[0], 'settings'),
                handle_l = $.data($handle[0], 'handle_l'),
                handle_o = $.data($handle[0], 'handle_o'),
                bar_l = $.data($handle[0], 'bar_l'),
                bar_o = $.data($handle[0], 'bar_o');

            requestAnimationFrame(function(){
                var pct;

                if (Foundation.rtl && !settings.vertical) {
                    pct = self.limit_to(((bar_o+bar_l-cursor_x)/bar_l),0,1);
                } else {
                    pct = self.limit_to(((cursor_x-bar_o)/bar_l),0,1);
                }

                pct = settings.vertical ? 1-pct : pct;

                var norm = self.normalized_value(pct, settings.start, settings.end, settings.step);

                self.set_ui($handle, norm);
            });
        },

        set_ui : function($handle, value) {
            var settings = $.data($handle[0], 'settings'),
                handle_l = $.data($handle[0], 'handle_l'),
                bar_l = $.data($handle[0], 'bar_l'),
                norm_pct = this.normalized_percentage(value, settings.start, settings.end),
                handle_offset = norm_pct*(bar_l-handle_l)-1,
                progress_bar_length = norm_pct*100;

            if (Foundation.rtl && !settings.vertical) {
                handle_offset = -handle_offset;
            }

            handle_offset = settings.vertical ? -handle_offset + bar_l - handle_l + 1 : handle_offset;
            this.set_translate($handle, handle_offset, settings.vertical);

            if (settings.vertical) {
                $handle.siblings('.range-slider-active-segment').css('height', progress_bar_length + '%');
            } else {
                $handle.siblings('.range-slider-active-segment').css('width', progress_bar_length + '%');
            }

            $handle.parent().attr(this.attr_name(), value).trigger('change').trigger('change.fndtn.slider');

            $handle.parent().children('input[type=hidden]').val(value);

            if (!$handle[0].hasAttribute('aria-valuemin')) {
                $handle.attr({
                    'aria-valuemin': settings.start,
                    'aria-valuemax': settings.end,
                });
            }
            $handle.attr('aria-valuenow', value);

            if (settings.display_selector != '') {
                $(settings.display_selector).each(function(){
                    if (this.hasOwnProperty('value')) {
                        $(this).val(value);
                    } else {
                        $(this).text(value);
                    }
                });
            }

        },

        normalized_percentage : function(val, start, end) {
            return Math.min(1, (val - start)/(end - start));
        },

        normalized_value : function(val, start, end, step) {
            var range = end - start,
                point = val*range,
                mod = (point-(point%step)) / step,
                rem = point % step,
                round = ( rem >= step*0.5 ? step : 0);
            return (mod*step + round) + start;
        },

        set_translate : function(ele, offset, vertical) {
            if (vertical) {
                $(ele)
                    .css('-webkit-transform', 'translateY('+offset+'px)')
                    .css('-moz-transform', 'translateY('+offset+'px)')
                    .css('-ms-transform', 'translateY('+offset+'px)')
                    .css('-o-transform', 'translateY('+offset+'px)')
                    .css('transform', 'translateY('+offset+'px)');
            } else {
                $(ele)
                    .css('-webkit-transform', 'translateX('+offset+'px)')
                    .css('-moz-transform', 'translateX('+offset+'px)')
                    .css('-ms-transform', 'translateX('+offset+'px)')
                    .css('-o-transform', 'translateX('+offset+'px)')
                    .css('transform', 'translateX('+offset+'px)');
            }
        },

        limit_to : function(val, min, max) {
            return Math.min(Math.max(val, min), max);
        },

        initialize_settings : function(handle) {
            var settings = $.extend({}, this.settings, this.data_options($(handle).parent()));

            if (settings.vertical) {
                $.data(handle, 'bar_o', $(handle).parent().offset().top);
                $.data(handle, 'bar_l', $(handle).parent().outerHeight());
                $.data(handle, 'handle_o', $(handle).offset().top);
                $.data(handle, 'handle_l', $(handle).outerHeight());
            } else {
                $.data(handle, 'bar_o', $(handle).parent().offset().left);
                $.data(handle, 'bar_l', $(handle).parent().outerWidth());
                $.data(handle, 'handle_o', $(handle).offset().left);
                $.data(handle, 'handle_l', $(handle).outerWidth());
            }

            $.data(handle, 'bar', $(handle).parent());
            $.data(handle, 'settings', settings);
        },

        set_initial_position : function($ele) {
            var settings = $.data($ele.children('.range-slider-handle')[0], 'settings'),
                initial = (!!settings.initial ? settings.initial : Math.floor((settings.end-settings.start)*0.5/settings.step)*settings.step+settings.start),
                $handle = $ele.children('.range-slider-handle');
            this.set_ui($handle, initial);
        },

        set_value : function(value) {
            var self = this;
            $('[' + self.attr_name() + ']', this.scope).each(function(){
                $(this).attr(self.attr_name(), value);
            });
            if (!!$(this.scope).attr(self.attr_name())) {
                $(this.scope).attr(self.attr_name(), value);
            }
            self.reflow();
        },

        reflow : function() {
            var self = this;
            self.S('[' + this.attr_name() + ']').each(function() {
                var handle = $(this).children('.range-slider-handle')[0],
                    val = $(this).attr(self.attr_name());
                self.initialize_settings(handle);

                if (val) {
                    self.set_ui($(handle), parseFloat(val));
                } else {
                    self.set_initial_position($(this));
                }
            });
        }
    };

}(jQuery, window, window.document));
;(function ($, window, document, undefined) {
    'use strict';

    Foundation.libs.tab = {
        name : 'tab',

        version : '5.4.6',

        settings : {
            active_class: 'active',
            callback : function () {},
            deep_linking: false,
            scroll_to_content: true,
            is_hover: false
        },

        default_tab_hashes: [],

        init : function (scope, method, options) {
            var self = this,
                S = this.S;

            this.bindings(method, options);
            this.handle_location_hash_change();

            // Store the default active tabs which will be referenced when the
            // location hash is absent, as in the case of navigating the tabs and
            // returning to the first viewing via the browser Back button.
            S('[' + this.attr_name() + '] > .active > a', this.scope).each(function () {
                self.default_tab_hashes.push(this.hash);
            });
        },

        events : function () {
            var self = this,
                S = this.S;

            var usual_tab_behavior =  function (e) {
                var settings = S(this).closest('[' + self.attr_name() +']').data(self.attr_name(true) + '-init');
                if (!settings.is_hover || Modernizr.touch) {
                    e.preventDefault();
                    e.stopPropagation();
                    self.toggle_active_tab(S(this).parent());
                }
            };

            S(this.scope)
                .off('.tab')
                // Click event: tab title
                .on('focus.fndtn.tab', '[' + this.attr_name() + '] > * > a', usual_tab_behavior )
                .on('click.fndtn.tab', '[' + this.attr_name() + '] > * > a', usual_tab_behavior )
                // Hover event: tab title
                .on('mouseenter.fndtn.tab', '[' + this.attr_name() + '] > * > a', function (e) {
                    var settings = S(this).closest('[' + self.attr_name() +']').data(self.attr_name(true) + '-init');
                    if (settings.is_hover) self.toggle_active_tab(S(this).parent());
                });

            // Location hash change event
            S(window).on('hashchange.fndtn.tab', function (e) {
                e.preventDefault();
                self.handle_location_hash_change();
            });
        },

        handle_location_hash_change : function () {

            var self = this,
                S = this.S;

            S('[' + this.attr_name() + ']', this.scope).each(function () {
                var settings = S(this).data(self.attr_name(true) + '-init');
                if (settings.deep_linking) {
                    // Match the location hash to a label
                    var hash;
                    if (settings.scroll_to_content) {
                        hash = self.scope.location.hash;
                    } else {
                        // prefix the hash to prevent anchor scrolling
                        hash = self.scope.location.hash.replace('fndtn-', '');
                    }
                    if (hash != '') {
                        // Check whether the location hash references a tab content div or
                        // another element on the page (inside or outside the tab content div)
                        var hash_element = S(hash);
                        if (hash_element.hasClass('content') && hash_element.parent().hasClass('tab-content')) {
                            // Tab content div
                            self.toggle_active_tab($('[' + self.attr_name() + '] > * > a[href=' + hash + ']').parent());
                        } else {
                            // Not the tab content div. If inside the tab content, find the
                            // containing tab and toggle it as active.
                            var hash_tab_container_id = hash_element.closest('.content').attr('id');
                            if (hash_tab_container_id != undefined) {
                                self.toggle_active_tab($('[' + self.attr_name() + '] > * > a[href=#' + hash_tab_container_id + ']').parent(), hash);
                            }
                        }
                    } else {
                        // Reference the default tab hashes which were initialized in the init function
                        for (var ind = 0; ind < self.default_tab_hashes.length; ind++) {
                            self.toggle_active_tab($('[' + self.attr_name() + '] > * > a[href=' + self.default_tab_hashes[ind] + ']').parent());
                        }
                    }
                }
            });
        },

        toggle_active_tab: function (tab, location_hash) {
            var S = this.S,
                tabs = tab.closest('[' + this.attr_name() + ']'),
                tab_link = tab.find('a'),
                anchor = tab.children('a').first(),
                target_hash = '#' + anchor.attr('href').split('#')[1],
                target = S(target_hash),
                siblings = tab.siblings(),
                settings = tabs.data(this.attr_name(true) + '-init'),
                interpret_keyup_action = function(e) {
                    // Light modification of Heydon Pickering's Practical ARIA Examples: http://heydonworks.com/practical_aria_examples/js/a11y.js

                    // define current, previous and next (possible) tabs

                    var $original = $(this);
                    var $prev = $(this).parents('li').prev().children('[role="tab"]');
                    var $next = $(this).parents('li').next().children('[role="tab"]');
                    var $target;

                    // find the direction (prev or next)

                    switch (e.keyCode) {
                        case 37:
                            $target = $prev;
                            break;
                        case 39:
                            $target = $next;
                            break;
                        default:
                            $target = false
                            break;
                    }

                    if ($target.length) {
                        $original.attr({
                            'tabindex' : '-1',
                            'aria-selected' : null
                        });
                        $target.attr({
                            'tabindex' : '0',
                            'aria-selected' : true
                        }).focus();
                    }

                    // Hide panels

                    $('[role="tabpanel"]')
                        .attr('aria-hidden', 'true');

                    // Show panel which corresponds to target

                    $('#' + $(document.activeElement).attr('href').substring(1))
                        .attr('aria-hidden', null);

                };

            // allow usage of data-tab-content attribute instead of href
            if (S(this).data(this.data_attr('tab-content'))) {
                target_hash = '#' + S(this).data(this.data_attr('tab-content')).split('#')[1];
                target = S(target_hash);
            }

            if (settings.deep_linking) {

                if (settings.scroll_to_content) {
                    // retain current hash to scroll to content
                    window.location.hash = location_hash || target_hash;
                    if (location_hash == undefined || location_hash == target_hash) {
                        tab.parent()[0].scrollIntoView();
                    } else {
                        S(target_hash)[0].scrollIntoView();
                    }
                } else {
                    // prefix the hashes so that the browser doesn't scroll down
                    if (location_hash != undefined) {
                        window.location.hash = 'fndtn-' + location_hash.replace('#', '');
                    } else {
                        window.location.hash = 'fndtn-' + target_hash.replace('#', '');
                    }
                }
            }

            // WARNING: The activation and deactivation of the tab content must
            // occur after the deep linking in order to properly refresh the browser
            // window (notably in Chrome).
            // Clean up multiple attr instances to done once
            tab.addClass(settings.active_class).triggerHandler('opened');
            tab_link.attr({"aria-selected": "true",  tabindex: 0});
            siblings.removeClass(settings.active_class)
            siblings.find('a').attr({"aria-selected": "false",  tabindex: -1});
            target.siblings().removeClass(settings.active_class).attr({"aria-hidden": "true",  tabindex: -1});
            target.addClass(settings.active_class).attr('aria-hidden', 'false').removeAttr("tabindex");
            settings.callback(tab);
            target.triggerHandler('toggled', [tab]);
            tabs.triggerHandler('toggled', [target]);

            tab_link.off('keydown').on('keydown', interpret_keyup_action );
        },

        data_attr: function (str) {
            if (this.namespace.length > 0) {
                return this.namespace + '-' + str;
            }

            return str;
        },

        off : function () {},

        reflow : function () {}
    };
}(jQuery, window, window.document));
;(function ($, window, document, undefined) {
    'use strict';

    Foundation.libs.topbar = {
        name : 'topbar',

        version: '5.4.6',

        settings : {
            index : 0,
            sticky_class : 'sticky',
            custom_back_text: true,
            back_text: 'Back',
            mobile_show_parent_link: true,
            is_hover: true,
            scrolltop : true, // jump to top when sticky nav menu toggle is clicked
            sticky_on : 'all'
        },

        init : function (section, method, options) {
            Foundation.inherit(this, 'add_custom_rule register_media throttle');
            var self = this;

            self.register_media('topbar', 'foundation-mq-topbar');

            this.bindings(method, options);

            self.S('[' + this.attr_name() + ']', this.scope).each(function () {
                var topbar = $(this),
                    settings = topbar.data(self.attr_name(true) + '-init'),
                    section = self.S('section, .top-bar-section', this);
                topbar.data('index', 0);
                var topbarContainer = topbar.parent();
                if (topbarContainer.hasClass('fixed') || self.is_sticky(topbar, topbarContainer, settings) ) {
                    self.settings.sticky_class = settings.sticky_class;
                    self.settings.sticky_topbar = topbar;
                    topbar.data('height', topbarContainer.outerHeight());
                    topbar.data('stickyoffset', topbarContainer.offset().top);
                } else {
                    topbar.data('height', topbar.outerHeight());
                }

                if (!settings.assembled) {
                    self.assemble(topbar);
                }

                if (settings.is_hover) {
                    self.S('.has-dropdown', topbar).addClass('not-click');
                } else {
                    self.S('.has-dropdown', topbar).removeClass('not-click');
                }

                // Pad body when sticky (scrolled) or fixed.
                self.add_custom_rule('.f-topbar-fixed { padding-top: ' + topbar.data('height') + 'px }');

                if (topbarContainer.hasClass('fixed')) {
                    self.S('body').addClass('f-topbar-fixed');
                }
            });

        },

        is_sticky: function (topbar, topbarContainer, settings) {
            var sticky = topbarContainer.hasClass(settings.sticky_class);

            if (sticky && settings.sticky_on === 'all') {
                return true;
            } else if (sticky && this.small() && settings.sticky_on === 'small') {
                return (matchMedia(Foundation.media_queries.small).matches && !matchMedia(Foundation.media_queries.medium).matches &&
                    !matchMedia(Foundation.media_queries.large).matches);
                //return true;
            } else if (sticky && this.medium() && settings.sticky_on === 'medium') {
                return (matchMedia(Foundation.media_queries.small).matches && matchMedia(Foundation.media_queries.medium).matches &&
                    !matchMedia(Foundation.media_queries.large).matches);
                //return true;
            } else if(sticky && this.large() && settings.sticky_on === 'large') {
                return (matchMedia(Foundation.media_queries.small).matches && matchMedia(Foundation.media_queries.medium).matches &&
                    matchMedia(Foundation.media_queries.large).matches);
                //return true;
            }

            return false;
        },

        toggle: function (toggleEl) {
            var self = this,
                topbar;

            if (toggleEl) {
                topbar = self.S(toggleEl).closest('[' + this.attr_name() + ']');
            } else {
                topbar = self.S('[' + this.attr_name() + ']');
            }

            var settings = topbar.data(this.attr_name(true) + '-init');

            var section = self.S('section, .top-bar-section', topbar);

            if (self.breakpoint()) {
                if (!self.rtl) {
                    section.css({left: '0%'});
                    $('>.name', section).css({left: '100%'});
                } else {
                    section.css({right: '0%'});
                    $('>.name', section).css({right: '100%'});
                }

                self.S('li.moved', section).removeClass('moved');
                topbar.data('index', 0);

                topbar
                    .toggleClass('expanded')
                    .css('height', '');
            }

            if (settings.scrolltop) {
                if (!topbar.hasClass('expanded')) {
                    if (topbar.hasClass('fixed')) {
                        topbar.parent().addClass('fixed');
                        topbar.removeClass('fixed');
                        self.S('body').addClass('f-topbar-fixed');
                    }
                } else if (topbar.parent().hasClass('fixed')) {
                    if (settings.scrolltop) {
                        topbar.parent().removeClass('fixed');
                        topbar.addClass('fixed');
                        self.S('body').removeClass('f-topbar-fixed');

                        window.scrollTo(0,0);
                    } else {
                        topbar.parent().removeClass('expanded');
                    }
                }
            } else {
                if (self.is_sticky(topbar, topbar.parent(), settings)) {
                    topbar.parent().addClass('fixed');
                }

                if (topbar.parent().hasClass('fixed')) {
                    if (!topbar.hasClass('expanded')) {
                        topbar.removeClass('fixed');
                        topbar.parent().removeClass('expanded');
                        self.update_sticky_positioning();
                    } else {
                        topbar.addClass('fixed');
                        topbar.parent().addClass('expanded');
                        self.S('body').addClass('f-topbar-fixed');
                    }
                }
            }
        },

        timer : null,

        events : function (bar) {
            var self = this,
                S = this.S;

            S(this.scope)
                .off('.topbar')
                .on('click.fndtn.topbar', '[' + this.attr_name() + '] .toggle-topbar', function (e) {
                    e.preventDefault();
                    self.toggle(this);
                })
                .on('click.fndtn.topbar','.top-bar .top-bar-section li a[href^="#"],[' + this.attr_name() + '] .top-bar-section li a[href^="#"]',function (e) {
                    var li = $(this).closest('li');
                    if(self.breakpoint() && !li.hasClass('back') && !li.hasClass('has-dropdown'))
                    {
                        self.toggle();
                    }
                })
                .on('click.fndtn.topbar', '[' + this.attr_name() + '] li.has-dropdown', function (e) {
                    var li = S(this),
                        target = S(e.target),
                        topbar = li.closest('[' + self.attr_name() + ']'),
                        settings = topbar.data(self.attr_name(true) + '-init');

                    if(target.data('revealId')) {
                        self.toggle();
                        return;
                    }

                    if (self.breakpoint()) return;
                    if (settings.is_hover && !Modernizr.touch) return;

                    e.stopImmediatePropagation();

                    if (li.hasClass('hover')) {
                        li
                            .removeClass('hover')
                            .find('li')
                            .removeClass('hover');

                        li.parents('li.hover')
                            .removeClass('hover');
                    } else {
                        li.addClass('hover');

                        $(li).siblings().removeClass('hover');

                        if (target[0].nodeName === 'A' && target.parent().hasClass('has-dropdown')) {
                            e.preventDefault();
                        }
                    }
                })
                .on('click.fndtn.topbar', '[' + this.attr_name() + '] .has-dropdown>a', function (e) {
                    if (self.breakpoint()) {

                        e.preventDefault();

                        var $this = S(this),
                            topbar = $this.closest('[' + self.attr_name() + ']'),
                            section = topbar.find('section, .top-bar-section'),
                            dropdownHeight = $this.next('.dropdown').outerHeight(),
                            $selectedLi = $this.closest('li');

                        topbar.data('index', topbar.data('index') + 1);
                        $selectedLi.addClass('moved');

                        if (!self.rtl) {
                            section.css({left: -(100 * topbar.data('index')) + '%'});
                            section.find('>.name').css({left: 100 * topbar.data('index') + '%'});
                        } else {
                            section.css({right: -(100 * topbar.data('index')) + '%'});
                            section.find('>.name').css({right: 100 * topbar.data('index') + '%'});
                        }

                        topbar.css('height', $this.siblings('ul').outerHeight(true) + topbar.data('height'));
                    }
                });

            S(window).off(".topbar").on("resize.fndtn.topbar", self.throttle(function() {
                self.resize.call(self);
            }, 50)).trigger("resize").trigger("resize.fndtn.topbar").load(function(){
                // Ensure that the offset is calculated after all of the pages resources have loaded
                S(this).trigger("resize.fndtn.topbar");
            });

            S('body').off('.topbar').on('click.fndtn.topbar', function (e) {
                var parent = S(e.target).closest('li').closest('li.hover');

                if (parent.length > 0) {
                    return;
                }

                S('[' + self.attr_name() + '] li.hover').removeClass('hover');
            });

            // Go up a level on Click
            S(this.scope).on('click.fndtn.topbar', '[' + this.attr_name() + '] .has-dropdown .back', function (e) {
                e.preventDefault();

                var $this = S(this),
                    topbar = $this.closest('[' + self.attr_name() + ']'),
                    section = topbar.find('section, .top-bar-section'),
                    settings = topbar.data(self.attr_name(true) + '-init'),
                    $movedLi = $this.closest('li.moved'),
                    $previousLevelUl = $movedLi.parent();

                topbar.data('index', topbar.data('index') - 1);

                if (!self.rtl) {
                    section.css({left: -(100 * topbar.data('index')) + '%'});
                    section.find('>.name').css({left: 100 * topbar.data('index') + '%'});
                } else {
                    section.css({right: -(100 * topbar.data('index')) + '%'});
                    section.find('>.name').css({right: 100 * topbar.data('index') + '%'});
                }

                if (topbar.data('index') === 0) {
                    topbar.css('height', '');
                } else {
                    topbar.css('height', $previousLevelUl.outerHeight(true) + topbar.data('height'));
                }

                setTimeout(function () {
                    $movedLi.removeClass('moved');
                }, 300);
            });

            // Show dropdown menus when their items are focused
            S(this.scope).find('.dropdown a')
                .focus(function() {
                    $(this).parents('.has-dropdown').addClass('hover');
                })
                .blur(function() {
                    $(this).parents('.has-dropdown').removeClass('hover');
                });
        },

        resize : function () {
            var self = this;
            self.S('[' + this.attr_name() + ']').each(function () {
                var topbar = self.S(this),
                    settings = topbar.data(self.attr_name(true) + '-init');

                var stickyContainer = topbar.parent('.' + self.settings.sticky_class);
                var stickyOffset;

                if (!self.breakpoint()) {
                    var doToggle = topbar.hasClass('expanded');
                    topbar
                        .css('height', '')
                        .removeClass('expanded')
                        .find('li')
                        .removeClass('hover');

                    if(doToggle) {
                        self.toggle(topbar);
                    }
                }

                if(self.is_sticky(topbar, stickyContainer, settings)) {
                    if(stickyContainer.hasClass('fixed')) {
                        // Remove the fixed to allow for correct calculation of the offset.
                        stickyContainer.removeClass('fixed');

                        stickyOffset = stickyContainer.offset().top;
                        if(self.S(document.body).hasClass('f-topbar-fixed')) {
                            stickyOffset -= topbar.data('height');
                        }

                        topbar.data('stickyoffset', stickyOffset);
                        stickyContainer.addClass('fixed');
                    } else {
                        stickyOffset = stickyContainer.offset().top;
                        topbar.data('stickyoffset', stickyOffset);
                    }
                }

            });
        },

        breakpoint : function () {
            return !matchMedia(Foundation.media_queries['topbar']).matches;
        },

        small : function () {
            return matchMedia(Foundation.media_queries['small']).matches;
        },

        medium : function () {
            return matchMedia(Foundation.media_queries['medium']).matches;
        },

        large : function () {
            return matchMedia(Foundation.media_queries['large']).matches;
        },

        assemble : function (topbar) {
            var self = this,
                settings = topbar.data(this.attr_name(true) + '-init'),
                section = self.S('section, .top-bar-section', topbar);

            // Pull element out of the DOM for manipulation
            section.detach();

            self.S('.has-dropdown>a', section).each(function () {
                var $link = self.S(this),
                    $dropdown = $link.siblings('.dropdown'),
                    url = $link.attr('href'),
                    $titleLi;


                if (!$dropdown.find('.title.back').length) {

                    if (settings.mobile_show_parent_link == true && url) {
                        $titleLi = $('<li class="title back js-generated"><h5><a href="javascript:void(0)"></a></h5></li><li class="parent-link show-for-small"><a class="parent-link js-generated" href="' + url + '">' + $link.html() +'</a></li>');
                    } else {
                        $titleLi = $('<li class="title back js-generated"><h5><a href="javascript:void(0)"></a></h5>');
                    }

                    // Copy link to subnav
                    if (settings.custom_back_text == true) {
                        $('h5>a', $titleLi).html(settings.back_text);
                    } else {
                        $('h5>a', $titleLi).html('&laquo; ' + $link.html());
                    }
                    $dropdown.prepend($titleLi);
                }
            });

            // Put element back in the DOM
            section.appendTo(topbar);

            // check for sticky
            this.sticky();

            this.assembled(topbar);
        },

        assembled : function (topbar) {
            topbar.data(this.attr_name(true), $.extend({}, topbar.data(this.attr_name(true)), {assembled: true}));
        },

        height : function (ul) {
            var total = 0,
                self = this;

            $('> li', ul).each(function () {
                total += self.S(this).outerHeight(true);
            });

            return total;
        },

        sticky : function () {
            var self = this;

            this.S(window).on('scroll', function() {
                self.update_sticky_positioning();
            });
        },

        update_sticky_positioning: function() {
            var klass = '.' + this.settings.sticky_class,
                $window = this.S(window),
                self = this;

            if (self.settings.sticky_topbar && self.is_sticky(this.settings.sticky_topbar,this.settings.sticky_topbar.parent(), this.settings)) {
                var distance = this.settings.sticky_topbar.data('stickyoffset');
                if (!self.S(klass).hasClass('expanded')) {
                    if ($window.scrollTop() > (distance)) {
                        if (!self.S(klass).hasClass('fixed')) {
                            self.S(klass).addClass('fixed');
                            self.S('body').addClass('f-topbar-fixed');
                        }
                    } else if ($window.scrollTop() <= distance) {
                        if (self.S(klass).hasClass('fixed')) {
                            self.S(klass).removeClass('fixed');
                            self.S('body').removeClass('f-topbar-fixed');
                        }
                    }
                }
            }
        },

        off : function () {
            this.S(this.scope).off('.fndtn.topbar');
            this.S(window).off('.fndtn.topbar');
        },

        reflow : function () {}
    };
}(jQuery, window, window.document));
