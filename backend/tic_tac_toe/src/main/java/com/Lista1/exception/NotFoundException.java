package com.Lista1.exception;

public class NotFoundException extends RuntimeException{
    private String message;
    public NotFoundException(String message){
        this.message = message;
    }

    public String getMessage(){
        return message;
    }
}
