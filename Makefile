PREFIX ?= /usr/local
sysconfdir ?= /etc

DAEMON=process-scheduler

SRC_DAEMON = Makefile Cargo.lock Cargo.toml $(shell find src -type f -wholename '*src/*.rs')
SRC_LIB = scheduler/Cargo.toml $(shell find scheduler/src -type f -wholename '*src/*.rs')
	  #pidwatcher/Cargo.toml $(shell find pidwatcher/src -type f -wholename '*src/*.rs')

TARGET = debug

DEBUG ?= 0
ifeq ($(DEBUG),0)
	ARGS += "--release"
	TARGET = release
endif

VENDORED ?= 0
ifeq ($(VENDORED),1)
	ARGS += "--frozen"
endif

.PHONY: all clean distclean install uninstall vendor

all: target/$(TARGET)/$(DAEMON)

clean:
	cargo clean

distclean:
	rm -rf .cargo vendor vendor.tar.xz

vendor:
	mkdir -p .cargo
	cargo vendor | head -n -1 > .cargo/config
	echo 'directory = "vendor"' >> .cargo/config
	tar pcfJ vendor.tar.xz vendor
	rm -rf vendor

install: all
	install -Dm04755 "target/$(TARGET)/$(DAEMON)" "$(DESTDIR)$(PREFIX)/bin/$(DAEMON)"
	install -Dm0644 "data/$(DAEMON).service" "$(DESTDIR)/lib/systemd/system/$(DAEMON).service"

uninstall:
	rm "$(DESTDIR)$(PREFIX)/bin/$(DAEMON)" "$(DESTDIR)/lib/systemd/system/$(DAEMON).service"

systemd-enable:
	systemctl daemon-reload
	systemctl enable $(DAEMON)
	systemctl is-active $(DAEMON) && systemctl restart $(DAEMON) || systemctl start $(DAEMON)

target/$(TARGET)/$(DAEMON): $(SRC_LIB) $(SRC_DAEMON)
ifeq ($(VENDORED),1)
	tar pxf vendor.tar.xz
endif
	cargo build $(ARGS)
