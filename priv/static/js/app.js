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

    $scope.players = room.all("players").getList();

    $scope.addBot = function() {
        room.all('bots').post()
        .then(function() {
            $scope.players = room.all("players").getList();
        });
    };

    room.all("players").post().then(
        function(e) {
            console.log(e.data);
        }
    )

/*    var bullet = $.bullet('ws://localhost:9999/bullet/game');

    bullet.onopen = function() {
        console.log('Open');
    };
    bullet.onclose = function() {
        console.log('close');
    };
    bullet.onmessage = function(e) {
        alert(e.data);
    };
    bullet.onheartbeat = function() {
        console.log('Got ping');
    }*/
});
