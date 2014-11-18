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
example of a client file, where there are two client nodes with names 01 and 02.

```bash
### client name : client address : port (optional)
01 : hello-world.com
02 : hello-world.com : 4242
```

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
  of the directory will contain myfile.txt that is copied from each of the client.
```
$ ./ocloud.native clients.txt pull /home/user/myfile.txt results
```

