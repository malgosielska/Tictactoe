package com.Lista1.controller;

import com.Lista1.controller.dto.ConnectRequest;
import com.Lista1.exception.InvalidGameException;
import com.Lista1.exception.InvalidParamException;
import com.Lista1.exception.NotFoundException;
import com.Lista1.model.Game;
import com.Lista1.model.GamePlay;
import com.Lista1.model.Player;
import com.Lista1.service.GameService;
import lombok.AllArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.messaging.simp.SimpMessagingTemplate;

@RestController
@Slf4j
@AllArgsConstructor
@CrossOrigin
@RequestMapping("/game")
public class GameController {
    private final GameService gameService;
    private final SimpMessagingTemplate simpMessagingTemplate;

    @PostMapping("/start")
    public ResponseEntity<Game> start(@RequestBody Player player){
        log.info("Starting game for player {}", player);
        return ResponseEntity.ok(gameService.createGame(player));
    }

    @PostMapping("/connect")
    public ResponseEntity<Game> connect(@RequestBody ConnectRequest request) throws InvalidParamException, InvalidGameException{
        log.info("Connect request {}", request);
        return ResponseEntity.ok(gameService.connectToGame(request.getPlayer(), request.getGameId()));
    }

    @PostMapping("/connect/random")
    public ResponseEntity<Game> connectRandom(@RequestBody Player player) throws NotFoundException {
        log.info("Connect random request {}", player);
        return ResponseEntity.ok(gameService.connectToRandomGame(player));
    }

    @PostMapping("/gameplay")
    public ResponseEntity<Game> gamePlay(@RequestBody GamePlay request) throws NotFoundException, InvalidGameException{
        log.info("Gameplay request {}", request);
        Game game = gameService.gamePlay(request);
        simpMessagingTemplate.convertAndSend("/topic/game-progress/"+game.getGameId(), game);
        return ResponseEntity.ok(game);
    }
}
