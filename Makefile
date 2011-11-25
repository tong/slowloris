
APP = slowloris
NEKO = bin/$(APP).n
SRC = Slowloris.hx slowloris/*.hx

all: build

$(NEKO) : $(SRC)
	haxe -neko $@ -main Slowloris \
		-resource help@help

bin: $(NEKO)
	haxelib run xcross $(NEKO)

build: bin

clean:
	rm -f $(NEKO)
	rm -f bin/$(APP)
	rm -f bin/$(APP)-*
	
.PHONY: all build clean
