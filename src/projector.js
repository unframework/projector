(typeof define !== 'undefined' && define !== null ?
    define.bind(null, ['indentation', 'projectorHtml']) :
    function(deps, module) { window.ngProjector = module(window.indentation, window.projectorHtml); }
)(function (indentation, projectorHtml) {
    'use strict';

    return function ngProjector(subTemplate) {
        function attachScope(instance, ngScope) {
            instance.watch = function (getter, subTemplate) {
                ngScope.$watch(getter, function (v) {
                    this.fork(function () {
                        subTemplate.call(this, v);
                    });
                }.bind(this));
            };

            instance.refresh = function () {
                ngScope.$apply();
            };

            instance.scope = function (subTemplate) {
                var subScope = ngScope.$new();

                this.fork(function () {
                    attachScope(this, subScope);

                    this.fork(subTemplate);
                });

                return function () { ngScope.$destroy(); };
            };
        }

        var controller = function ($scope, $element) {
            indentation(function () {
                attachScope(this, $scope);

                projectorHtml(this, function (dom) {
                    $element.append(dom);
                });

                this.fork(subTemplate);
            });
        };

        controller.$inject = [ '$scope', '$element' ];

        return controller;
    };
});
