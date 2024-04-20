package com.Lista1.model;

import lombok.Data;

@Data
public class Game {

    private String turn;
    private String gameId;
    private Player player1;
    private Player player2;
    private GameStatus status;
    private int [][] board;
    private TicTacToe winner;
}
