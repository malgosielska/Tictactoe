package com.Lista1.storage;

import com.Lista1.model.Game;

import java.util.HashMap;
import java.util.Map;

public class GameStorage {
    private static Map<String, Game> games;
    private static GameStorage instance;
    private GameStorage() {
        games = new HashMap<>();
    }

    public static synchronized GameStorage getInstance(){
        if(instance==null){
            instance = new GameStorage();
        }
        return instance;
    }

    public Map<String, Game> getGames() {
        return games;
    }

    public void setGame(Game game) {
        games.put(game.getGameId(), game);
    }
}
