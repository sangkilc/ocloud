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

open Client
open Cloudapi

let ocloud_env_user = "OCLOUD_USER"

let user_id =
  try Sys.getenv ocloud_env_user
  with Not_found -> "user"

let root_id = "root"

module Cloud (API: API) =
struct

  let reboot keypath client_list =
    API.parallel_exec keypath client_list root_id (API.sshcmd ["reboot"])

  let kill keypath client_list =
    API.parallel_exec ~screen:false keypath client_list root_id
      (API.sshcmd ["pkill -9 -u "^user_id]);
    API.parallel_exec keypath client_list user_id
      (API.screencmd ["-wipe"])

  let pull keypath client_list = function
    | path_from::path_to::_ ->
        let () = Utils.mkdir path_to in
        API.parallel_exec keypath client_list user_id
          (API.pullcmd path_from path_to)
    | _ -> failwith "pull takes 2 arguments"

  let zippull keypath client_list = function
    | path_from::path_to::_ ->
        let () = Utils.mkdir path_to in
        let zipfile = "backup.bz2" in
        API.parallel_exec ~screen:false keypath client_list user_id
          (API.sshcmd [(Printf.sprintf "tar cjf %s %s" zipfile path_from)]);
        API.parallel_exec keypath client_list user_id
          (API.pullcmd zipfile path_to)
    | _ -> failwith "zippull takes 2 arguments"

  let push keypath client_list = function
    | path_from::path_to::_ ->
        API.parallel_exec keypath client_list user_id
          (API.pushcmd path_from path_to)
    | _ -> failwith "push takes 2 arguments"

  let connect keypath uid client =
    API.exec (API.sshcmd [] uid keypath client false)

  let rec connect_to keypath uid name = function
    | client::tl ->
        if Str.string_match (Str.regexp name) client.client_name 0 then
          connect keypath uid client
        else
          connect_to keypath uid name tl
    | [] -> failwith "failed to find client name"

  let connect keypath client_list = function
    | name::_ -> connect_to keypath user_id name client_list
    | [] -> failwith "client name is not given"

  let ping keypath client_list = function
    | _ -> () (* TODO *)

  let list_clients client_list =
    List.iter (fun {client_name=n;client_addr=a} ->
      Printf.printf "(%s) : (%s)\n" n a
    ) client_list

  let exec keypath client_list cmd uid =
    let cmd = String.concat " " cmd in
    API.parallel_exec ~screen:false keypath client_list uid
      (API.sshcmd [cmd])

  let parse_opt keypath client_list args = function
    | "reboot" -> reboot keypath client_list
    | "kill" | "clear" -> kill keypath client_list
    | "pull" -> pull keypath client_list args
    | "zippull" -> zippull keypath client_list args
    | "push" -> push keypath client_list args
    | "connect" -> connect keypath client_list args
    | "ping" -> ping keypath client_list args
    | "list" | "ls" -> list_clients client_list
    | "exec" | "execute" -> exec keypath client_list args user_id
    | "rootexec" -> exec keypath client_list args root_id
    | opt ->
        failwith ("unknown option: ("^opt^")")

end

module DebianCloud = Cloud(DebianAPI)

let usage = "Usage: "^Sys.argv.(0)^" <client file> [optional args] <cmds>\n"

let invalid_arg () =
  print_string usage;
  print_string (
    "  exec <cmd>                           : execute a command in cloud\n"^
    "  rootexec <cmd>                       : execute a command as a root\n"^
    "  reboot                               : reboot\n" ^
    "  kill                                 : stop all the user processes\n" ^
    "  ping                                 : check availability of clients\n" ^
    "  pull <remote> <local>                : pull remote file to local dir\n" ^
    "  push <local> <remote>                : push local file/dir to remote\n" ^
    "  connect <client_name>                : connect to a client\n" ^
    "  list                                 : show client list\n" ^
    "\n"
  );
  exit 1

let parse listfile opt args parse =
  let client_list = Client.read_list_of_clients listfile in
  parse None client_list args opt

let () =
  if Array.length Sys.argv < 3 then invalid_arg ();
  let args = Array.to_list Sys.argv in
  match args with
    | _::lst::"debian"::opt::args -> parse lst opt args DebianCloud.parse_opt
    | _::lst::"linux"::opt::args -> parse lst opt args DebianCloud.parse_opt
    | _::lst::opt::args -> parse lst opt args DebianCloud.parse_opt
    | _ -> failwith "invalid arguments passed"

