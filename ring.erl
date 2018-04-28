-module(ring).
-export([build/1, ring_node/6, loop/1, test/0, data/1, broad/1, add/1, kill/1, send/3, erase/2, getvalue/2]).

build(N) ->
  Manager = self(),
  register(ring, Manager),
  %data(dict:new()),
  Data = spawn(node(), ?MODULE, data, [dict:new()]),
  Data ! {debut},
  Root = spawn(node(), ?MODULE, ring_node, [null, null, Manager, N, null, Data]),
  Root ! {createdebut, N},
  %register(root, Root),
  %ring_node(Root, Manager, 1),
  loop(N).

data(Dict) ->
  receive

    {debut} -> io:fwrite("data actif ~n"), data(Dict);

    {append, Key, Value} -> D = dict:append(Key, Value, Dict), data(D);

    {erase, Key} -> D = dict:erase(Key, Dict), data(Daa);

    {fetch, Key, PID} ->io:fwrite("La valeur est ~p~n", [dict:fetch(Key, Dict)]), Value = dict:fetch(Key, Dict), PID ! {val, Value}, data(Dict)

  end.

loop(N) ->
  receive

    {bro, PID} -> PID ! {broad}; %io:fwrite("wesh");

    yo -> io:fwrite("yop~n");

    ok ->
      io:format("Ring was built~n"),
      loop(N);

    {creation, Taille_ring, NN} -> io:fwrite("taille ring ~p, ce qu'il reste ~p~n",
          [Taille_ring,NN]), loop(N);

    {message, finished} -> io:format("It finished~n"),loop(N);

    {message, Value} ->
      loop(N)
  end.




ring_node(Father, ChildPid, Manager, Taille_ring, Root, Data) ->
  receive

  %test -> io:fwrite("yoyo~n"), ChildPid ! {broad};
    yo -> io:fwrite("yopp");

    {create, 0} ->
      Manager ! {bro, self()},
      ring_node(self(), Root, Manager, Taille_ring, Root, Data);

    {createdebut, N} ->
      Child = spawn(node(), ?MODULE, ring_node, [self(), null, Manager, Taille_ring, self(), Data]),
      Child ! {create, N-1},
      Manager ! {creation, Taille_ring, N},
      ring_node(self(), Child, Manager, Taille_ring,Root, Data);

    {create, N} ->
      Child = spawn(node(), ?MODULE, ring_node, [self(), null, Manager, Taille_ring,Root, Data]),
      Child ! {create, N-1},
      Manager ! {creation, Taille_ring, N},
      ring_node(self(), Child, Manager, Taille_ring, Root, Data);

    {send, M, UUID} -> ChildPid ! {send2, M, UUID, self()},
    Data ! {append, UUID, M},
    ring_node(Father, ChildPid, Manager, Taille_ring, Root, Data);

    {send2, M, UUID, PID} -> if self()==PID -> ring_node(Father, ChildPid, Manager, Taille_ring, Root, Data);
                            true -> ChildPid ! {send2, M, UUID, PID},
                            ring_node(Father, ChildPid, Manager, Taille_ring, Root, Data) end;

    {get, Key} -> io:fwrite("On recoit la clé~p~n",[Key]), Data ! {fetch, Key, self()}, ring_node(Father, ChildPid, Manager, Taille_ring, Root, Data);

    {val, Val} -> io:fwrite("On recoit la valeur ~p~n",[Val]), ring_node(Father, ChildPid, Manager, Taille_ring, Root, Data);

    {kill, PID} when self() == PID -> ChildPid ! {kill, self(), ChildPid, Taille_ring-1};%, ring_node(Father, ChildPid, Manager, Taille_ring, Root);

    {kill, PID, Child, NewTaille_ring} -> if ChildPid == PID ->
    ring_node(Father, Child, Manager, NewTaille_ring, Root, Data); %pid de celui qu'on supprime et son fils
                                          true -> ChildPid ! {kill, PID, Child, NewTaille_ring}, ring_node(Father, ChildPid, Manager, NewTaille_ring, Root, Data) end;

    {add} -> %io:fwrite("add~p~n",[self()]),
    Child = spawn(node(), ?MODULE, ring_node, [null, null, Manager, Taille_ring+1, null, Data]),
    io:fwrite("addChild ~p~n",[Child]),
    Child ! {add2, ChildPid, Taille_ring+1},
    ring_node(self(), Child, Manager, Taille_ring+1, Root, Data);
    %ring_node(Father, ChildPid, Manager, Taille_ring+1, Root);

    {add2, NewChild, NewTaille_ring} ->
    NewChild ! {broadadd, NewTaille_ring},
    ring_node(self(), NewChild, Manager, NewTaille_ring, Root, Data);

% faire pour gerer taille ring
    {broadadd, NewTaille_ring} -> io:fwrite("Début broadcastadd~p~n",[ChildPid]),
    ChildPid ! {broadadd, 0, ChildPid, NewTaille_ring}, ring_node(Father, ChildPid, Manager, NewTaille_ring,Root, Data);

    {broadadd, Nb, PID, NewTaille_ring} -> if NewTaille_ring - Nb == 0
      -> io:fwrite("Fin broadcastadd ~p~n",[ChildPid]),
        ring_node(Father, ChildPid, Manager, Taille_ring,Root, Data);

                            true -> ChildPid ! {broadadd, Nb + 1, ChildPid, NewTaille_ring},
                              io:fwrite("Broadcastadd ~p ~n",[ChildPid]),
                              ring_node(Father, ChildPid, Manager, Taille_ring,Root, Data) end;

    {kill, PID, Child} -> ChildPid ! {kill, self(), ChildPid},
    ring_node(Father, ChildPid, Manager, Taille_ring, Root, Data),
    ring_node(Father, Child, Manager, Taille_ring, Root, Data);

    {broad} -> io:fwrite("Début broadcast~p~n",[ChildPid]), ChildPid ! {broad, 0, ChildPid}, ring_node(Father, ChildPid, Manager, Taille_ring,Root, Data);

    {broad, Nb, PID} -> if Taille_ring - Nb == 0 -> io:fwrite("Fin broadcast ~p~n",[ChildPid]),
    ring_node(Father, ChildPid, Manager, Taille_ring,Root, Data);
                        true -> ChildPid ! {broad, Nb + 1, ChildPid},
                        io:fwrite("Broadcast ~p ~n",[ChildPid]),
                        ring_node(Father, ChildPid, Manager, Taille_ring,Root, Data) end

  end.

broad(PID) -> PID ! {broad}.

add(PID) -> PID ! {add}.

kill(PID) -> PID ! {kill, PID}.

send(M, UUID, PID) -> PID ! {send, M, UUID}.

erase(Key, PID) -> PID ! {erase, Key}.

getvalue(Key, PID) -> PID ! {get, Key}.

test() -> build(4).
