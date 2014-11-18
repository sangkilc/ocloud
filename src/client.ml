(** oCloud: controlling cloud nodes via command lines

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

open Utils

type client_t = {
  client_name: string;
  client_addr: string;
  client_port: int;
}

let get_name_and_addr l =
  let t = Str.split (Str.regexp_string ":") l in
  match t with
    | name::addr::[] -> name, trim addr, 22
    | name::addr::port::[] -> name, trim addr, (int_of_string (trim port))
    | _ -> failwith "bad format"

let readlines chan =
  let rec readloop acc =
    try
      let l = input_line chan in
      let fc = String.get l 0 in
      match fc with
        | '#' -> readloop acc
        | _ ->
            let n, a, p = get_name_and_addr l in
            readloop ({client_name=n; client_addr=a; client_port=p}::acc)
    with End_of_file -> List.rev acc
  in
  readloop []

let read_list_of_clients path =
  let f = open_in path in
  let lines = readlines f in
  close_in f;
  lines

