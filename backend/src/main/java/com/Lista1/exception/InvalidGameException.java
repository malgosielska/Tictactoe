package com.Lista1.exception;

public class InvalidGameException extends RuntimeException{
    private String message;
    public InvalidGameException(String message){
        this.message = message;
    }

    public String getMessage(){
        return message;
    }
}
