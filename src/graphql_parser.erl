-module(graphql_parser).
-export([parse/1, parse_and_scan/1, format_error/1]).
-file("src/graphql_parser.yrl", 204).

extract_atom({Value, _Line}) -> Value.
extract_token({_Token, _Line, Value}) -> Value.
extract_integer({_Token, _Line, Value}) ->
  {Int, []} = string:to_integer(Value), Int.
extract_float({_Token, _Line, Value}) ->
  {Float, []} = string:to_float(Value), Float.
extract_boolean({_Token, _Line, "true"}) -> true;
extract_boolean({_Token, _Line, "false"}) -> false.
extract_keyword({Value, _Line}) -> atom_to_list(Value).

build_ast_node(Type, Tuple) when is_list(Tuple) ->
  [{kind, Type}, {loc, [{start, 0}]}] ++ Tuple;
build_ast_node(Type, Tuple) when is_tuple(Tuple) ->
  [{kind, Type}, {loc, [{start, 0}]}, Tuple].

-file("/usr/local/Cellar/erlang/17.5/lib/erlang/lib/parsetools-2.0.12/include/yeccpre.hrl", 0).
%%
%% %CopyrightBegin%
%%
%% Copyright Ericsson AB 1996-2013. All Rights Reserved.
%%
%% The contents of this file are subject to the Erlang Public License,
%% Version 1.1, (the "License"); you may not use this file except in
%% compliance with the License. You should have received a copy of the
%% Erlang Public License along with this software. If not, it can be
%% retrieved online at http://www.erlang.org/.
%%
%% Software distributed under the License is distributed on an "AS IS"
%% basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See
%% the License for the specific language governing rights and limitations
%% under the License.
%%
%% %CopyrightEnd%
%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% The parser generator will insert appropriate declarations before this line.%

-type yecc_ret() :: {'error', _} | {'ok', _}.

-spec parse(Tokens :: list()) -> yecc_ret().
parse(Tokens) ->
    yeccpars0(Tokens, {no_func, no_line}, 0, [], []).

-spec parse_and_scan({function() | {atom(), atom()}, [_]}
                     | {atom(), atom(), [_]}) -> yecc_ret().
parse_and_scan({F, A}) ->
    yeccpars0([], {{F, A}, no_line}, 0, [], []);
parse_and_scan({M, F, A}) ->
    Arity = length(A),
    yeccpars0([], {{fun M:F/Arity, A}, no_line}, 0, [], []).

-spec format_error(any()) -> [char() | list()].
format_error(Message) ->
    case io_lib:deep_char_list(Message) of
        true ->
            Message;
        _ ->
            io_lib:write(Message)
    end.

%% To be used in grammar files to throw an error message to the parser
%% toplevel. Doesn't have to be exported!
-compile({nowarn_unused_function, return_error/2}).
-spec return_error(integer(), any()) -> no_return().
return_error(Line, Message) ->
    throw({error, {Line, ?MODULE, Message}}).

-define(CODE_VERSION, "1.4").

yeccpars0(Tokens, Tzr, State, States, Vstack) ->
    try yeccpars1(Tokens, Tzr, State, States, Vstack)
    catch 
        error: Error ->
            Stacktrace = erlang:get_stacktrace(),
            try yecc_error_type(Error, Stacktrace) of
                Desc ->
                    erlang:raise(error, {yecc_bug, ?CODE_VERSION, Desc},
                                 Stacktrace)
            catch _:_ -> erlang:raise(error, Error, Stacktrace)
            end;
        %% Probably thrown from return_error/2:
        throw: {error, {_Line, ?MODULE, _M}} = Error ->
            Error
    end.

yecc_error_type(function_clause, [{?MODULE,F,ArityOrArgs,_} | _]) ->
    case atom_to_list(F) of
        "yeccgoto_" ++ SymbolL ->
            {ok,[{atom,_,Symbol}],_} = erl_scan:string(SymbolL),
            State = case ArityOrArgs of
                        [S,_,_,_,_,_,_] -> S;
                        _ -> state_is_unknown
                    end,
            {Symbol, State, missing_in_goto_table}
    end.

yeccpars1([Token | Tokens], Tzr, State, States, Vstack) ->
    yeccpars2(State, element(1, Token), States, Vstack, Token, Tokens, Tzr);
yeccpars1([], {{F, A},_Line}, State, States, Vstack) ->
    case apply(F, A) of
        {ok, Tokens, Endline} ->
            yeccpars1(Tokens, {{F, A}, Endline}, State, States, Vstack);
        {eof, Endline} ->
            yeccpars1([], {no_func, Endline}, State, States, Vstack);
        {error, Descriptor, _Endline} ->
            {error, Descriptor}
    end;
yeccpars1([], {no_func, no_line}, State, States, Vstack) ->
    Line = 999999,
    yeccpars2(State, '$end', States, Vstack, yecc_end(Line), [],
              {no_func, Line});
yeccpars1([], {no_func, Endline}, State, States, Vstack) ->
    yeccpars2(State, '$end', States, Vstack, yecc_end(Endline), [],
              {no_func, Endline}).

%% yeccpars1/7 is called from generated code.
%%
%% When using the {includefile, Includefile} option, make sure that
%% yeccpars1/7 can be found by parsing the file without following
%% include directives. yecc will otherwise assume that an old
%% yeccpre.hrl is included (one which defines yeccpars1/5).
yeccpars1(State1, State, States, Vstack, Token0, [Token | Tokens], Tzr) ->
    yeccpars2(State, element(1, Token), [State1 | States],
              [Token0 | Vstack], Token, Tokens, Tzr);
yeccpars1(State1, State, States, Vstack, Token0, [], {{_F,_A}, _Line}=Tzr) ->
    yeccpars1([], Tzr, State, [State1 | States], [Token0 | Vstack]);
yeccpars1(State1, State, States, Vstack, Token0, [], {no_func, no_line}) ->
    Line = yecctoken_end_location(Token0),
    yeccpars2(State, '$end', [State1 | States], [Token0 | Vstack],
              yecc_end(Line), [], {no_func, Line});
yeccpars1(State1, State, States, Vstack, Token0, [], {no_func, Line}) ->
    yeccpars2(State, '$end', [State1 | States], [Token0 | Vstack],
              yecc_end(Line), [], {no_func, Line}).

%% For internal use only.
yecc_end({Line,_Column}) ->
    {'$end', Line};
yecc_end(Line) ->
    {'$end', Line}.

yecctoken_end_location(Token) ->
    try
        {text, Str} = erl_scan:token_info(Token, text),
        {line, Line} = erl_scan:token_info(Token, line),
        Parts = re:split(Str, "\n"),
        Dline = length(Parts) - 1,
        Yline = Line + Dline,
        case erl_scan:token_info(Token, column) of
            {column, Column} ->
                Col = byte_size(lists:last(Parts)),
                {Yline, Col + if Dline =:= 0 -> Column; true -> 1 end};
            undefined ->
                Yline
        end
    catch _:_ ->
        yecctoken_location(Token)
    end.

-compile({nowarn_unused_function, yeccerror/1}).
yeccerror(Token) ->
    Text = yecctoken_to_string(Token),
    Location = yecctoken_location(Token),
    {error, {Location, ?MODULE, ["syntax error before: ", Text]}}.

-compile({nowarn_unused_function, yecctoken_to_string/1}).
yecctoken_to_string(Token) ->
    case catch erl_scan:token_info(Token, text) of
        {text, Txt} -> Txt;
        _ -> yecctoken2string(Token)
    end.

yecctoken_location(Token) ->
    case catch erl_scan:token_info(Token, location) of
        {location, Loc} -> Loc;
        _ -> element(2, Token)
    end.

-compile({nowarn_unused_function, yecctoken2string/1}).
yecctoken2string({atom, _, A}) -> io_lib:write(A);
yecctoken2string({integer,_,N}) -> io_lib:write(N);
yecctoken2string({float,_,F}) -> io_lib:write(F);
yecctoken2string({char,_,C}) -> io_lib:write_char(C);
yecctoken2string({var,_,V}) -> io_lib:format("~s", [V]);
yecctoken2string({string,_,S}) -> io_lib:write_string(S);
yecctoken2string({reserved_symbol, _, A}) -> io_lib:write(A);
yecctoken2string({_Cat, _, Val}) -> io_lib:format("~p",[Val]);
yecctoken2string({dot, _}) -> "'.'";
yecctoken2string({'$end', _}) ->
    [];
yecctoken2string({Other, _}) when is_atom(Other) ->
    io_lib:write(Other);
yecctoken2string(Other) ->
    io_lib:write(Other).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%



-file("src/graphql_parser.erl", 204).

