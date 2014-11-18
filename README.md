oCloud
======

oCloud is a command-line interface for managing cloud nodes. You can run
arbitrary commands such as bash scripts on multiple cloud nodes from a terminal.

Quick Start
-----------

```
Usage: ./ocloud.native <client file> [optional args] <cmds>
```

The first argument of oCloud is always a client file, which specifies a list of
client addresses. The second argument is an optional argument, which we will
discuss later. The third (or the second if the optional argument is not given)
argument and the rest of the arguments specify commands. You can list available
commands by simply typing:
```
$ ./ocloud.native
```

### Client File

A client file is an ASCII text file where each line specifies a tuple (client
name, client address). Each line of the client file is separated by a colon ':',
and there can be either two or three colon-separated elements. There are two
elements when a line contains a client name and a client address. There are
three elements when a line has a client name, an address, and a port number. Any
line started with a '#' is considered to be a comment line. The following is an
example of a client file, where there are three client nodes with names 01, 02
and 03.

```bash
### client name : client address : port (optional)
01 : hello-world.com
02 : hello-world.com : 4242
03 : foo-bar.net
```

### List Clients (`list`)

The command `list` shows a list of client nodes and their connection statuses.
Below is an example output. Notice we cannot connect to the node 03 in this
case.

```
$ ./ocloud.native clients.txt list
(01) : (hello-world.com) : (22) : ok
(02) : (hello-world.com) : (4242) : ok
(03) : (foo-bar.net) : (22) : failed to connect
```

Always make sure all the client nodes are accessible before executing any
commands. If you cannot connect to any of the nodes, please check the
followings.

* Can you ping the nodes?
* Can you connect to the nodes by manually typing ssh?
* Did you ran ssh-agent? oCloud always assumes that ssh-agent is running on
  background, and properly setup so that you don't need to type in passphrases
  every time you invoke a command.
* Do you have a different user id in your client nodes than the one you have in
  your local machine? If so, set an environment variable *OCLOUD_USER* to have a
  correct user name for your remote machines.

### Execution (`exec`)

The command `exec` executes (an) arbitrary command(s) in each client in
parallel.

* Print out /tmp/results from each node:
```
$ ./ocloud.native clients.txt exec cat /tmp/results
```

* Grep the last foo line of /tmp/results from each node:
```
$ ./ocloud.native clients.txt exec 'grep foo /tmp/results | tail -n 1'
```

### Root Execution (`rootexec`)

The command `rootexec` is the same as `exec` except that it executes commands as
a root.

### Push (`push`)

The commnand `push` copies a local file over to the client nodes in parallel.

* Copy myfile.txt to each client node (in /home/user/myfile.txt)
```
$ ./ocloud.native clients.txt push myfile.txt /home/user/myfile.txt
```

### Pull (`pull`)

The commnand `pull` copies remote files of the same path into local.

* Copy /home/user/myfile.txt file on each node into results directory. The
  results directory will contain a list of directories for each client and each
  of the directory will contain myfile.txt that is copied from each of the
  client.
```
$ ./ocloud.native clients.txt pull /home/user/myfile.txt results
```

