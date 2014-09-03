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

let get_name_and_addr l =
  let t = Str.split (Str.regexp_string ":") l in
  match t with
    | name::addr::[] -> name, Utils.trim addr
    | _ -> failwith "bad format"

let readlines chan =
  let rec readloop acc =
    try
      let l = input_line chan in
      let fc = String.get l 0 in
      match fc with
        | '#' -> readloop acc
        | _ ->
            let n,a = get_name_and_addr l in
            readloop ({client_name=n; client_addr=a}::acc)
    with _ -> List.rev acc
  in
  readloop []

let read_list_of_clients path =
  let f = open_in path in
  let lines = readlines f in
  close_in f;
  lines

