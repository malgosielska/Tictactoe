let turns = [["#", "#", "#"], ["#", "#", "#"], ["#", "#", "#"]];
let turn = '';
let gameOn = false;

function playerTurn(turn, id) {
    if (gameOn) {
        let spotTaken = $("#" + id).text();
        if (spotTaken === "#") {
            if (turn === 'X') {
                turn = "O";
            } else {
                turn = "X";
            }
            makeAMove(turn, playerType, id.split("_")[0], id.split("_")[1]);
        }
    }
}

function makeAMove(turn, type, xCoordinate, yCoordinate) {
    $.ajax({
        url: url + "/game/gameplay",
        type: 'POST',
        dataType: "json",
        contentType: "application/json",
        data: JSON.stringify({
            "turn": turn,
            "type": type,
            "coordinateX": xCoordinate,
            "coordinateY": yCoordinate,
            "gameId": gameId
        }),
        success: function (data) {
            gameOn = false;
            displayResponse(data);
        },
        error: function (error) {
            console.log(error);
        }
    })
}

function displayResponse(data) {
    let board = data.board;
    let turnNow = data.turn;
    for (let i = 0; i < board.length; i++) {
        for (let j = 0; j < board[i].length; j++) {
            if (board[i][j] === 1) {
                turns[i][j] = 'X'
            } else if (board[i][j] === 2) {
                turns[i][j] = 'O';
            }
            let id = i + "_" + j;
            $("#" + id).text(turns[i][j]);
        }
    }
    if (data.winner != null) {
        alert("Winner is " + data.winner);
    } else {
        gameOn = (turnNow === playerType);
    }
}

$(".tic").click(function () {
    let slot = $(this).attr('id');
    playerTurn(playerType, slot);
});

function reset() {
    turns = [["#", "#", "#"], ["#", "#", "#"], ["#", "#", "#"]];
    $(".tic").text("#");
}

$("#reset").click(function () {
    reset();
});
