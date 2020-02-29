# @Todo: dependencies (currently a folder dependency)
SRC=mainframe

all:
	odin run $(SRC)

build:
	odin build $(SRC)

run:
	.\$(SRC)
