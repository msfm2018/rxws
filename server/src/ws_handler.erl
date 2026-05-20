-module(ws_handler).
-behaviour(cowboy_websocket).

-export([init/2]).
-export([websocket_init/1, websocket_handle/2, websocket_info/2]).

init(Req0, State) ->
    Headers = cowboy_req:headers(Req0),
    io:format("=== WebSocket Headers ===~n~p~n", [Headers]),
    
    Key = maps:get(<<"sec-websocket-key">>, Headers, undefined),
    io:format("Sec-WebSocket-Key: ~p~n", [Key]),
    
    {cowboy_websocket, Req0, State}.

websocket_init(State) ->
    %% 定时发送消息
    {ok, State}.

websocket_handle(ping, State) ->
    io:format("Received ping from client~n"),
    {ok, State};                    % 不需要手动返回 pong，Cowboy 已自动处理

websocket_handle({text, Msg}, State) ->
    io:format("收到: ~p~n", [Msg]),
    {reply, {text, <<"echo: ", Msg/binary>>}, State};

websocket_handle({binary, Data}, State) ->
    io:format("收到二进制: ~p~n", [Data]),
    {reply, {binary, Data}, State};

websocket_handle(Data, State) ->
    io:format("websocket_handle (未知) -------------> ~p~n", [Data]),
    {ok, State}.


websocket_info(D, State) ->
        io:format("websocket_info:::::::::::::::~p~n",[D]),
    {ok, State}.