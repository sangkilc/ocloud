(** oCloud: controlling cloud nodes via command lines (written in OCaml)

    @author Sang Kil Cha <sangkil.cha\@gmail.com>

*)
(*
Copyright (c) 2014, Sang Kil Cha
All rights reserved.
This software is free software; you can redistribute it and/or
modify it under the terms of the GNU Library General Public
License version 2, with the special exception on linking
described in file LICENSE.

This software is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
*)


type client_t = {
  client_name: string;
  client_addr: string;
}

val read_list_of_clients : string -> client_t list

