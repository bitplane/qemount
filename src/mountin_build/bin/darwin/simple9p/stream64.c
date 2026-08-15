#include <errno.h>
#include <fcntl.h>
#include <pthread.h>
#include <signal.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/socket.h>
#include <sys/types.h>
#include <sys/wait.h>
#include <unistd.h>

#define RECORD_PREFIX "Q9:"
#define READY_RECORD "Q9!\n"
#define RECORD_LIMIT (16U * 1024U * 1024U)

struct relay {
    int stream;
    int child;
};

static const char alphabet[] =
    "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

static int
write_all(int fd, const void *buffer, size_t length)
{
    const unsigned char *bytes = buffer;

    while (length > 0) {
        ssize_t written = write(fd, bytes, length);
        if (written < 0) {
            if (errno == EINTR)
                continue;
            return -1;
        }
        if (written == 0)
            return -1;
        bytes += written;
        length -= (size_t)written;
    }
    return 0;
}

static size_t
encode64(const unsigned char *input, size_t length, char *output)
{
    size_t in = 0;
    size_t out = 0;

    while (in + 3 <= length) {
        unsigned value = ((unsigned)input[in] << 16)
            | ((unsigned)input[in + 1] << 8) | input[in + 2];
        output[out++] = alphabet[(value >> 18) & 63];
        output[out++] = alphabet[(value >> 12) & 63];
        output[out++] = alphabet[(value >> 6) & 63];
        output[out++] = alphabet[value & 63];
        in += 3;
    }
    if (in < length) {
        unsigned value = (unsigned)input[in] << 16;
        output[out++] = alphabet[(value >> 18) & 63];
        if (++in < length) {
            value |= (unsigned)input[in] << 8;
            output[out++] = alphabet[(value >> 12) & 63];
            output[out++] = alphabet[(value >> 6) & 63];
            output[out++] = '=';
        } else {
            output[out++] = alphabet[(value >> 12) & 63];
            output[out++] = '=';
            output[out++] = '=';
        }
    }
    return out;
}

static int
base64_value(unsigned char byte)
{
    if (byte >= 'A' && byte <= 'Z')
        return byte - 'A';
    if (byte >= 'a' && byte <= 'z')
        return byte - 'a' + 26;
    if (byte >= '0' && byte <= '9')
        return byte - '0' + 52;
    if (byte == '+')
        return 62;
    if (byte == '/')
        return 63;
    return -1;
}

static int
decode64(const char *input, size_t length, unsigned char *output,
    size_t *output_length)
{
    size_t in;
    size_t out = 0;

    if (length == 0 || length % 4 != 0)
        return -1;
    for (in = 0; in < length; in += 4) {
        int a = base64_value((unsigned char)input[in]);
        int b = base64_value((unsigned char)input[in + 1]);
        int c = input[in + 2] == '=' ? 0
            : base64_value((unsigned char)input[in + 2]);
        int d = input[in + 3] == '=' ? 0
            : base64_value((unsigned char)input[in + 3]);
        unsigned value;

        if (a < 0 || b < 0 || c < 0 || d < 0)
            return -1;
        if ((input[in + 2] == '=' && input[in + 3] != '=')
            || (input[in + 2] == '=' && in + 4 != length)
            || (input[in + 3] == '=' && in + 4 != length))
            return -1;
        value = ((unsigned)a << 18) | ((unsigned)b << 12)
            | ((unsigned)c << 6) | (unsigned)d;
        output[out++] = (unsigned char)(value >> 16);
        if (input[in + 2] != '=')
            output[out++] = (unsigned char)(value >> 8);
        if (input[in + 3] != '=')
            output[out++] = (unsigned char)value;
    }
    *output_length = out;
    return 0;
}

static int
read_record(int fd, char **record, size_t *capacity)
{
    size_t length = 0;

    for (;;) {
        char byte;
        ssize_t count = read(fd, &byte, 1);
        if (count == 0)
            return 0;
        if (count < 0) {
            if (errno == EINTR)
                continue;
            return -1;
        }
        if (byte == '\n') {
            (*record)[length] = '\0';
            return 1;
        }
        if (byte == '\r')
            continue;
        if (length + 1 >= *capacity) {
            size_t next = *capacity * 2;
            char *grown;
            if (next > RECORD_LIMIT)
                return -1;
            grown = realloc(*record, next);
            if (grown == NULL)
                return -1;
            *record = grown;
            *capacity = next;
        }
        (*record)[length++] = byte;
    }
}

