CC=clang

FRAMEWORKS:= -framework Foundation -framework IOKit
LIBRARIES:= -lobjc

SOURCE=temp_sensor.m

CFLAGS=-Wall -v $(SOURCE)
LDFLAGS=$(LIBRARIES) $(FRAMEWORKS)
OUT=-o temp_sensor

build:
	$(CC) $(CFLAGS) $(LDFLAGS) $(OUT)

all: build

run:
	./temp_sensor | ./monitor.py

.phony: build run