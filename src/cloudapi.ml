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

open Client

type cmdgen_t =
  string ->
  string option ->
  client_t ->
  bool ->
  string list

module type OSType =
sig

  val ssh_path : string
  val scp_path : string
  val nohup_path : string
  val screen_path : string

end

module type API =
sig

  val exec : string list -> bool -> unit

  (* return true if the program successfully exited. otherwise return false *)
  val execute_return : string option -> string -> cmdgen_t -> client_t -> bool

  val parallel_exec :
    ?screen:bool ->
    string option ->
    client_t list ->
    string ->
    cmdgen_t ->
    unit

  val sequential_exec :
    client_t list ->
    string ->
    cmdgen_t ->
    string option ->
    unit

  val sshcmd : string list -> cmdgen_t
  val pullcmd : string -> string -> cmdgen_t
  val pushcmd : string -> string -> cmdgen_t
  val screencmd : string list -> cmdgen_t

end

module CloudAPI (OS : OSType) : API =
struct

  let ssh client keypath =
    let port = string_of_int client.client_port in
    match keypath with
      | None ->
        [
          OS.ssh_path;
          "-o";"StrictHostKeyChecking=no";
          "-o";"PasswordAuthentication=no";
          "-o";"ConnectTimeout=3";
          "-p";port
        ]
      | Some keypath ->
        [
          OS.ssh_path;
          "-i";keypath;
          "-o";"StrictHostKeyChecking=no";
          "-o";"PasswordAuthentication=no";
          "-o";"ConnectTimeout=3";
          "-p";port
        ]

  let scp client keypath =
    let port = string_of_int client.client_port in
    match keypath with
      | None ->
        [
          OS.scp_path;
          "-r";
          "-o";"StrictHostKeyChecking=no";
          "-o";"PasswordAuthentication=no";
          "-c";"arcfour";"-C";
          "-P";port
        ]
      | Some keypath ->
        [
          OS.scp_path;
          "-i";keypath;
          "-r";
          "-o";"StrictHostKeyChecking=no";
          "-o";"PasswordAuthentication=no";
          "-c";"arcfour";"-C";
          "-P";port
        ]

  let sshcmd cmds =
    fun uid keypath client screen -> begin
        ssh client keypath
      @ [uid^"@"^client.client_addr]
      @ (
          if screen then
            [OS.screen_path; "-S"; "ozzuf"; "-d"; "-m"; OS.nohup_path]
          else
            []
        )
      @ cmds
    end

  let pullcmd path_from path_to =
    fun uid keypath client screen -> begin
      let cd = Filename.concat path_to (client.client_name^"_"^client.client_addr) in
      let () = Utils.mkdir cd in
        scp client keypath
      @ [uid^"@"^client.client_addr^":"^path_from; cd]
    end

  let pushcmd path_from path_to =
    fun uid keypath client screen -> begin
        scp client keypath
      @ [path_from; uid^"@"^client.client_addr^":"^path_to]
    end

  let screencmd opt =
    sshcmd ([OS.screen_path] @ opt)

  let exec cmds noout =
    let null_out () =
      let fd = Unix.openfile "/dev/null" [Unix.O_WRONLY] 0o666 in
      Unix.dup2 fd Unix.stdout;
      Unix.dup2 fd Unix.stderr;
      Unix.close fd
    in
    let arr = Array.of_list cmds in
    if noout then null_out () else ();
    Unix.execvp arr.(0) arr

  let fork_and_exec screen uid cmdgen keypath noout client =
    let pid = Unix.fork () in
    match pid with
      | 0 -> (* child *)
          let cmds = cmdgen uid keypath client screen in
          exec cmds noout
      | -1 -> failwith "failed to fork"
      | _ -> ()

  let execute_return keypath uid cmdgen client =
    fork_and_exec false uid cmdgen keypath true client;
    let _pid, status = Unix.wait () in
    match status with
      | Unix.WEXITED c when c = 0 -> true
      | _ -> false

  let wait_for_children clients =
    List.iter (fun _ -> ignore( Unix.wait () )) clients

  let parallel_exec ?screen:(screen=true) keypath lst uid cmdgen =
    List.iter (fork_and_exec screen uid cmdgen keypath false) lst;
    wait_for_children lst

  let sequential_exec lst uid cmdgen keypath =
    List.iter (fun ({client_name=name} as cl) ->
      Printf.printf "client: %s\n" name; flush stdout;
      let () = fork_and_exec false uid cmdgen keypath false cl in
      ignore( Unix.wait () )
    ) lst

end

module Debian =
struct

  let ssh_path = "/usr/bin/ssh"
  let scp_path = "/usr/bin/scp"
  let nohup_path = "/usr/bin/nohup"
  let screen_path = "/usr/bin/screen"

end

module DebianAPI = CloudAPI(Debian)

