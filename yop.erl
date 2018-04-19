-module(yop).
-export([build/1, ring_node/5, loop/1, test/0, data/1]).

build(N) ->
  Manager = self(),
  register(ring, Manager),
  %data(dict:new()),
  Data = spawn(?MODULE, data, [dict:new()]),
  Data ! {debut},
  Root = spawn(?MODULE, ring_node, [null, null, Manager, N, null]),
  Root ! {createdebut, N},
  %register(root, Root),
  %ring_node(Root, Manager, 1),
  loop(N).

data(Dict) ->
  receive

    {debut} -> io:fwrite("data actif ~n"), data(Dict);

    {append, Key, Value} -> Dict = dict:append(Key, Value, Dict), data(Dict);

    {erase, Key} -> Dict = dict:erase(Key, Dict), data(Dict);

    {fetch, Key, PID} -> Value = dict:fetch(Key, Dict), PID ! {val, Value}, data(Dict)

  end.

loop(N) ->
  receive

    {bro, PID} -> PID ! {broad}; %io:fwrite("wesh");

    yo -> io:fwrite("yop~n");

    ok ->
      io:format("Ring was built~n"),
      %send_messages(N),
      loop(N);

    {creation, Taille_ring, NN} -> io:fwrite("taille ring ~p, ce qu'il reste ~p~n",[Taille_ring,NN]), loop(N);

    {message, finished} -> io:format("It finished~n"),loop(N);

    {message, Value} ->
      loop(N)
  end.

send_messages(0) ->
  ring ! {message, finished};

send_messages(N) ->
  ring ! {message, N},
  send_messages(N-1).



ring_node(Father, ChildPid, Manager, Taille_ring, Root) ->
  receive

  %test -> io:fwrite("yoyo~n"), ChildPid ! {broad};
    yo -> io:fwrite("yopp");

    {create, 0} ->
      Manager ! {bro, self()}, %Manager ! yo, %ChildPid ! {broad},
      io:fwrite("ringg ~p et ~p~n",[self(),Root]),
      ring_node(self(), Root, Manager, Taille_ring, Root);

    {createdebut, N} ->
      Child = spawn(?MODULE, ring_node, [self(), null, Manager, Taille_ring, self()]),
      Child ! {create, N-1},
      Manager ! {creation, Taille_ring, N},
      io:fwrite("ring ~p et ~p~n",[self(),Child]),
      ring_node(self(), Child, Manager, Taille_ring,Root);

    {create, N} ->
      Child = spawn(?MODULE, ring_node, [self(), null, Manager, Taille_ring,Root]),
      Child ! {create, N-1},
      Manager ! {creation, Taille_ring, N},
      io:fwrite("ring ~p et ~p~n",[self(),Child]),
      ring_node(self(), Child, Manager, Taille_ring,Root);

    {kill, PID} when self() == PID -> ChildPid ! {kill, self(), ChildPid}, ring_node(Father, ChildPid, Manager, Taille_ring, Root);

    {kill, PID, Child} when ChildPid == PID -> ChildPid = Child,
    ring_node(Father, Child, Manager, Taille_ring, Root); %pid de celui qu'on supprime et son fils

    {add} -> Child = spawn(?MODULE, ring_node, [null, Manager, Taille_ring+1]),
    Child ! {add2, ChildPid},
    ring_node(Father, Child, Manager, Taille_ring, Root),
    ring_node(Father, ChildPid, Manager, Taille_ring, Root);

    {add2, NewChild} -> ChildPid = NewChild,
    ring_node(Father, ChildPid, Manager, Taille_ring, Root);

    {kill, PID, Child} -> ChildPid ! {kill, self(), ChildPid},
    ring_node(Father, ChildPid, Manager, Taille_ring, Root),
    ring_node(Father, Child, Manager, Taille_ring, Root);

    {broad} -> io:fwrite("Début broadcast~p~n",[ChildPid]), ChildPid ! {broad, 0, ChildPid}, ring_node(Father, ChildPid, Manager, Taille_ring,Root);

    {broad, Nb, PID} -> if Taille_ring - Nb == 0 -> io:fwrite("Fin broadcast~p~n",[ChildPid]), ring_node(Father, ChildPid, Manager, Taille_ring,Root);
                        true -> ChildPid ! {broad, Nb + 1, ChildPid},
                        io:fwrite("Broadcast ~p ~p ~p~n",[ChildPid,Nb,Taille_ring]),
                        ring_node(Father, ChildPid, Manager, Taille_ring,Root) end

  end.

test() -> build(4).
