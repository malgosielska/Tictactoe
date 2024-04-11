package com.Lista1.controller.dto;

import com.Lista1.model.Player;
import lombok.Data;

@Data
public class ConnectRequest {
    private String gameId;
    private Player player;
}
