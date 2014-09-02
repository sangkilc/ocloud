(** oCloud: controlling cloud nodes via command lines (written in OCaml)

    @author Sang Kil Cha <sangkil.cha\@gmail.com>

*)
(*
Copyright (c) 2014, Sang Kil Cha
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:
    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.
    * Neither the name of the <organization> nor the
      names of its contributors may be used to endorse or promote products
      derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL SANG KIL CHA BE LIABLE FOR ANY
DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
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

