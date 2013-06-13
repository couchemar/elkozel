angular.module('KozelApp', ['restangular'])
.config(function(RestangularProvider) {
    RestangularProvider.setBaseUrl('/api');
})
.controller('RoomsController', function($scope, Restangular) {
    var roomsList = Restangular.all('rooms');
    $scope.rooms = roomsList.getList();
});
