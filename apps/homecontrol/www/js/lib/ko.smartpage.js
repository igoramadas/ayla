ko.bindingHandlers.smartPage = {
    init: function (element, valueAccessor, allBindingsAccessor, viewModel, bindingContext) {
        var customValueAccessor = function() {
            var result = valueAccessor();
            result.withOnShow = viewModel.bindPage;
            return result;
        };

        var customAllBindingsAccessor = function() {
            var result = allBindingsAccessor();
            result.smartPage.withOnShow = viewModel.bindPage;
            return result;
        };

        var page = new pager.Page(element, customValueAccessor, customAllBindingsAccessor, viewModel, bindingContext);
        return page.init();
    }
};
