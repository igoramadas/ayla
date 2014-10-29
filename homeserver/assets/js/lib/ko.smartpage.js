ko.bindingHandlers.smartPage = {
    init: function (element, valueAccessor, allBindingsAccessor, viewModel, bindingContext) {
        var customValueAccessor = function() {
            var result = valueAccessor();
            result.withOnShow = viewModel.bindPage;
            return result;
        };

        var page = new pager.Page(element, customValueAccessor, allBindingsAccessor, viewModel, bindingContext);
        page.init();
    },

    update:function () {
    }
};
