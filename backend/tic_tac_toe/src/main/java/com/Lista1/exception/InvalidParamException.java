package com.Lista1.exception;

public class InvalidParamException extends RuntimeException{
    private String message;
    public InvalidParamException(String message){
        this.message = message;
    }

    public String getMessage(){
        return message;
    }
}
