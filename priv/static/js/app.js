angular.module('KozelApp', ['restangular'])
.config(function(RestangularProvider) {
    RestangularProvider.setBaseUrl('/api');
})
.config(function($routeProvider) {
    $routeProvider
    .when('/', {templateUrl: '/template/rooms',
                controller: 'RoomsController'})
    .when('/rooms/:roomName', {templateUrl: 'template/room',
                               controller: 'RoomController'});
})
.controller('RoomsController', function($scope, Restangular, $location) {
    var roomsList = Restangular.all('rooms');
    $scope.rooms = roomsList.getList();

    $scope.createRoom = function() {
        roomsList.post().then(function() {
            $scope.rooms = roomsList.getList();
        });
    };

    $scope.joinRoom = function(roomName) {
        $location.path('/rooms/' + roomName);
    };
})
.controller('RoomController', function($scope, $routeParams,
                                       Restangular) {
    var room = Restangular.one('rooms', $routeParams.roomName);
    $scope.addBot = function() {
        room.all('bots').post();
    };
});
