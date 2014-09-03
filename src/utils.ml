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

let check_exit_status = function
  | Unix.WEXITED 0 -> ()
  | Unix.WEXITED _
  | Unix.WSIGNALED _
  | Unix.WSTOPPED _ -> failwith "failed execution"

let syscall ?(env=[| |]) cmd =
  let ic, oc, ec = Unix.open_process_full cmd env in
  let buf1 = Buffer.create 96
  and buf2 = Buffer.create 48 in
  (try
     while true do Buffer.add_channel buf1 ic 1 done
   with End_of_file -> ());
  (try
     while true do Buffer.add_channel buf2 ec 1 done
   with End_of_file -> ());
  let exit_status = Unix.close_process_full (ic, oc, ec) in
  check_exit_status exit_status;
  (Buffer.contents buf1,
   Buffer.contents buf2)

let get_packagename progname =
  let out, _ = syscall ("apt-file find "^progname^" | awk -F: '{print $1}' | head -n 1") in
  let () = if String.length out = 0 then (Printf.printf "%s package not found\n" progname; flush stdout) else () in
  out

let sorting a b = Pervasives.compare a b

let get_list d exts =
  try
    let handle = Unix.opendir d in
    let rec loop acc =
      try
        let file = Unix.readdir handle in
        let extreg = match exts with
          | None -> Str.regexp ("[^.].*")
          | Some exts -> Str.regexp (".*\\.\\("^exts^"\\)$")
        in
        if Str.string_match extreg file 0 then
          loop ((Filename.concat d file)::acc)
        else
          loop acc
      with _ -> List.sort sorting acc
    in
    loop []
  with _ -> []

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

