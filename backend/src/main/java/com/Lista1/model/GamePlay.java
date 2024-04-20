package com.Lista1.model;

import lombok.Data;

@Data
public class GamePlay {

    private String turn;
    private TicTacToe type;
    private Integer coordinateX;
    private Integer coordinateY;
    private String gameId;
}
