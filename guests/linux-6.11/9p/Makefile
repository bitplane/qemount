CC = gcc
CFLAGS = -O2 -static -D_XOPEN_SOURCE=600
TARGET = simple9p

LIBIXP_DIR = libixp
BUILD_DIR = build
OUTPUT_DIR = /outputs/guests/linux-6.11/rootfs/$(ARCH)/bin

# Core libixp source files
LIBIXP_SRCS = \
	convert.c \
	error.c \
	map.c \
	message.c \
	request.c \
	rpc.c \
	server.c \
	socket.c \
	transport.c \
	util.c \
	timer.c \
	client.c \
	thread.c

.PHONY: all clean install

all: $(BUILD_DIR)/$(TARGET)

$(LIBIXP_DIR):
	git clone https://github.com/0intro/libixp.git $(LIBIXP_DIR)

$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)

# Build libixp manually to avoid their build system issues
$(BUILD_DIR)/libixp.a: | $(LIBIXP_DIR) $(BUILD_DIR)
	cd $(LIBIXP_DIR)/lib/libixp && \
	for f in $(LIBIXP_SRCS); do \
		$(CC) $(CFLAGS) -I../../include -c $$f -o $(CURDIR)/$(BUILD_DIR)/$${f%.c}.o || exit 1; \
	done
	ar rcs $@ $(BUILD_DIR)/*.o

# Build our server
$(BUILD_DIR)/$(TARGET): simple9p.c $(BUILD_DIR)/libixp.a | $(BUILD_DIR)
	$(CC) $(CFLAGS) -I$(LIBIXP_DIR)/include -o $@ $< $(BUILD_DIR)/libixp.a -lpthread
	strip $@

install: $(BUILD_DIR)/$(TARGET)
	mkdir -p $(OUTPUT_DIR)
	cp $(BUILD_DIR)/$(TARGET) $(OUTPUT_DIR)/

clean:
	rm -rf $(BUILD_DIR)
	rm -rf $(LIBIXP_DIR)