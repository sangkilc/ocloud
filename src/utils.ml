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

let trim str =
  if str = "" then ""
  else
    let search_pos init p next =
      let rec search i =
        if p i then raise(Failure "empty")
        else
          match str.[i] with
            | ' ' | '\n' | '\r' | '\t' -> search (next i)
            | _ -> i
      in
      search init
    in
    let len = String.length str in
    try
      let left = search_pos 0 (fun i -> i >= len) (succ)
      and right = search_pos (len - 1) (fun i -> i < 0) (pred)
      in
      String.sub str left (right - left + 1)
    with
      Failure "empty" -> ""

let mkdir path =
  try Unix.mkdir path 0o755 with _ -> failwith "dir exists"