static void *
decode_input(void *argument)
{
    struct relay *relay = argument;
    size_t capacity = 4096;
    char *record = malloc(capacity);
    unsigned char *decoded = NULL;
    size_t decoded_capacity = 0;

    if (record == NULL)
        goto done;
    for (;;) {
        size_t encoded_length;
        size_t decoded_length;
        size_t required;
        int result = read_record(relay->stream, &record, &capacity);
        if (result <= 0)
            break;
        if (strncmp(record, RECORD_PREFIX, sizeof(RECORD_PREFIX) - 1) != 0)
            continue;
        encoded_length = strlen(record + sizeof(RECORD_PREFIX) - 1);
        required = encoded_length / 4 * 3;
        if (required > decoded_capacity) {
            unsigned char *grown = realloc(decoded, required);
            if (grown == NULL)
                break;
            decoded = grown;
            decoded_capacity = required;
        }
        if (decode64(record + sizeof(RECORD_PREFIX) - 1, encoded_length,
                decoded, &decoded_length) == 0) {
            if (write_all(relay->child, decoded, decoded_length) < 0)
                break;
        }
    }

done:
    free(decoded);
    free(record);
    shutdown(relay->child, SHUT_WR);
    return NULL;
}

static int
encode_output(struct relay *relay)
{
    unsigned char input[4096];
    char output[sizeof(RECORD_PREFIX) - 1 + ((sizeof(input) + 2) / 3) * 4 + 1];

    memcpy(output, RECORD_PREFIX, sizeof(RECORD_PREFIX) - 1);
    for (;;) {
        ssize_t length = read(relay->child, input, sizeof(input));
        size_t encoded_length;
        if (length == 0)
            return 0;
        if (length < 0) {
            if (errno == EINTR)
                continue;
            return -1;
        }
        encoded_length = encode64(input, (size_t)length,
            output + sizeof(RECORD_PREFIX) - 1);
        output[sizeof(RECORD_PREFIX) - 1 + encoded_length] = '\n';
        if (write_all(relay->stream, output,
                sizeof(RECORD_PREFIX) + encoded_length) < 0)
            return -1;
    }
}

static void
usage(const char *program)
{
    fprintf(stderr, "Usage: %s stream command [argument ...]\n", program);
}

int
main(int argc, char **argv)
{
    int pair[2];
    int stream;
    pid_t child;
    pthread_t input_thread;
    struct relay relay;
    int thread_error;
    int status = 1;

    if (argc < 3) {
        usage(argv[0]);
        return 2;
    }
    stream = open(argv[1], O_RDWR);
    if (stream < 0 || socketpair(AF_UNIX, SOCK_STREAM, 0, pair) < 0) {
        perror("stream64");
        return 1;
    }
    child = fork();
    if (child < 0) {
        perror("fork");
        return 1;
    }
    if (child == 0) {
        close(pair[0]);
        close(stream);
        if (dup2(pair[1], STDIN_FILENO) < 0) {
            perror("dup2");
            _exit(127);
        }
        close(pair[1]);
        execvp(argv[2], &argv[2]);
        perror(argv[2]);
        _exit(127);
    }

    close(pair[1]);
    relay.stream = stream;
    relay.child = pair[0];
    if (write_all(stream, READY_RECORD, sizeof(READY_RECORD) - 1) < 0) {
        kill(child, SIGTERM);
    } else if ((thread_error = pthread_create(
                    &input_thread, NULL, decode_input, &relay)) != 0) {
        errno = thread_error;
        perror("pthread_create");
        kill(child, SIGTERM);
    } else {
        encode_output(&relay);
        shutdown(pair[0], SHUT_RDWR);
        pthread_cancel(input_thread);
        pthread_join(input_thread, NULL);
        if (waitpid(child, &status, 0) < 0)
            status = 1;
    }
    close(pair[0]);
    close(stream);
    return WIFEXITED(status) ? WEXITSTATUS(status) : 1;
}
