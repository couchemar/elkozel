angular.module('KozelApp', ['restangular'])
.config(function(RestangularProvider) {
    RestangularProvider.setBaseUrl('/api');
})
.config(function($routeProvider) {
    $routeProvider
    .when('/', {templateUrl: '/template/rooms',
                controller: 'RoomsController'});
})
.controller('RoomsController', function($scope, Restangular) {
    var roomsList = Restangular.all('rooms');
    $scope.rooms = roomsList.getList();

    $scope.createRoom = function() {
        roomsList.post().then(function() {
            $scope.rooms = roomsList.getList();
        });
    };

});
