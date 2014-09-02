###
### oCloud: command line cloud control
###

all: ocloud

.SUFFIXES: .ml .mli .cmo .cmi .cmx

%.cmi: %.mli
	ocamlfind ocamlopt -c $<

%.cmx: %.ml
	ocamlfind ocamlopt -c $<

client.cmx: client.cmi

ocloud: utils.cmx client.cmx cloudapi.cmx ocloud.ml
	ocamlfind ocamlopt -g -o $@ $^ -package unix,str -linkpkg

clean:
	rm -rf *.cmx *.cmo *.cmi *.o ocloud

