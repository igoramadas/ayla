ko.bindingHandlers.colorPicker = {
    init: function(el, va, ab) {
    },
    update: function(el, va, ab) {
        console.warn(el);
        $(el).colorPicker();
    }
};