yeccpars2(0=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_0(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(1=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_1(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(2=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_2(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(3=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_3(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(4=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_4(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(5=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_5(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(6=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_6(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(7=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_7(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(8=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_8(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(9=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_9(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(10=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_10(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(11=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_11(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(12=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_12(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(13=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_13(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(14=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_14(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(15=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_15(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(16=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_6(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(17=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_17(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(18=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_6(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(19=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_6(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(20=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_6(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(21=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_21(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(22=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_22(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(23=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_6(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(24=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_6(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(25=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_6(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(26=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_26(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(27=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_27(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(28=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_28(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(29=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_29(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(30=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_30(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(31=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_31(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(32=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_32(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(33=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_6(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(34=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_34(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(35=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_35(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(36=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_36(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(37=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_37(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(38=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_38(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(39=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_39(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(40=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_40(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(41=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_41(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(42=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_42(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(43=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_43(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(44=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_44(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(45=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_45(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(46=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_46(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(47=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_47(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(48=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_48(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(49=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_49(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(50=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_6(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(51=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_51(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(52=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_52(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(53=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_53(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(54=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_54(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(55=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_55(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(56=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_56(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(57=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_6(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(58=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_58(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(59=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_59(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(60=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_6(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(61=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_61(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(62=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_62(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(63=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_63(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(64=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_64(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(65=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_65(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(66=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_66(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(67=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_67(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(68=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_68(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(69=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_69(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(70=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_70(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(71=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_71(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(72=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_72(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(73=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_6(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(74=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_74(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(75=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_75(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(76=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_76(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(77=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_77(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(78=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_78(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(79=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_79(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(80=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_80(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(81=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_81(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(82=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_82(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(83=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_83(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(84=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_66(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(85=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_85(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(86=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_86(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(87=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_87(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(88=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_88(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(89=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_89(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(90=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_90(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(91=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_91(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(92=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_92(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(93=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_93(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(94=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_94(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(95=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_95(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(96=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_96(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(97=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_97(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(98=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_98(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(99=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_99(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(100=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_100(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(101=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_101(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(102=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_102(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(103=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_103(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(104=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_104(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(105=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_105(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(106=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_106(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(107=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_107(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(108=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_108(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(109=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_109(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(110=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_110(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(111=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_111(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(112=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_112(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(113=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_113(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(114=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_114(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(115=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_115(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(116=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_6(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(117=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_117(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(118=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_118(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(119=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_6(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(120=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_120(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(121=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_121(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(122=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_122(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(123=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_6(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(124=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_6(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(125=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_125(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(126=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_126(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(127=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_127(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(128=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_128(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(129=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_129(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(130=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_130(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(131=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_6(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(132=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_132(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(133=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_133(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(134=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_134(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(135=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_135(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(136=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_136(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(137=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_132(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(138=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_138(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(139=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_139(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(140=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_140(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(141=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_141(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(142=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_142(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(143=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_143(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(144=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_144(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(145=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_145(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(146=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_146(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(147=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_132(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(148=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_148(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(149=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_149(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(150=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_66(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(151=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_151(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(152=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_132(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(153=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_153(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(154=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_154(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(155=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_155(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(156=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_156(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(157=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_6(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(158=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_158(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(159=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_159(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(160=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_160(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(161=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_161(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(162=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_6(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(163=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_163(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(164=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_164(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(165=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_165(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(166=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_6(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(167=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_167(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(168=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_168(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(169=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_169(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(170=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_6(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(171=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_51(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(172=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_172(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(173=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_55(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(174=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_174(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(175=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_175(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(176=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_176(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(177=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_6(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(178=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_178(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(179=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_179(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(180=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_180(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(181=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_181(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(182=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_182(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(183=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_183(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(184=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_184(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(185=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_51(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(186=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_186(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(187=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_55(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(188=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_188(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(189=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_189(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(190=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_190(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(191=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_191(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(192=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_132(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(193=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_193(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(194=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_194(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(195=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_195(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(196=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_196(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(197=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_197(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(198=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_198(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(199=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_55(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(200=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_200(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(Other, _, _, _, _, _, _) ->
 erlang:error({yecc_bug,"1.4",{missing_state_in_action_table, Other}}).

yeccpars2_0(S, enum, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 16, Ss, Stack, T, Ts, Tzr);
yeccpars2_0(S, extend, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 17, Ss, Stack, T, Ts, Tzr);
yeccpars2_0(S, fragment, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 18, Ss, Stack, T, Ts, Tzr);
yeccpars2_0(S, input, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 19, Ss, Stack, T, Ts, Tzr);
yeccpars2_0(S, interface, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 20, Ss, Stack, T, Ts, Tzr);
yeccpars2_0(S, mutation, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 21, Ss, Stack, T, Ts, Tzr);
yeccpars2_0(S, query, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 22, Ss, Stack, T, Ts, Tzr);
yeccpars2_0(S, scalar, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 23, Ss, Stack, T, Ts, Tzr);
yeccpars2_0(S, type, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 24, Ss, Stack, T, Ts, Tzr);
yeccpars2_0(S, union, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 25, Ss, Stack, T, Ts, Tzr);
yeccpars2_0(S, '{', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 26, Ss, Stack, T, Ts, Tzr);
yeccpars2_0(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_1(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 'yeccgoto_\'TypeDefinition\''(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_2(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 'yeccgoto_\'TypeDefinition\''(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_3(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 'yeccgoto_\'Definition\''(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_4(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_4_(Stack),
 'yeccgoto_\'OperationDefinition\''(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_5(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 'yeccgoto_\'TypeDefinition\''(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_6(S, enum, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 35, Ss, Stack, T, Ts, Tzr);
yeccpars2_6(S, extend, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 36, Ss, Stack, T, Ts, Tzr);
yeccpars2_6(S, fragment, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 37, Ss, Stack, T, Ts, Tzr);
yeccpars2_6(S, implements, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 38, Ss, Stack, T, Ts, Tzr);
yeccpars2_6(S, input, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 39, Ss, Stack, T, Ts, Tzr);
yeccpars2_6(S, interface, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 40, Ss, Stack, T, Ts, Tzr);
yeccpars2_6(S, mutation, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 41, Ss, Stack, T, Ts, Tzr);
yeccpars2_6(S, name, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 42, Ss, Stack, T, Ts, Tzr);
yeccpars2_6(S, null, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 43, Ss, Stack, T, Ts, Tzr);
yeccpars2_6(S, query, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 44, Ss, Stack, T, Ts, Tzr);
yeccpars2_6(S, scalar, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 45, Ss, Stack, T, Ts, Tzr);
yeccpars2_6(S, type, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 46, Ss, Stack, T, Ts, Tzr);
yeccpars2_6(S, union, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 47, Ss, Stack, T, Ts, Tzr);
yeccpars2_6(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 'yeccgoto_\'Definition\''(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_8(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 'yeccgoto_\'TypeDefinition\''(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_9(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 'yeccgoto_\'TypeDefinition\''(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_10(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 'yeccgoto_\'TypeDefinition\''(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_11(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 'yeccgoto_\'Definition\''(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_12(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 'yeccgoto_\'TypeDefinition\''(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_13(_S, '$end', _Ss, Stack, _T, _Ts, _Tzr) ->
 {ok, hd(Stack)};
yeccpars2_13(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_14(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_14_(Stack),
 'yeccgoto_\'Document\''(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_15(S, enum, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 16, Ss, Stack, T, Ts, Tzr);
yeccpars2_15(S, extend, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 17, Ss, Stack, T, Ts, Tzr);
yeccpars2_15(S, fragment, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 18, Ss, Stack, T, Ts, Tzr);
yeccpars2_15(S, input, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 19, Ss, Stack, T, Ts, Tzr);
yeccpars2_15(S, interface, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 20, Ss, Stack, T, Ts, Tzr);
yeccpars2_15(S, mutation, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 21, Ss, Stack, T, Ts, Tzr);
yeccpars2_15(S, query, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 22, Ss, Stack, T, Ts, Tzr);
yeccpars2_15(S, scalar, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 23, Ss, Stack, T, Ts, Tzr);
yeccpars2_15(S, type, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 24, Ss, Stack, T, Ts, Tzr);
yeccpars2_15(S, union, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 25, Ss, Stack, T, Ts, Tzr);
yeccpars2_15(S, '{', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 26, Ss, Stack, T, Ts, Tzr);
yeccpars2_15(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_15_(Stack),
 'yeccgoto_\'Definitions\''(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

%% yeccpars2_16: see yeccpars2_6

yeccpars2_17(S, type, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 24, Ss, Stack, T, Ts, Tzr);
yeccpars2_17(_, _, _, _, T, _, _) ->
 yeccerror(T).

%% yeccpars2_18: see yeccpars2_6

%% yeccpars2_19: see yeccpars2_6

%% yeccpars2_20: see yeccpars2_6

yeccpars2_21(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_21_(Stack),
 'yeccgoto_\'OperationType\''(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_22(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_22_(Stack),
 'yeccgoto_\'OperationType\''(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

%% yeccpars2_23: see yeccpars2_6

%% yeccpars2_24: see yeccpars2_6

%% yeccpars2_25: see yeccpars2_6

yeccpars2_26(S, '...', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 34, Ss, Stack, T, Ts, Tzr);
yeccpars2_26(S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_6(S, Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_27(S, '}', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 114, Ss, Stack, T, Ts, Tzr);
yeccpars2_27(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_28(S, '...', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 34, Ss, Stack, T, Ts, Tzr);
yeccpars2_28(S, enum, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 35, Ss, Stack, T, Ts, Tzr);
yeccpars2_28(S, extend, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 36, Ss, Stack, T, Ts, Tzr);
yeccpars2_28(S, fragment, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 37, Ss, Stack, T, Ts, Tzr);
yeccpars2_28(S, implements, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 38, Ss, Stack, T, Ts, Tzr);
yeccpars2_28(S, input, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 39, Ss, Stack, T, Ts, Tzr);
yeccpars2_28(S, interface, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 40, Ss, Stack, T, Ts, Tzr);
yeccpars2_28(S, mutation, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 41, Ss, Stack, T, Ts, Tzr);
yeccpars2_28(S, name, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 42, Ss, Stack, T, Ts, Tzr);
yeccpars2_28(S, null, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 43, Ss, Stack, T, Ts, Tzr);
yeccpars2_28(S, query, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 44, Ss, Stack, T, Ts, Tzr);
yeccpars2_28(S, scalar, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 45, Ss, Stack, T, Ts, Tzr);
yeccpars2_28(S, type, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 46, Ss, Stack, T, Ts, Tzr);
yeccpars2_28(S, union, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 47, Ss, Stack, T, Ts, Tzr);
yeccpars2_28(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_28_(Stack),
 'yeccgoto_\'Selections\''(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_29(S, '(', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 60, Ss, Stack, T, Ts, Tzr);
yeccpars2_29(S, ':', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 108, Ss, Stack, T, Ts, Tzr);
yeccpars2_29(S, '@', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 57, Ss, Stack, T, Ts, Tzr);
yeccpars2_29(S, '{', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 26, Ss, Stack, T, Ts, Tzr);
yeccpars2_29(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_29_(Stack),
 'yeccgoto_\'Field\''(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_30(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 'yeccgoto_\'Selection\''(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_31(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 'yeccgoto_\'Selection\''(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_32(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 'yeccgoto_\'Selection\''(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

%% yeccpars2_33: see yeccpars2_6

yeccpars2_34(S, on, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 50, Ss, Stack, T, Ts, Tzr);
yeccpars2_34(S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_6(S, Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_35(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_35_(Stack),
 'yeccgoto_\'Name\''(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_36(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_36_(Stack),
 'yeccgoto_\'Name\''(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_37(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_37_(Stack),
 'yeccgoto_\'Name\''(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_38(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_38_(Stack),
 'yeccgoto_\'Name\''(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_39(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_39_(Stack),
 'yeccgoto_\'Name\''(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_40(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_40_(Stack),
 'yeccgoto_\'Name\''(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_41(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_41_(Stack),
 'yeccgoto_\'Name\''(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_42(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_42_(Stack),
 'yeccgoto_\'Name\''(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_43(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_43_(Stack),
 'yeccgoto_\'Name\''(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_44(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_44_(Stack),
 'yeccgoto_\'Name\''(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_45(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_45_(Stack),
 'yeccgoto_\'Name\''(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_46(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_46_(Stack),
 'yeccgoto_\'Name\''(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_47(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_47_(Stack),
 'yeccgoto_\'Name\''(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_48(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 'yeccgoto_\'FragmentName\''(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_49(S, '@', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 57, Ss, Stack, T, Ts, Tzr);
yeccpars2_49(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_|Nss] = Ss,
 NewStack = yeccpars2_49_(Stack),
 'yeccgoto_\'FragmentSpread\''(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

%% yeccpars2_50: see yeccpars2_6

yeccpars2_51(S, '@', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 57, Ss, Stack, T, Ts, Tzr);
yeccpars2_51(S, '{', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 26, Ss, Stack, T, Ts, Tzr);
yeccpars2_51(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_52(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 'yeccgoto_\'TypeCondition\''(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_53(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_53_(Stack),
 'yeccgoto_\'NamedType\''(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_54(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_|Nss] = Ss,
 NewStack = yeccpars2_54_(Stack),
 'yeccgoto_\'InlineFragment\''(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_55(S, '{', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 26, Ss, Stack, T, Ts, Tzr);
yeccpars2_55(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_56(S, '@', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 57, Ss, Stack, T, Ts, Tzr);
yeccpars2_56(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_56_(Stack),
 'yeccgoto_\'Directives\''(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

%% yeccpars2_57: see yeccpars2_6

yeccpars2_58(S, '(', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 60, Ss, Stack, T, Ts, Tzr);
yeccpars2_58(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_|Nss] = Ss,
 NewStack = yeccpars2_58_(Stack),
 'yeccgoto_\'Directive\''(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_59(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_59_(Stack),
 'yeccgoto_\'Directive\''(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

%% yeccpars2_60: see yeccpars2_6

yeccpars2_61(S, ':', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 66, Ss, Stack, T, Ts, Tzr);
yeccpars2_61(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_62(S, ')', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 65, Ss, Stack, T, Ts, Tzr);
yeccpars2_62(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_63(S, enum, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 35, Ss, Stack, T, Ts, Tzr);
yeccpars2_63(S, extend, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 36, Ss, Stack, T, Ts, Tzr);
yeccpars2_63(S, fragment, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 37, Ss, Stack, T, Ts, Tzr);
yeccpars2_63(S, implements, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 38, Ss, Stack, T, Ts, Tzr);
yeccpars2_63(S, input, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 39, Ss, Stack, T, Ts, Tzr);
yeccpars2_63(S, interface, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 40, Ss, Stack, T, Ts, Tzr);
yeccpars2_63(S, mutation, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 41, Ss, Stack, T, Ts, Tzr);
yeccpars2_63(S, name, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 42, Ss, Stack, T, Ts, Tzr);
yeccpars2_63(S, null, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 43, Ss, Stack, T, Ts, Tzr);
yeccpars2_63(S, query, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 44, Ss, Stack, T, Ts, Tzr);
yeccpars2_63(S, scalar, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 45, Ss, Stack, T, Ts, Tzr);
yeccpars2_63(S, type, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 46, Ss, Stack, T, Ts, Tzr);
yeccpars2_63(S, union, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 47, Ss, Stack, T, Ts, Tzr);
yeccpars2_63(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_63_(Stack),
 'yeccgoto_\'ArgumentList\''(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_64(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_|Nss] = Ss,
 NewStack = yeccpars2_64_(Stack),
 'yeccgoto_\'ArgumentList\''(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_65(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_65_(Stack),
 'yeccgoto_\'Arguments\''(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_66(S, '$', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 73, Ss, Stack, T, Ts, Tzr);
yeccpars2_66(S, '[', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 74, Ss, Stack, T, Ts, Tzr);
yeccpars2_66(S, boolean_value, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 75, Ss, Stack, T, Ts, Tzr);
yeccpars2_66(S, float_value, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 76, Ss, Stack, T, Ts, Tzr);
yeccpars2_66(S, int_value, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 77, Ss, Stack, T, Ts, Tzr);
yeccpars2_66(S, string_value, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 78, Ss, Stack, T, Ts, Tzr);
yeccpars2_66(S, '{', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 79, Ss, Stack, T, Ts, Tzr);
yeccpars2_66(S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_6(S, Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_67(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 'yeccgoto_\'Value\''(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_68(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_68_(Stack),
 'yeccgoto_\'Argument\''(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_69(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_69_(Stack),
 'yeccgoto_\'Value\''(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_70(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 'yeccgoto_\'EnumValue\''(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_71(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_71_(Stack),
 'yeccgoto_\'Value\''(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_72(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_72_(Stack),
 'yeccgoto_\'Value\''(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

%% yeccpars2_73: see yeccpars2_6

yeccpars2_74(S, '$', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 73, Ss, Stack, T, Ts, Tzr);
yeccpars2_74(S, '[', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 74, Ss, Stack, T, Ts, Tzr);
yeccpars2_74(S, ']', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 90, Ss, Stack, T, Ts, Tzr);
yeccpars2_74(S, boolean_value, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 75, Ss, Stack, T, Ts, Tzr);
yeccpars2_74(S, float_value, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 76, Ss, Stack, T, Ts, Tzr);
yeccpars2_74(S, int_value, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 77, Ss, Stack, T, Ts, Tzr);
yeccpars2_74(S, string_value, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 78, Ss, Stack, T, Ts, Tzr);
yeccpars2_74(S, '{', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 79, Ss, Stack, T, Ts, Tzr);
yeccpars2_74(S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_6(S, Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_75(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_75_(Stack),
 'yeccgoto_\'Value\''(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_76(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_76_(Stack),
 'yeccgoto_\'Value\''(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_77(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_77_(Stack),
 'yeccgoto_\'Value\''(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_78(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_78_(Stack),
 'yeccgoto_\'Value\''(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_79(S, '}', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 83, Ss, Stack, T, Ts, Tzr);
yeccpars2_79(S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_6(S, Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_80(S, '}', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 87, Ss, Stack, T, Ts, Tzr);
yeccpars2_80(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_81(S, enum, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 35, Ss, Stack, T, Ts, Tzr);
yeccpars2_81(S, extend, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 36, Ss, Stack, T, Ts, Tzr);
yeccpars2_81(S, fragment, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 37, Ss, Stack, T, Ts, Tzr);
yeccpars2_81(S, implements, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 38, Ss, Stack, T, Ts, Tzr);
yeccpars2_81(S, input, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 39, Ss, Stack, T, Ts, Tzr);
yeccpars2_81(S, interface, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 40, Ss, Stack, T, Ts, Tzr);
yeccpars2_81(S, mutation, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 41, Ss, Stack, T, Ts, Tzr);
yeccpars2_81(S, name, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 42, Ss, Stack, T, Ts, Tzr);
yeccpars2_81(S, null, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 43, Ss, Stack, T, Ts, Tzr);
yeccpars2_81(S, query, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 44, Ss, Stack, T, Ts, Tzr);
yeccpars2_81(S, scalar, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 45, Ss, Stack, T, Ts, Tzr);
yeccpars2_81(S, type, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 46, Ss, Stack, T, Ts, Tzr);
yeccpars2_81(S, union, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 47, Ss, Stack, T, Ts, Tzr);
yeccpars2_81(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_81_(Stack),
 'yeccgoto_\'ObjectFields\''(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_82(S, ':', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 84, Ss, Stack, T, Ts, Tzr);
yeccpars2_82(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_83(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_|Nss] = Ss,
 NewStack = yeccpars2_83_(Stack),
 'yeccgoto_\'ObjectValue\''(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

%% yeccpars2_84: see yeccpars2_66

yeccpars2_85(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_85_(Stack),
 'yeccgoto_\'ObjectField\''(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_86(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_|Nss] = Ss,
 NewStack = yeccpars2_86_(Stack),
 'yeccgoto_\'ObjectFields\''(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_87(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_87_(Stack),
 'yeccgoto_\'ObjectValue\''(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_88(S, ']', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 92, Ss, Stack, T, Ts, Tzr);
yeccpars2_88(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_89(S, '$', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 73, Ss, Stack, T, Ts, Tzr);
yeccpars2_89(S, '[', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 74, Ss, Stack, T, Ts, Tzr);
yeccpars2_89(S, boolean_value, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 75, Ss, Stack, T, Ts, Tzr);
yeccpars2_89(S, enum, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 35, Ss, Stack, T, Ts, Tzr);
yeccpars2_89(S, extend, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 36, Ss, Stack, T, Ts, Tzr);
yeccpars2_89(S, float_value, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 76, Ss, Stack, T, Ts, Tzr);
yeccpars2_89(S, fragment, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 37, Ss, Stack, T, Ts, Tzr);
yeccpars2_89(S, implements, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 38, Ss, Stack, T, Ts, Tzr);
yeccpars2_89(S, input, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 39, Ss, Stack, T, Ts, Tzr);
yeccpars2_89(S, int_value, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 77, Ss, Stack, T, Ts, Tzr);
yeccpars2_89(S, interface, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 40, Ss, Stack, T, Ts, Tzr);
yeccpars2_89(S, mutation, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 41, Ss, Stack, T, Ts, Tzr);
yeccpars2_89(S, name, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 42, Ss, Stack, T, Ts, Tzr);
yeccpars2_89(S, null, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 43, Ss, Stack, T, Ts, Tzr);
yeccpars2_89(S, query, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 44, Ss, Stack, T, Ts, Tzr);
yeccpars2_89(S, scalar, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 45, Ss, Stack, T, Ts, Tzr);
yeccpars2_89(S, string_value, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 78, Ss, Stack, T, Ts, Tzr);
yeccpars2_89(S, type, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 46, Ss, Stack, T, Ts, Tzr);
yeccpars2_89(S, union, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 47, Ss, Stack, T, Ts, Tzr);
yeccpars2_89(S, '{', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 79, Ss, Stack, T, Ts, Tzr);
yeccpars2_89(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_89_(Stack),
 'yeccgoto_\'Values\''(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_90(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_|Nss] = Ss,
 NewStack = yeccpars2_90_(Stack),
 'yeccgoto_\'ListValue\''(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_91(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_|Nss] = Ss,
 NewStack = yeccpars2_91_(Stack),
 'yeccgoto_\'Values\''(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_92(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_92_(Stack),
 'yeccgoto_\'ListValue\''(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_93(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_|Nss] = Ss,
 NewStack = yeccpars2_93_(Stack),
 'yeccgoto_\'Variable\''(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_94(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_|Nss] = Ss,
 NewStack = yeccpars2_94_(Stack),
 'yeccgoto_\'Directives\''(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_95(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_,_|Nss] = Ss,
 NewStack = yeccpars2_95_(Stack),
 'yeccgoto_\'InlineFragment\''(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_96(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_96_(Stack),
 'yeccgoto_\'FragmentSpread\''(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_97(S, '(', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 60, Ss, Stack, T, Ts, Tzr);
yeccpars2_97(S, '@', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 57, Ss, Stack, T, Ts, Tzr);
yeccpars2_97(S, '{', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 26, Ss, Stack, T, Ts, Tzr);
yeccpars2_97(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_|Nss] = Ss,
 NewStack = yeccpars2_97_(Stack),
 'yeccgoto_\'Field\''(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_98(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_98_(Stack),
 'yeccgoto_\'Field\''(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_99(S, '{', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 26, Ss, Stack, T, Ts, Tzr);
yeccpars2_99(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_99_(Stack),
 'yeccgoto_\'Field\''(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_100(S, '@', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 57, Ss, Stack, T, Ts, Tzr);
yeccpars2_100(S, '{', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 26, Ss, Stack, T, Ts, Tzr);
yeccpars2_100(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_100_(Stack),
 'yeccgoto_\'Field\''(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_101(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_|Nss] = Ss,
 NewStack = yeccpars2_101_(Stack),
 'yeccgoto_\'Field\''(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_102(S, '{', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 26, Ss, Stack, T, Ts, Tzr);
yeccpars2_102(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_|Nss] = Ss,
 NewStack = yeccpars2_102_(Stack),
 'yeccgoto_\'Field\''(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_103(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_,_|Nss] = Ss,
 NewStack = yeccpars2_103_(Stack),
 'yeccgoto_\'Field\''(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_104(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_|Nss] = Ss,
 NewStack = yeccpars2_104_(Stack),
 'yeccgoto_\'Field\''(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_105(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_|Nss] = Ss,
 NewStack = yeccpars2_105_(Stack),
 'yeccgoto_\'Field\''(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_106(S, '{', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 26, Ss, Stack, T, Ts, Tzr);
yeccpars2_106(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_|Nss] = Ss,
 NewStack = yeccpars2_106_(Stack),
 'yeccgoto_\'Field\''(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_107(S, '@', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 57, Ss, Stack, T, Ts, Tzr);
yeccpars2_107(S, '{', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 26, Ss, Stack, T, Ts, Tzr);
yeccpars2_107(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_|Nss] = Ss,
 NewStack = yeccpars2_107_(Stack),
 'yeccgoto_\'Field\''(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_108(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_|Nss] = Ss,
 NewStack = yeccpars2_108_(Stack),
 'yeccgoto_\'Alias\''(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_109(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_109_(Stack),
 'yeccgoto_\'Field\''(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_110(S, '{', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 26, Ss, Stack, T, Ts, Tzr);
yeccpars2_110(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_110_(Stack),
 'yeccgoto_\'Field\''(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_111(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_|Nss] = Ss,
 NewStack = yeccpars2_111_(Stack),
 'yeccgoto_\'Field\''(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_112(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_112_(Stack),
 'yeccgoto_\'Field\''(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_113(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_|Nss] = Ss,
 NewStack = yeccpars2_113_(Stack),
 'yeccgoto_\'Selections\''(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_114(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_114_(Stack),
 'yeccgoto_\'SelectionSet\''(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_115(S, '=', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 116, Ss, Stack, T, Ts, Tzr);
yeccpars2_115(_, _, _, _, T, _, _) ->
 yeccerror(T).

%% yeccpars2_116: see yeccpars2_6

yeccpars2_117(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_|Nss] = Ss,
 NewStack = yeccpars2_117_(Stack),
 'yeccgoto_\'UnionTypeDefinition\''(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_118(S, '|', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 119, Ss, Stack, T, Ts, Tzr);
yeccpars2_118(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_118_(Stack),
 'yeccgoto_\'UnionMembers\''(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

%% yeccpars2_119: see yeccpars2_6

yeccpars2_120(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_120_(Stack),
 'yeccgoto_\'UnionMembers\''(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_121(S, implements, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 123, Ss, Stack, T, Ts, Tzr);
yeccpars2_121(S, '{', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 124, Ss, Stack, T, Ts, Tzr);
yeccpars2_121(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_122(S, '{', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 157, Ss, Stack, T, Ts, Tzr);
yeccpars2_122(_, _, _, _, T, _, _) ->
 yeccerror(T).

%% yeccpars2_123: see yeccpars2_6

%% yeccpars2_124: see yeccpars2_6

yeccpars2_125(S, '(', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 131, Ss, Stack, T, Ts, Tzr);
yeccpars2_125(S, ':', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 132, Ss, Stack, T, Ts, Tzr);
yeccpars2_125(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_126(S, '}', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 129, Ss, Stack, T, Ts, Tzr);
yeccpars2_126(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_127(S, enum, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 35, Ss, Stack, T, Ts, Tzr);
yeccpars2_127(S, extend, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 36, Ss, Stack, T, Ts, Tzr);
yeccpars2_127(S, fragment, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 37, Ss, Stack, T, Ts, Tzr);
yeccpars2_127(S, implements, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 38, Ss, Stack, T, Ts, Tzr);
yeccpars2_127(S, input, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 39, Ss, Stack, T, Ts, Tzr);
yeccpars2_127(S, interface, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 40, Ss, Stack, T, Ts, Tzr);
yeccpars2_127(S, mutation, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 41, Ss, Stack, T, Ts, Tzr);
yeccpars2_127(S, name, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 42, Ss, Stack, T, Ts, Tzr);
yeccpars2_127(S, null, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 43, Ss, Stack, T, Ts, Tzr);
yeccpars2_127(S, query, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 44, Ss, Stack, T, Ts, Tzr);
yeccpars2_127(S, scalar, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 45, Ss, Stack, T, Ts, Tzr);
yeccpars2_127(S, type, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 46, Ss, Stack, T, Ts, Tzr);
yeccpars2_127(S, union, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 47, Ss, Stack, T, Ts, Tzr);
yeccpars2_127(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_127_(Stack),
 'yeccgoto_\'FieldDefinitionList\''(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_128(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_|Nss] = Ss,
 NewStack = yeccpars2_128_(Stack),
 'yeccgoto_\'FieldDefinitionList\''(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_129(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_,_|Nss] = Ss,
 NewStack = yeccpars2_129_(Stack),
 'yeccgoto_\'ObjectTypeDefinition\''(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_130(S, ':', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 152, Ss, Stack, T, Ts, Tzr);
yeccpars2_130(_, _, _, _, T, _, _) ->
 yeccerror(T).

%% yeccpars2_131: see yeccpars2_6

yeccpars2_132(S, '[', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 137, Ss, Stack, T, Ts, Tzr);
yeccpars2_132(S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_6(S, Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_133(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_133_(Stack),
 'yeccgoto_\'FieldDefinition\''(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_134(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 'yeccgoto_\'Type\''(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_135(S, '!', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 141, Ss, Stack, T, Ts, Tzr);
yeccpars2_135(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 'yeccgoto_\'Type\''(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_136(S, '!', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 140, Ss, Stack, T, Ts, Tzr);
yeccpars2_136(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 'yeccgoto_\'Type\''(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

%% yeccpars2_137: see yeccpars2_132

yeccpars2_138(S, ']', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 139, Ss, Stack, T, Ts, Tzr);
yeccpars2_138(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_139(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_139_(Stack),
 'yeccgoto_\'ListType\''(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_140(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_|Nss] = Ss,
 NewStack = yeccpars2_140_(Stack),
 'yeccgoto_\'NonNullType\''(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_141(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_|Nss] = Ss,
 NewStack = yeccpars2_141_(Stack),
 'yeccgoto_\'NonNullType\''(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_142(S, ':', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 147, Ss, Stack, T, Ts, Tzr);
yeccpars2_142(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_143(S, ')', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 146, Ss, Stack, T, Ts, Tzr);
yeccpars2_143(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_144(S, enum, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 35, Ss, Stack, T, Ts, Tzr);
yeccpars2_144(S, extend, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 36, Ss, Stack, T, Ts, Tzr);
yeccpars2_144(S, fragment, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 37, Ss, Stack, T, Ts, Tzr);
yeccpars2_144(S, implements, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 38, Ss, Stack, T, Ts, Tzr);
yeccpars2_144(S, input, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 39, Ss, Stack, T, Ts, Tzr);
yeccpars2_144(S, interface, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 40, Ss, Stack, T, Ts, Tzr);
yeccpars2_144(S, mutation, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 41, Ss, Stack, T, Ts, Tzr);
yeccpars2_144(S, name, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 42, Ss, Stack, T, Ts, Tzr);
yeccpars2_144(S, null, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 43, Ss, Stack, T, Ts, Tzr);
yeccpars2_144(S, query, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 44, Ss, Stack, T, Ts, Tzr);
yeccpars2_144(S, scalar, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 45, Ss, Stack, T, Ts, Tzr);
yeccpars2_144(S, type, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 46, Ss, Stack, T, Ts, Tzr);
yeccpars2_144(S, union, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 47, Ss, Stack, T, Ts, Tzr);
yeccpars2_144(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_144_(Stack),
 'yeccgoto_\'InputValueDefinitionList\''(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_145(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_|Nss] = Ss,
 NewStack = yeccpars2_145_(Stack),
 'yeccgoto_\'InputValueDefinitionList\''(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_146(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_146_(Stack),
 'yeccgoto_\'ArgumentsDefinition\''(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

%% yeccpars2_147: see yeccpars2_132

yeccpars2_148(S, '=', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 150, Ss, Stack, T, Ts, Tzr);
yeccpars2_148(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_148_(Stack),
 'yeccgoto_\'InputValueDefinition\''(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_149(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_|Nss] = Ss,
 NewStack = yeccpars2_149_(Stack),
 'yeccgoto_\'InputValueDefinition\''(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

%% yeccpars2_150: see yeccpars2_66

yeccpars2_151(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_|Nss] = Ss,
 NewStack = yeccpars2_151_(Stack),
 'yeccgoto_\'DefaultValue\''(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

%% yeccpars2_152: see yeccpars2_132

yeccpars2_153(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_|Nss] = Ss,
 NewStack = yeccpars2_153_(Stack),
 'yeccgoto_\'FieldDefinition\''(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_154(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_|Nss] = Ss,
 NewStack = yeccpars2_154_(Stack),
 'yeccgoto_\'ImplementsInterfaces\''(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_155(S, enum, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 35, Ss, Stack, T, Ts, Tzr);
yeccpars2_155(S, extend, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 36, Ss, Stack, T, Ts, Tzr);
yeccpars2_155(S, fragment, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 37, Ss, Stack, T, Ts, Tzr);
yeccpars2_155(S, implements, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 38, Ss, Stack, T, Ts, Tzr);
yeccpars2_155(S, input, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 39, Ss, Stack, T, Ts, Tzr);
yeccpars2_155(S, interface, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 40, Ss, Stack, T, Ts, Tzr);
yeccpars2_155(S, mutation, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 41, Ss, Stack, T, Ts, Tzr);
yeccpars2_155(S, name, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 42, Ss, Stack, T, Ts, Tzr);
yeccpars2_155(S, null, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 43, Ss, Stack, T, Ts, Tzr);
yeccpars2_155(S, query, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 44, Ss, Stack, T, Ts, Tzr);
yeccpars2_155(S, scalar, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 45, Ss, Stack, T, Ts, Tzr);
yeccpars2_155(S, type, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 46, Ss, Stack, T, Ts, Tzr);
yeccpars2_155(S, union, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 47, Ss, Stack, T, Ts, Tzr);
yeccpars2_155(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_155_(Stack),
 'yeccgoto_\'NamedTypeList\''(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_156(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_|Nss] = Ss,
 NewStack = yeccpars2_156_(Stack),
 'yeccgoto_\'NamedTypeList\''(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

%% yeccpars2_157: see yeccpars2_6

yeccpars2_158(S, '}', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 159, Ss, Stack, T, Ts, Tzr);
yeccpars2_158(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_159(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_,_,_|Nss] = Ss,
 NewStack = yeccpars2_159_(Stack),
 'yeccgoto_\'ObjectTypeDefinition\''(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_160(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_|Nss] = Ss,
 NewStack = yeccpars2_160_(Stack),
 'yeccgoto_\'ScalarTypeDefinition\''(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_161(S, '{', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 162, Ss, Stack, T, Ts, Tzr);
yeccpars2_161(_, _, _, _, T, _, _) ->
 yeccerror(T).

%% yeccpars2_162: see yeccpars2_6

yeccpars2_163(S, '}', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 164, Ss, Stack, T, Ts, Tzr);
yeccpars2_163(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_164(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_,_|Nss] = Ss,
 NewStack = yeccpars2_164_(Stack),
 'yeccgoto_\'InterfaceTypeDefinition\''(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_165(S, '{', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 166, Ss, Stack, T, Ts, Tzr);
yeccpars2_165(_, _, _, _, T, _, _) ->
 yeccerror(T).

%% yeccpars2_166: see yeccpars2_6

yeccpars2_167(S, '}', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 168, Ss, Stack, T, Ts, Tzr);
yeccpars2_167(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_168(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_,_|Nss] = Ss,
 NewStack = yeccpars2_168_(Stack),
 'yeccgoto_\'InputObjectTypeDefinition\''(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_169(S, on, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 170, Ss, Stack, T, Ts, Tzr);
yeccpars2_169(_, _, _, _, T, _, _) ->
 yeccerror(T).

%% yeccpars2_170: see yeccpars2_6

%% yeccpars2_171: see yeccpars2_51

yeccpars2_172(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_,_|Nss] = Ss,
 NewStack = yeccpars2_172_(Stack),
 'yeccgoto_\'FragmentDefinition\''(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

%% yeccpars2_173: see yeccpars2_55

yeccpars2_174(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_,_,_|Nss] = Ss,
 NewStack = yeccpars2_174_(Stack),
 'yeccgoto_\'FragmentDefinition\''(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_175(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_|Nss] = Ss,
 NewStack = yeccpars2_175_(Stack),
 'yeccgoto_\'TypeExtensionDefinition\''(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_176(S, '{', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 177, Ss, Stack, T, Ts, Tzr);
yeccpars2_176(_, _, _, _, T, _, _) ->
 yeccerror(T).

%% yeccpars2_177: see yeccpars2_6

yeccpars2_178(S, '}', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 182, Ss, Stack, T, Ts, Tzr);
yeccpars2_178(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_179(S, enum, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 35, Ss, Stack, T, Ts, Tzr);
yeccpars2_179(S, extend, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 36, Ss, Stack, T, Ts, Tzr);
yeccpars2_179(S, fragment, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 37, Ss, Stack, T, Ts, Tzr);
yeccpars2_179(S, implements, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 38, Ss, Stack, T, Ts, Tzr);
yeccpars2_179(S, input, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 39, Ss, Stack, T, Ts, Tzr);
yeccpars2_179(S, interface, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 40, Ss, Stack, T, Ts, Tzr);
yeccpars2_179(S, mutation, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 41, Ss, Stack, T, Ts, Tzr);
yeccpars2_179(S, name, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 42, Ss, Stack, T, Ts, Tzr);
yeccpars2_179(S, null, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 43, Ss, Stack, T, Ts, Tzr);
yeccpars2_179(S, query, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 44, Ss, Stack, T, Ts, Tzr);
yeccpars2_179(S, scalar, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 45, Ss, Stack, T, Ts, Tzr);
yeccpars2_179(S, type, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 46, Ss, Stack, T, Ts, Tzr);
yeccpars2_179(S, union, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 47, Ss, Stack, T, Ts, Tzr);
yeccpars2_179(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_179_(Stack),
 'yeccgoto_\'EnumValueDefinitionList\''(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_180(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 'yeccgoto_\'EnumValueDefinition\''(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_181(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_|Nss] = Ss,
 NewStack = yeccpars2_181_(Stack),
 'yeccgoto_\'EnumValueDefinitionList\''(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_182(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_,_|Nss] = Ss,
 NewStack = yeccpars2_182_(Stack),
 'yeccgoto_\'EnumTypeDefinition\''(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_183(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_|Nss] = Ss,
 NewStack = yeccpars2_183_(Stack),
 'yeccgoto_\'Definitions\''(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_184(S, '(', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 188, Ss, Stack, T, Ts, Tzr);
yeccpars2_184(S, '@', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 57, Ss, Stack, T, Ts, Tzr);
yeccpars2_184(S, '{', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 26, Ss, Stack, T, Ts, Tzr);
yeccpars2_184(_, _, _, _, T, _, _) ->
 yeccerror(T).

%% yeccpars2_185: see yeccpars2_51

yeccpars2_186(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_186_(Stack),
 'yeccgoto_\'OperationDefinition\''(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

%% yeccpars2_187: see yeccpars2_55

yeccpars2_188(S, '$', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 73, Ss, Stack, T, Ts, Tzr);
yeccpars2_188(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_189(S, ')', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 196, Ss, Stack, T, Ts, Tzr);
yeccpars2_189(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_190(S, '$', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 73, Ss, Stack, T, Ts, Tzr);
yeccpars2_190(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_190_(Stack),
 'yeccgoto_\'VariableDefinitionList\''(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_191(S, ':', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 192, Ss, Stack, T, Ts, Tzr);
yeccpars2_191(_, _, _, _, T, _, _) ->
 yeccerror(T).

%% yeccpars2_192: see yeccpars2_132

yeccpars2_193(S, '=', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 150, Ss, Stack, T, Ts, Tzr);
yeccpars2_193(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_193_(Stack),
 'yeccgoto_\'VariableDefinition\''(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_194(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_|Nss] = Ss,
 NewStack = yeccpars2_194_(Stack),
 'yeccgoto_\'VariableDefinition\''(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_195(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_|Nss] = Ss,
 NewStack = yeccpars2_195_(Stack),
 'yeccgoto_\'VariableDefinitionList\''(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_196(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_196_(Stack),
 'yeccgoto_\'VariableDefinitions\''(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_197(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_|Nss] = Ss,
 NewStack = yeccpars2_197_(Stack),
 'yeccgoto_\'OperationDefinition\''(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_198(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_|Nss] = Ss,
 NewStack = yeccpars2_198_(Stack),
 'yeccgoto_\'OperationDefinition\''(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

%% yeccpars2_199: see yeccpars2_55

yeccpars2_200(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_,_|Nss] = Ss,
 NewStack = yeccpars2_200_(Stack),
 'yeccgoto_\'OperationDefinition\''(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

'yeccgoto_\'Alias\''(26, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_6(33, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'Alias\''(28, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_6(33, Cat, Ss, Stack, T, Ts, Tzr).

'yeccgoto_\'Argument\''(60, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_63(63, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'Argument\''(63, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_63(63, Cat, Ss, Stack, T, Ts, Tzr).

'yeccgoto_\'ArgumentList\''(60, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_62(62, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'ArgumentList\''(63=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_64(_S, Cat, Ss, Stack, T, Ts, Tzr).

'yeccgoto_\'Arguments\''(29, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_107(107, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'Arguments\''(58=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_59(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'Arguments\''(97, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_100(100, Cat, Ss, Stack, T, Ts, Tzr).

'yeccgoto_\'ArgumentsDefinition\''(125, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_130(130, Cat, Ss, Stack, T, Ts, Tzr).

'yeccgoto_\'DefaultValue\''(148=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_149(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'DefaultValue\''(193=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_194(_S, Cat, Ss, Stack, T, Ts, Tzr).

'yeccgoto_\'Definition\''(0, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_15(15, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'Definition\''(15, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_15(15, Cat, Ss, Stack, T, Ts, Tzr).

'yeccgoto_\'Definitions\''(0=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_14(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'Definitions\''(15=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_183(_S, Cat, Ss, Stack, T, Ts, Tzr).

'yeccgoto_\'Directive\''(29, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_56(56, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'Directive\''(49, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_56(56, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'Directive\''(51, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_56(56, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'Directive\''(56, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_56(56, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'Directive\''(97, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_56(56, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'Directive\''(100, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_56(56, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'Directive\''(107, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_56(56, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'Directive\''(171, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_56(56, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'Directive\''(184, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_56(56, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'Directive\''(185, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_56(56, Cat, Ss, Stack, T, Ts, Tzr).

'yeccgoto_\'Directives\''(29, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_106(106, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'Directives\''(49=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_96(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'Directives\''(51, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_55(55, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'Directives\''(56=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_94(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'Directives\''(97, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_99(99, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'Directives\''(100, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_102(102, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'Directives\''(107, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_110(110, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'Directives\''(171, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_55(173, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'Directives\''(184, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_55(187, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'Directives\''(185, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_55(199, Cat, Ss, Stack, T, Ts, Tzr).

'yeccgoto_\'Document\''(0, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_13(13, Cat, Ss, Stack, T, Ts, Tzr).

'yeccgoto_\'EnumTypeDefinition\''(0=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_12(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'EnumTypeDefinition\''(15=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_12(_S, Cat, Ss, Stack, T, Ts, Tzr).

'yeccgoto_\'EnumValue\''(66=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_72(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'EnumValue\''(74=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_72(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'EnumValue\''(84=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_72(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'EnumValue\''(89=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_72(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'EnumValue\''(150=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_72(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'EnumValue\''(177=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_180(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'EnumValue\''(179=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_180(_S, Cat, Ss, Stack, T, Ts, Tzr).

'yeccgoto_\'EnumValueDefinition\''(177, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_179(179, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'EnumValueDefinition\''(179, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_179(179, Cat, Ss, Stack, T, Ts, Tzr).

'yeccgoto_\'EnumValueDefinitionList\''(177, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_178(178, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'EnumValueDefinitionList\''(179=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_181(_S, Cat, Ss, Stack, T, Ts, Tzr).

'yeccgoto_\'Field\''(26=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_32(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'Field\''(28=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_32(_S, Cat, Ss, Stack, T, Ts, Tzr).

'yeccgoto_\'FieldDefinition\''(124, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_127(127, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'FieldDefinition\''(127, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_127(127, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'FieldDefinition\''(157, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_127(127, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'FieldDefinition\''(162, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_127(127, Cat, Ss, Stack, T, Ts, Tzr).

'yeccgoto_\'FieldDefinitionList\''(124, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_126(126, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'FieldDefinitionList\''(127=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_128(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'FieldDefinitionList\''(157, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_158(158, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'FieldDefinitionList\''(162, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_163(163, Cat, Ss, Stack, T, Ts, Tzr).

'yeccgoto_\'FragmentDefinition\''(0=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_11(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'FragmentDefinition\''(15=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_11(_S, Cat, Ss, Stack, T, Ts, Tzr).

'yeccgoto_\'FragmentName\''(18, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_169(169, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'FragmentName\''(34, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_49(49, Cat, Ss, Stack, T, Ts, Tzr).

'yeccgoto_\'FragmentSpread\''(26=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_31(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'FragmentSpread\''(28=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_31(_S, Cat, Ss, Stack, T, Ts, Tzr).

'yeccgoto_\'ImplementsInterfaces\''(121, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_122(122, Cat, Ss, Stack, T, Ts, Tzr).

'yeccgoto_\'InlineFragment\''(26=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_30(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'InlineFragment\''(28=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_30(_S, Cat, Ss, Stack, T, Ts, Tzr).

'yeccgoto_\'InputObjectTypeDefinition\''(0=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_10(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'InputObjectTypeDefinition\''(15=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_10(_S, Cat, Ss, Stack, T, Ts, Tzr).

'yeccgoto_\'InputValueDefinition\''(131, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_144(144, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'InputValueDefinition\''(144, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_144(144, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'InputValueDefinition\''(166, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_144(144, Cat, Ss, Stack, T, Ts, Tzr).

'yeccgoto_\'InputValueDefinitionList\''(131, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_143(143, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'InputValueDefinitionList\''(144=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_145(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'InputValueDefinitionList\''(166, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_167(167, Cat, Ss, Stack, T, Ts, Tzr).

'yeccgoto_\'InterfaceTypeDefinition\''(0=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_9(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'InterfaceTypeDefinition\''(15=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_9(_S, Cat, Ss, Stack, T, Ts, Tzr).

'yeccgoto_\'ListType\''(132, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_136(136, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'ListType\''(137, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_136(136, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'ListType\''(147, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_136(136, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'ListType\''(152, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_136(136, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'ListType\''(192, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_136(136, Cat, Ss, Stack, T, Ts, Tzr).

'yeccgoto_\'ListValue\''(66=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_71(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'ListValue\''(74=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_71(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'ListValue\''(84=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_71(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'ListValue\''(89=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_71(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'ListValue\''(150=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_71(_S, Cat, Ss, Stack, T, Ts, Tzr).

'yeccgoto_\'Name\''(6, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_184(184, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'Name\''(16, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_176(176, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'Name\''(18=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_48(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'Name\''(19, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_165(165, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'Name\''(20, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_161(161, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'Name\''(23=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_160(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'Name\''(24, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_121(121, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'Name\''(25, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_115(115, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'Name\''(26, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_29(29, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'Name\''(28, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_29(29, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'Name\''(33, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_97(97, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'Name\''(34=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_48(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'Name\''(50=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_53(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'Name\''(57, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_58(58, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'Name\''(60, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_61(61, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'Name\''(63, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_61(61, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'Name\''(66=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_70(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'Name\''(73=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_93(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'Name\''(74=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_70(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'Name\''(79, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_82(82, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'Name\''(81, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_82(82, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'Name\''(84=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_70(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'Name\''(89=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_70(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'Name\''(116=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_53(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'Name\''(119=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_53(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'Name\''(123=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_53(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'Name\''(124, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_125(125, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'Name\''(127, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_125(125, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'Name\''(131, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_142(142, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'Name\''(132=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_53(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'Name\''(137=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_53(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'Name\''(144, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_142(142, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'Name\''(147=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_53(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'Name\''(150=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_70(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'Name\''(152=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_53(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'Name\''(155=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_53(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'Name\''(157, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_125(125, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'Name\''(162, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_125(125, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'Name\''(166, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_142(142, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'Name\''(170=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_53(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'Name\''(177=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_70(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'Name\''(179=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_70(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'Name\''(192=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_53(_S, Cat, Ss, Stack, T, Ts, Tzr).

'yeccgoto_\'NamedType\''(50=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_52(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'NamedType\''(116, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_118(118, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'NamedType\''(119, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_118(118, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'NamedType\''(123, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_155(155, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'NamedType\''(132, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_135(135, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'NamedType\''(137, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_135(135, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'NamedType\''(147, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_135(135, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'NamedType\''(152, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_135(135, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'NamedType\''(155, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_155(155, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'NamedType\''(170=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_52(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'NamedType\''(192, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_135(135, Cat, Ss, Stack, T, Ts, Tzr).

'yeccgoto_\'NamedTypeList\''(123=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_154(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'NamedTypeList\''(155=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_156(_S, Cat, Ss, Stack, T, Ts, Tzr).

'yeccgoto_\'NonNullType\''(132=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_134(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'NonNullType\''(137=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_134(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'NonNullType\''(147=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_134(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'NonNullType\''(152=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_134(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'NonNullType\''(192=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_134(_S, Cat, Ss, Stack, T, Ts, Tzr).

'yeccgoto_\'ObjectField\''(79, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_81(81, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'ObjectField\''(81, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_81(81, Cat, Ss, Stack, T, Ts, Tzr).

'yeccgoto_\'ObjectFields\''(79, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_80(80, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'ObjectFields\''(81=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_86(_S, Cat, Ss, Stack, T, Ts, Tzr).

'yeccgoto_\'ObjectTypeDefinition\''(0=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_8(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'ObjectTypeDefinition\''(15=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_8(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'ObjectTypeDefinition\''(17=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_175(_S, Cat, Ss, Stack, T, Ts, Tzr).

'yeccgoto_\'ObjectValue\''(66=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_69(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'ObjectValue\''(74=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_69(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'ObjectValue\''(84=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_69(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'ObjectValue\''(89=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_69(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'ObjectValue\''(150=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_69(_S, Cat, Ss, Stack, T, Ts, Tzr).

'yeccgoto_\'OperationDefinition\''(0=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'OperationDefinition\''(15=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr).

'yeccgoto_\'OperationType\''(0, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_6(6, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'OperationType\''(15, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_6(6, Cat, Ss, Stack, T, Ts, Tzr).

'yeccgoto_\'ScalarTypeDefinition\''(0=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_5(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'ScalarTypeDefinition\''(15=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_5(_S, Cat, Ss, Stack, T, Ts, Tzr).

'yeccgoto_\'Selection\''(26, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_28(28, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'Selection\''(28, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_28(28, Cat, Ss, Stack, T, Ts, Tzr).

'yeccgoto_\'SelectionSet\''(0=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_4(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'SelectionSet\''(15=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_4(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'SelectionSet\''(29=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_105(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'SelectionSet\''(51=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_54(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'SelectionSet\''(55=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_95(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'SelectionSet\''(97=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_98(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'SelectionSet\''(99=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_104(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'SelectionSet\''(100=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_101(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'SelectionSet\''(102=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_103(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'SelectionSet\''(106=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_112(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'SelectionSet\''(107=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_109(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'SelectionSet\''(110=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_111(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'SelectionSet\''(171=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_172(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'SelectionSet\''(173=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_174(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'SelectionSet\''(184=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_186(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'SelectionSet\''(185=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_198(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'SelectionSet\''(187=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_197(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'SelectionSet\''(199=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_200(_S, Cat, Ss, Stack, T, Ts, Tzr).

'yeccgoto_\'Selections\''(26, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_27(27, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'Selections\''(28=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_113(_S, Cat, Ss, Stack, T, Ts, Tzr).

'yeccgoto_\'Type\''(132=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_133(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'Type\''(137, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_138(138, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'Type\''(147, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_148(148, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'Type\''(152=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_153(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'Type\''(192, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_193(193, Cat, Ss, Stack, T, Ts, Tzr).

'yeccgoto_\'TypeCondition\''(50, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_51(51, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'TypeCondition\''(170, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_51(171, Cat, Ss, Stack, T, Ts, Tzr).

'yeccgoto_\'TypeDefinition\''(0=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_3(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'TypeDefinition\''(15=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_3(_S, Cat, Ss, Stack, T, Ts, Tzr).

'yeccgoto_\'TypeExtensionDefinition\''(0=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_2(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'TypeExtensionDefinition\''(15=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_2(_S, Cat, Ss, Stack, T, Ts, Tzr).

'yeccgoto_\'UnionMembers\''(116=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_117(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'UnionMembers\''(119=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_120(_S, Cat, Ss, Stack, T, Ts, Tzr).

'yeccgoto_\'UnionTypeDefinition\''(0=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_1(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'UnionTypeDefinition\''(15=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_1(_S, Cat, Ss, Stack, T, Ts, Tzr).

'yeccgoto_\'Value\''(66=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_68(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'Value\''(74, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_89(89, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'Value\''(84=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_85(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'Value\''(89, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_89(89, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'Value\''(150=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_151(_S, Cat, Ss, Stack, T, Ts, Tzr).

'yeccgoto_\'Values\''(74, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_88(88, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'Values\''(89=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_91(_S, Cat, Ss, Stack, T, Ts, Tzr).

'yeccgoto_\'Variable\''(66=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_67(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'Variable\''(74=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_67(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'Variable\''(84=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_67(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'Variable\''(89=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_67(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'Variable\''(150=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_67(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'Variable\''(188, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_191(191, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'Variable\''(190, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_191(191, Cat, Ss, Stack, T, Ts, Tzr).

'yeccgoto_\'VariableDefinition\''(188, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_190(190, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'VariableDefinition\''(190, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_190(190, Cat, Ss, Stack, T, Ts, Tzr).

'yeccgoto_\'VariableDefinitionList\''(188, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_189(189, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'VariableDefinitionList\''(190=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_195(_S, Cat, Ss, Stack, T, Ts, Tzr).

'yeccgoto_\'VariableDefinitions\''(184, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_51(185, Cat, Ss, Stack, T, Ts, Tzr).

-compile({inline,yeccpars2_4_/1}).
-file("src/graphql_parser.yrl", 33).
yeccpars2_4_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   build_ast_node ( 'OperationDefinition' , [ { operation , query } , { selectionSet , __1 } ] )
  end | __Stack].

-compile({inline,yeccpars2_14_/1}).
-file("src/graphql_parser.yrl", 21).
yeccpars2_14_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   build_ast_node ( 'Document' , { definitions , __1 } )
  end | __Stack].

-compile({inline,yeccpars2_15_/1}).
-file("src/graphql_parser.yrl", 23).
yeccpars2_15_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   [ __1 ]
  end | __Stack].

-compile({inline,yeccpars2_21_/1}).
-file("src/graphql_parser.yrl", 31).
yeccpars2_21_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   extract_atom ( __1 )
  end | __Stack].

-compile({inline,yeccpars2_22_/1}).
-file("src/graphql_parser.yrl", 30).
yeccpars2_22_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   extract_atom ( __1 )
  end | __Stack].

-compile({inline,yeccpars2_28_/1}).
-file("src/graphql_parser.yrl", 63).
yeccpars2_28_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   [ __1 ]
  end | __Stack].

-compile({inline,yeccpars2_29_/1}).
-file("src/graphql_parser.yrl", 78).
yeccpars2_29_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   build_ast_node ( 'Field' , { name , __1 } )
  end | __Stack].

-compile({inline,yeccpars2_35_/1}).
-file("src/graphql_parser.yrl", 117).
yeccpars2_35_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   extract_keyword ( __1 )
  end | __Stack].

-compile({inline,yeccpars2_36_/1}).
-file("src/graphql_parser.yrl", 119).
yeccpars2_36_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   extract_keyword ( __1 )
  end | __Stack].

-compile({inline,yeccpars2_37_/1}).
-file("src/graphql_parser.yrl", 110).
yeccpars2_37_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   extract_keyword ( __1 )
  end | __Stack].

-compile({inline,yeccpars2_38_/1}).
-file("src/graphql_parser.yrl", 113).
yeccpars2_38_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   extract_keyword ( __1 )
  end | __Stack].

-compile({inline,yeccpars2_39_/1}).
-file("src/graphql_parser.yrl", 118).
yeccpars2_39_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   extract_keyword ( __1 )
  end | __Stack].

-compile({inline,yeccpars2_40_/1}).
-file("src/graphql_parser.yrl", 114).
yeccpars2_40_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   extract_keyword ( __1 )
  end | __Stack].

-compile({inline,yeccpars2_41_/1}).
-file("src/graphql_parser.yrl", 109).
yeccpars2_41_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   extract_keyword ( __1 )
  end | __Stack].

-compile({inline,yeccpars2_42_/1}).
-file("src/graphql_parser.yrl", 107).
yeccpars2_42_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   extract_token ( __1 )
  end | __Stack].

-compile({inline,yeccpars2_43_/1}).
-file("src/graphql_parser.yrl", 120).
yeccpars2_43_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   extract_keyword ( __1 )
  end | __Stack].

-compile({inline,yeccpars2_44_/1}).
-file("src/graphql_parser.yrl", 108).
yeccpars2_44_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   extract_keyword ( __1 )
  end | __Stack].

-compile({inline,yeccpars2_45_/1}).
-file("src/graphql_parser.yrl", 116).
yeccpars2_45_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   extract_keyword ( __1 )
  end | __Stack].

-compile({inline,yeccpars2_46_/1}).
-file("src/graphql_parser.yrl", 112).
yeccpars2_46_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   extract_keyword ( __1 )
  end | __Stack].

-compile({inline,yeccpars2_47_/1}).
-file("src/graphql_parser.yrl", 115).
yeccpars2_47_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   extract_keyword ( __1 )
  end | __Stack].

-compile({inline,yeccpars2_49_/1}).
-file("src/graphql_parser.yrl", 70).
yeccpars2_49_(__Stack0) ->
 [__2,__1 | __Stack] = __Stack0,
 [begin
   build_ast_node ( 'FragmentSpread' , [ { name , __2 } ] )
  end | __Stack].

-compile({inline,yeccpars2_53_/1}).
-file("src/graphql_parser.yrl", 56).
yeccpars2_53_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   build_ast_node ( 'NamedType' , [ { name , __1 } ] )
  end | __Stack].

-compile({inline,yeccpars2_54_/1}).
-file("src/graphql_parser.yrl", 73).
yeccpars2_54_(__Stack0) ->
 [__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   build_ast_node ( 'InlineFragment' , [ { typeCondition , __3 } , { selectionSet , __4 } ] )
  end | __Stack].

-compile({inline,yeccpars2_56_/1}).
-file("src/graphql_parser.yrl", 102).
yeccpars2_56_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   [ __1 ]
  end | __Stack].

-compile({inline,yeccpars2_58_/1}).
-file("src/graphql_parser.yrl", 104).
yeccpars2_58_(__Stack0) ->
 [__2,__1 | __Stack] = __Stack0,
 [begin
   build_ast_node ( 'Directive' , [ { name , __2 } ] )
  end | __Stack].

-compile({inline,yeccpars2_59_/1}).
-file("src/graphql_parser.yrl", 105).
yeccpars2_59_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   build_ast_node ( 'Directive' , [ { name , __2 } , { arguments , __3 } ] )
  end | __Stack].

-compile({inline,yeccpars2_63_/1}).
-file("src/graphql_parser.yrl", 98).
yeccpars2_63_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   [ __1 ]
  end | __Stack].

-compile({inline,yeccpars2_64_/1}).
-file("src/graphql_parser.yrl", 99).
yeccpars2_64_(__Stack0) ->
 [__2,__1 | __Stack] = __Stack0,
 [begin
   [ __1 | __2 ]
  end | __Stack].

-compile({inline,yeccpars2_65_/1}).
-file("src/graphql_parser.yrl", 97).
yeccpars2_65_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   __2
  end | __Stack].

-compile({inline,yeccpars2_68_/1}).
-file("src/graphql_parser.yrl", 100).
yeccpars2_68_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   build_ast_node ( 'Argument' , [ { name , __1 } , { value , __3 } ] )
  end | __Stack].

-compile({inline,yeccpars2_69_/1}).
-file("src/graphql_parser.yrl", 129).
yeccpars2_69_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   build_ast_node ( 'ObjectValue' , [ { fields , __1 } ] )
  end | __Stack].

-compile({inline,yeccpars2_71_/1}).
-file("src/graphql_parser.yrl", 128).
yeccpars2_71_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   build_ast_node ( 'ListValue' , [ { values , __1 } ] )
  end | __Stack].

-compile({inline,yeccpars2_72_/1}).
-file("src/graphql_parser.yrl", 127).
yeccpars2_72_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   build_ast_node ( 'EnumValue' , [ { value , __1 } ] )
  end | __Stack].

-compile({inline,yeccpars2_75_/1}).
-file("src/graphql_parser.yrl", 126).
yeccpars2_75_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   build_ast_node ( 'BooleanValue' , [ { value , extract_boolean ( __1 ) } ] )
  end | __Stack].

-compile({inline,yeccpars2_76_/1}).
-file("src/graphql_parser.yrl", 124).
yeccpars2_76_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   build_ast_node ( 'FloatValue' , [ { value , extract_float ( __1 ) } ] )
  end | __Stack].

-compile({inline,yeccpars2_77_/1}).
-file("src/graphql_parser.yrl", 123).
yeccpars2_77_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   build_ast_node ( 'IntValue' , [ { value , extract_integer ( __1 ) } ] )
  end | __Stack].

-compile({inline,yeccpars2_78_/1}).
-file("src/graphql_parser.yrl", 125).
yeccpars2_78_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   build_ast_node ( 'StringValue' , [ { value , extract_token ( __1 ) } ] )
  end | __Stack].

-compile({inline,yeccpars2_81_/1}).
-file("src/graphql_parser.yrl", 140).
yeccpars2_81_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   [ __1 ]
  end | __Stack].

-compile({inline,yeccpars2_83_/1}).
-file("src/graphql_parser.yrl", 138).
yeccpars2_83_(__Stack0) ->
 [__2,__1 | __Stack] = __Stack0,
 [begin
   [ ]
  end | __Stack].

-compile({inline,yeccpars2_85_/1}).
-file("src/graphql_parser.yrl", 142).
yeccpars2_85_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   build_ast_node ( 'ObjectField' , [ { name , __1 } , { value , __3 } ] )
  end | __Stack].

-compile({inline,yeccpars2_86_/1}).
-file("src/graphql_parser.yrl", 141).
yeccpars2_86_(__Stack0) ->
 [__2,__1 | __Stack] = __Stack0,
 [begin
   [ __1 | __2 ]
  end | __Stack].

-compile({inline,yeccpars2_87_/1}).
-file("src/graphql_parser.yrl", 139).
yeccpars2_87_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   __2
  end | __Stack].

-compile({inline,yeccpars2_89_/1}).
-file("src/graphql_parser.yrl", 135).
yeccpars2_89_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   [ __1 ]
  end | __Stack].

-compile({inline,yeccpars2_90_/1}).
-file("src/graphql_parser.yrl", 133).
yeccpars2_90_(__Stack0) ->
 [__2,__1 | __Stack] = __Stack0,
 [begin
   [ ]
  end | __Stack].

-compile({inline,yeccpars2_91_/1}).
-file("src/graphql_parser.yrl", 136).
yeccpars2_91_(__Stack0) ->
 [__2,__1 | __Stack] = __Stack0,
 [begin
   [ __1 | __2 ]
  end | __Stack].

-compile({inline,yeccpars2_92_/1}).
-file("src/graphql_parser.yrl", 134).
yeccpars2_92_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   __2
  end | __Stack].

-compile({inline,yeccpars2_93_/1}).
-file("src/graphql_parser.yrl", 49).
yeccpars2_93_(__Stack0) ->
 [__2,__1 | __Stack] = __Stack0,
 [begin
   build_ast_node ( 'Variable' , [ { name , __2 } ] )
  end | __Stack].

-compile({inline,yeccpars2_94_/1}).
-file("src/graphql_parser.yrl", 103).
yeccpars2_94_(__Stack0) ->
 [__2,__1 | __Stack] = __Stack0,
 [begin
   [ __1 | __2 ]
  end | __Stack].

-compile({inline,yeccpars2_95_/1}).
-file("src/graphql_parser.yrl", 74).
yeccpars2_95_(__Stack0) ->
 [__5,__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   build_ast_node ( 'InlineFragment' , [ { typeCondition , __3 } , { directives , __4 } , { selectionSet , __5 } ] )
  end | __Stack].

-compile({inline,yeccpars2_96_/1}).
-file("src/graphql_parser.yrl", 71).
yeccpars2_96_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   build_ast_node ( 'FragmentSpread' , [ { name , __2 } , { directives , __3 } ] )
  end | __Stack].

-compile({inline,yeccpars2_97_/1}).
-file("src/graphql_parser.yrl", 86).
yeccpars2_97_(__Stack0) ->
 [__2,__1 | __Stack] = __Stack0,
 [begin
   build_ast_node ( 'Field' , [ { alias , __1 } , { name , __2 } ] )
  end | __Stack].

-compile({inline,yeccpars2_98_/1}).
-file("src/graphql_parser.yrl", 88).
yeccpars2_98_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   build_ast_node ( 'Field' , [ { alias , __1 } , { name , __2 } , { selectionSet , __3 } ] )
  end | __Stack].

-compile({inline,yeccpars2_99_/1}).
-file("src/graphql_parser.yrl", 90).
yeccpars2_99_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   build_ast_node ( 'Field' , [ { alias , __1 } , { name , __2 } , { directives , __3 } ] )
  end | __Stack].

-compile({inline,yeccpars2_100_/1}).
-file("src/graphql_parser.yrl", 87).
yeccpars2_100_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   build_ast_node ( 'Field' , [ { alias , __1 } , { name , __2 } , { arguments , __3 } ] )
  end | __Stack].

-compile({inline,yeccpars2_101_/1}).
-file("src/graphql_parser.yrl", 89).
yeccpars2_101_(__Stack0) ->
 [__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   build_ast_node ( 'Field' , [ { alias , __1 } , { name , __2 } , { arguments , __3 } , { selectionSet , __4 } ] )
  end | __Stack].

-compile({inline,yeccpars2_102_/1}).
-file("src/graphql_parser.yrl", 91).
yeccpars2_102_(__Stack0) ->
 [__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   build_ast_node ( 'Field' , [ { alias , __1 } , { name , __2 } , { arguments , __3 } , { directives , __4 } ] )
  end | __Stack].

-compile({inline,yeccpars2_103_/1}).
-file("src/graphql_parser.yrl", 93).
yeccpars2_103_(__Stack0) ->
 [__5,__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   build_ast_node ( 'Field' , [ { alias , __1 } , { name , __2 } , { arguments , __3 } , { directives , __4 } , { selectionSet , __5 } ] )
  end | __Stack].

-compile({inline,yeccpars2_104_/1}).
-file("src/graphql_parser.yrl", 92).
yeccpars2_104_(__Stack0) ->
 [__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   build_ast_node ( 'Field' , [ { alias , __1 } , { name , __2 } , { directives , __3 } , { selectionSet , __4 } ] )
  end | __Stack].

-compile({inline,yeccpars2_105_/1}).
-file("src/graphql_parser.yrl", 81).
yeccpars2_105_(__Stack0) ->
 [__2,__1 | __Stack] = __Stack0,
 [begin
   build_ast_node ( 'Field' , [ { name , __1 } , { selectionSet , __2 } ] )
  end | __Stack].

-compile({inline,yeccpars2_106_/1}).
-file("src/graphql_parser.yrl", 80).
yeccpars2_106_(__Stack0) ->
 [__2,__1 | __Stack] = __Stack0,
 [begin
   build_ast_node ( 'Field' , [ { name , __1 } , { directives , __2 } ] )
  end | __Stack].

-compile({inline,yeccpars2_107_/1}).
-file("src/graphql_parser.yrl", 79).
yeccpars2_107_(__Stack0) ->
 [__2,__1 | __Stack] = __Stack0,
 [begin
   build_ast_node ( 'Field' , [ { name , __1 } , { arguments , __2 } ] )
  end | __Stack].

-compile({inline,yeccpars2_108_/1}).
-file("src/graphql_parser.yrl", 95).
yeccpars2_108_(__Stack0) ->
 [__2,__1 | __Stack] = __Stack0,
 [begin
   __1
  end | __Stack].

-compile({inline,yeccpars2_109_/1}).
-file("src/graphql_parser.yrl", 83).
yeccpars2_109_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   build_ast_node ( 'Field' , [ { name , __1 } , { arguments , __2 } , { selectionSet , __3 } ] )
  end | __Stack].

-compile({inline,yeccpars2_110_/1}).
-file("src/graphql_parser.yrl", 84).
yeccpars2_110_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   build_ast_node ( 'Field' , [ { name , __1 } , { arguments , __2 } , { directives , __3 } ] )
  end | __Stack].

-compile({inline,yeccpars2_111_/1}).
-file("src/graphql_parser.yrl", 85).
yeccpars2_111_(__Stack0) ->
 [__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   build_ast_node ( 'Field' , [ { name , __1 } , { arguments , __2 } , { directives , __3 } , { selectionSet , __4 } ] )
  end | __Stack].

-compile({inline,yeccpars2_112_/1}).
-file("src/graphql_parser.yrl", 82).
yeccpars2_112_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   build_ast_node ( 'Field' , [ { name , __1 } , { directives , __2 } , { selectionSet , __3 } ] )
  end | __Stack].

-compile({inline,yeccpars2_113_/1}).
-file("src/graphql_parser.yrl", 64).
yeccpars2_113_(__Stack0) ->
 [__2,__1 | __Stack] = __Stack0,
 [begin
   [ __1 | __2 ]
  end | __Stack].

-compile({inline,yeccpars2_114_/1}).
-file("src/graphql_parser.yrl", 61).
yeccpars2_114_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   build_ast_node ( 'SelectionSet' , { selections , __2 } )
  end | __Stack].

-compile({inline,yeccpars2_117_/1}).
-file("src/graphql_parser.yrl", 179).
yeccpars2_117_(__Stack0) ->
 [__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   build_ast_node ( 'UnionTypeDefinition' , [ { name , __2 } , { types , __4 } ] )
  end | __Stack].

-compile({inline,yeccpars2_118_/1}).
-file("src/graphql_parser.yrl", 181).
yeccpars2_118_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   [ __1 ]
  end | __Stack].

-compile({inline,yeccpars2_120_/1}).
-file("src/graphql_parser.yrl", 182).
yeccpars2_120_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   [ __1 | __3 ]
  end | __Stack].

-compile({inline,yeccpars2_127_/1}).
-file("src/graphql_parser.yrl", 162).
yeccpars2_127_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   [ __1 ]
  end | __Stack].

-compile({inline,yeccpars2_128_/1}).
-file("src/graphql_parser.yrl", 163).
yeccpars2_128_(__Stack0) ->
 [__2,__1 | __Stack] = __Stack0,
 [begin
   [ __1 | __2 ]
  end | __Stack].

-compile({inline,yeccpars2_129_/1}).
-file("src/graphql_parser.yrl", 153).
yeccpars2_129_(__Stack0) ->
 [__5,__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   build_ast_node ( 'ObjectTypeDefinition' , [ { name , __2 } , { fields , __4 } ] )
  end | __Stack].

-compile({inline,yeccpars2_133_/1}).
-file("src/graphql_parser.yrl", 164).
yeccpars2_133_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   build_ast_node ( 'FieldDefinition' , [ { name , __1 } , { type , __3 } ] )
  end | __Stack].

-compile({inline,yeccpars2_139_/1}).
-file("src/graphql_parser.yrl", 57).
yeccpars2_139_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   build_ast_node ( 'ListType' , [ { type , __2 } ] )
  end | __Stack].

-compile({inline,yeccpars2_140_/1}).
-file("src/graphql_parser.yrl", 59).
yeccpars2_140_(__Stack0) ->
 [__2,__1 | __Stack] = __Stack0,
 [begin
   build_ast_node ( 'NonNullType' , [ { type , __1 } ] )
  end | __Stack].

-compile({inline,yeccpars2_141_/1}).
-file("src/graphql_parser.yrl", 58).
yeccpars2_141_(__Stack0) ->
 [__2,__1 | __Stack] = __Stack0,
 [begin
   build_ast_node ( 'NonNullType' , [ { type , __1 } ] )
  end | __Stack].

-compile({inline,yeccpars2_144_/1}).
-file("src/graphql_parser.yrl", 169).
yeccpars2_144_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   [ __1 ]
  end | __Stack].

-compile({inline,yeccpars2_145_/1}).
-file("src/graphql_parser.yrl", 170).
yeccpars2_145_(__Stack0) ->
 [__2,__1 | __Stack] = __Stack0,
 [begin
   [ __1 | __2 ]
  end | __Stack].

-compile({inline,yeccpars2_146_/1}).
-file("src/graphql_parser.yrl", 167).
yeccpars2_146_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   __2
  end | __Stack].

-compile({inline,yeccpars2_148_/1}).
-file("src/graphql_parser.yrl", 172).
yeccpars2_148_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   build_ast_node ( 'InputValueDefinition' , [ { name , __1 } , { type , __3 } ] )
  end | __Stack].

-compile({inline,yeccpars2_149_/1}).
-file("src/graphql_parser.yrl", 173).
yeccpars2_149_(__Stack0) ->
 [__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   build_ast_node ( 'InputValueDefinition' , [ { name , __1 } , { type , __3 } , { defaultValue , __4 } ] )
  end | __Stack].

-compile({inline,yeccpars2_151_/1}).
-file("src/graphql_parser.yrl", 51).
yeccpars2_151_(__Stack0) ->
 [__2,__1 | __Stack] = __Stack0,
 [begin
   __2
  end | __Stack].

-compile({inline,yeccpars2_153_/1}).
-file("src/graphql_parser.yrl", 165).
yeccpars2_153_(__Stack0) ->
 [__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   build_ast_node ( 'FieldDefinition' , [ { name , __1 } , { arguments , __2 } , { type , __4 } ] )
  end | __Stack].

-compile({inline,yeccpars2_154_/1}).
-file("src/graphql_parser.yrl", 157).
yeccpars2_154_(__Stack0) ->
 [__2,__1 | __Stack] = __Stack0,
 [begin
   __2
  end | __Stack].

-compile({inline,yeccpars2_155_/1}).
-file("src/graphql_parser.yrl", 159).
yeccpars2_155_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   [ __1 ]
  end | __Stack].

-compile({inline,yeccpars2_156_/1}).
-file("src/graphql_parser.yrl", 160).
yeccpars2_156_(__Stack0) ->
 [__2,__1 | __Stack] = __Stack0,
 [begin
   [ __1 | __2 ]
  end | __Stack].

-compile({inline,yeccpars2_159_/1}).
-file("src/graphql_parser.yrl", 155).
yeccpars2_159_(__Stack0) ->
 [__6,__5,__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   build_ast_node ( 'ObjectTypeDefinition' , [ { name , __2 } , { interfaces , __3 } , { fields , __5 } ] )
  end | __Stack].

-compile({inline,yeccpars2_160_/1}).
-file("src/graphql_parser.yrl", 184).
yeccpars2_160_(__Stack0) ->
 [__2,__1 | __Stack] = __Stack0,
 [begin
   build_ast_node ( 'ScalarTypeDefinition' , [ { name , __2 } ] )
  end | __Stack].

-compile({inline,yeccpars2_164_/1}).
-file("src/graphql_parser.yrl", 176).
yeccpars2_164_(__Stack0) ->
 [__5,__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   build_ast_node ( 'InterfaceTypeDefinition' , [ { name , __2 } , { fields , __4 } ] )
  end | __Stack].

-compile({inline,yeccpars2_168_/1}).
-file("src/graphql_parser.yrl", 195).
yeccpars2_168_(__Stack0) ->
 [__5,__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   build_ast_node ( 'InputObjectTypeDefinition' , [ { name , __2 } , { fields , __4 } ] )
  end | __Stack].

-compile({inline,yeccpars2_172_/1}).
-file("src/graphql_parser.yrl", 39).
yeccpars2_172_(__Stack0) ->
 [__5,__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   build_ast_node ( 'FragmentDefinition' , [ { name , __2 } , { typeCondition , __4 } , { selectionSet , __5 } ] )
  end | __Stack].

-compile({inline,yeccpars2_174_/1}).
-file("src/graphql_parser.yrl", 40).
yeccpars2_174_(__Stack0) ->
 [__6,__5,__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   build_ast_node ( 'FragmentDefinition' , [ { name , __2 } , { typeCondition , __4 } , { directives , __5 } , { selectionSet , __6 } ] )
  end | __Stack].

-compile({inline,yeccpars2_175_/1}).
-file("src/graphql_parser.yrl", 198).
yeccpars2_175_(__Stack0) ->
 [__2,__1 | __Stack] = __Stack0,
 [begin
   build_ast_node ( 'TypeExtensionDefinition' , [ { definition , __2 } ] )
  end | __Stack].

-compile({inline,yeccpars2_179_/1}).
-file("src/graphql_parser.yrl", 189).
yeccpars2_179_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   [ __1 ]
  end | __Stack].

-compile({inline,yeccpars2_181_/1}).
-file("src/graphql_parser.yrl", 190).
yeccpars2_181_(__Stack0) ->
 [__2,__1 | __Stack] = __Stack0,
 [begin
   [ __1 | __2 ]
  end | __Stack].

-compile({inline,yeccpars2_182_/1}).
-file("src/graphql_parser.yrl", 187).
yeccpars2_182_(__Stack0) ->
 [__5,__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   build_ast_node ( 'EnumTypeDefinition' , [ { name , __2 } , { values , __4 } ] )
  end | __Stack].

-compile({inline,yeccpars2_183_/1}).
-file("src/graphql_parser.yrl", 24).
yeccpars2_183_(__Stack0) ->
 [__2,__1 | __Stack] = __Stack0,
 [begin
   [ __1 | __2 ]
  end | __Stack].

-compile({inline,yeccpars2_186_/1}).
-file("src/graphql_parser.yrl", 34).
yeccpars2_186_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   build_ast_node ( 'OperationDefinition' , [ { operation , __1 } , { name , __2 } , { selectionSet , __3 } ] )
  end | __Stack].

-compile({inline,yeccpars2_190_/1}).
-file("src/graphql_parser.yrl", 45).
yeccpars2_190_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   [ __1 ]
  end | __Stack].

-compile({inline,yeccpars2_193_/1}).
-file("src/graphql_parser.yrl", 47).
yeccpars2_193_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   build_ast_node ( 'VariableDefinition' , [ { variable , __1 } , { type , __3 } ] )
  end | __Stack].

-compile({inline,yeccpars2_194_/1}).
-file("src/graphql_parser.yrl", 48).
yeccpars2_194_(__Stack0) ->
 [__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   build_ast_node ( 'VariableDefinition' , [ { variable , __1 } , { type , __3 } , { defaultValue , __4 } ] )
  end | __Stack].

-compile({inline,yeccpars2_195_/1}).
-file("src/graphql_parser.yrl", 46).
yeccpars2_195_(__Stack0) ->
 [__2,__1 | __Stack] = __Stack0,
 [begin
   [ __1 | __2 ]
  end | __Stack].

-compile({inline,yeccpars2_196_/1}).
-file("src/graphql_parser.yrl", 44).
yeccpars2_196_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   __2
  end | __Stack].

-compile({inline,yeccpars2_197_/1}).
-file("src/graphql_parser.yrl", 36).
yeccpars2_197_(__Stack0) ->
 [__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   build_ast_node ( 'OperationDefinition' , [ { operation , __1 } , { name , __2 } , { directives , __3 } , { selectionSet , __4 } ] )
  end | __Stack].

-compile({inline,yeccpars2_198_/1}).
-file("src/graphql_parser.yrl", 35).
yeccpars2_198_(__Stack0) ->
 [__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   build_ast_node ( 'OperationDefinition' , [ { operation , __1 } , { name , __2 } , { variableDefinitions , __3 } , { selectionSet , __4 } ] )
  end | __Stack].

-compile({inline,yeccpars2_200_/1}).
-file("src/graphql_parser.yrl", 37).
yeccpars2_200_(__Stack0) ->
 [__5,__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   build_ast_node ( 'OperationDefinition' , [ { operation , __1 } , { name , __2 } , { variableDefinitions , __3 } , { directives , __4 } , { selectionSet , __5 } ] )
  end | __Stack].


-file("src/graphql_parser.yrl", 220).
