-module(ring).
-export([build/1, ring_node/3, loop/1, test/0, data/1]).

build(N) ->
  Manager = self(),
  register(ring, Manager),
  Data = spawn(?MODULE, data, [dict:new()]),
  Root = spawn(?MODULE, ring_node, [null, Manager, 1, Data]),
  Root ! {create, N},
  %register(root, Root),
  %ring_node(Root, Manager, 1),
  loop(N).

loop(N) ->
  receive

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



data(Dict) ->
  receive

    {append, Key, Value} -> Dict = append(Key, Value, Dict), data(Dict);

    {erase, Key} -> Dict = erase(Key, Dict), data(Dict);

    {fetch, Key, PID} -> Value = fetch(Key, Dict), PID ! {val, Value}, data(Dict)

  end.

ring_node(ChildPid, Manager, Taille_ring, Data) ->
  receive

  %test -> io:fwrite("yoyo~n"), ChildPid ! {broad};
    yo -> io:fwrite("yopp");

    {create, 0} ->
      Manager ! ok, Manager ! yo, ChildPid ! {broad},
      ring_node(ChildPid, Manager, Taille_ring, Data);

    {create, N} ->
      Child = spawn(?MODULE, ring_node, [null, Manager, Taille_ring+1]),
      Child ! {create, N-1},
      Manager ! {creation, Taille_ring, N},
      ring_node(Child, Manager, Taille_ring, Data);


    {kill, PID} when self() = PID -> ChildPid ! {kill, self(), ChildPid}, ring_node(Child, Manager, Taille_ring, Data);

    {kill, PID, Child} when ChildPid = PID -> ChildPid = Child,
    ring_node(Child, Manager, Taille_ring, Data); %pid de celui qu'on supprime et son fils

    {add} -> Child = spawn(?MODULE, ring_node, [null, Manager, Taille_ring+1]),
    Child ! {add2, ChildPid}
    ring_node(Child, Manager, Taille_ring, Data)

    {add2, NewChild} -> ChildPid = NewChild,
    ring_node(ChildPid, Manager, Taille_ring, Data);

    {kill, PID, Child} -> ChildPid ! {kill, self(), ChildPid},
    ring_node(Child, Manager, Taille_ring, Data);

    {add_info, Info} -> UUID = 12, Data ! {append, UUID, Info},
    ring_node(ChildPid, Manager, Taille_ring, Data);

    {info, UUID} -> Data ! {fetch, UUID, PID},
    ring_node(ChildPid, Manager, Taille_ring, Data);

    {val, Value, PID} when self()=PID -> ring_node(ChildPid, Manager, Taille_ring, Data);

    {val, Value, PID} -> ChildPid ! {val, Value, PID},
    ring_node(ChildPid, Manager, Taille_ring, Data);

    {broad} -> io:fwrite("Début broadcast~p~n",[ChildPid]), ChildPid ! {broad, 0, ChildPid}, ring_node(ChildPid, Manager, Taille_ring, Data);

    {broad, Nb, PID} -> if Taille_ring - Nb == 0 -> ring_node(ChildPid, Manager, Taille_ring, Data), io:fwrite("Fin broadcast~p~n",[ChildPid]);
                        true -> ChildPid ! {broad, Nb + 1, ChildPid},
                        io:fwrite("Broadcast ~p~n",[ChildPid]),
                        ring_node(ChildPid, Manager, Taille_ring, Data) end

  end.

test() -> build(4).
