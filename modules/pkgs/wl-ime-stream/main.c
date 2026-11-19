// Each "locked<TAB>tentative" line on stdin types the new part of locked into the
// focused field and shows tentative as provisional text; end of input types it too.
// Derived from https://gitlab.freedesktop.org/emersion/wl-ime-type, see LICENSE.
#define _POSIX_C_SOURCE 200809L
#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <wayland-client.h>
#include "input-method-unstable-v2-protocol.h"

// A Wayland message holds at most 4096 bytes.
#define CHUNK 3000

static struct zwp_input_method_manager_v2 *ime_manager = NULL;
static struct wl_seat *seat = NULL;

static bool ime_active = false;
static bool ime_unavailable = false;
static uint32_t ime_serial = 0;

static void noop_ime_surrounding_text(void *data, struct zwp_input_method_v2 *ime, const char *text, uint32_t cursor, uint32_t anchor) {}
static void noop_ime_text_change_cause(void *data, struct zwp_input_method_v2 *ime, uint32_t cause) {}
static void noop_ime_content_type(void *data, struct zwp_input_method_v2 *ime, uint32_t hint, uint32_t purpose) {}
static void noop_registry_global_remove(void *data, struct wl_registry *registry, uint32_t name) {}

static void ime_handle_activate(void *data, struct zwp_input_method_v2 *ime)
{
	ime_active = true;
}

static void ime_handle_deactivate(void *data, struct zwp_input_method_v2 *ime)
{
	ime_active = false;
}

static void ime_handle_done(void *data, struct zwp_input_method_v2 *ime)
{
	ime_serial++;
}

static void ime_handle_unavailable(void *data, struct zwp_input_method_v2 *ime)
{
	ime_unavailable = true;
}

static const struct zwp_input_method_v2_listener ime_listener = {
	.activate = ime_handle_activate,
	.deactivate = ime_handle_deactivate,
	.surrounding_text = noop_ime_surrounding_text,
	.text_change_cause = noop_ime_text_change_cause,
	.content_type = noop_ime_content_type,
	.done = ime_handle_done,
	.unavailable = ime_handle_unavailable,
};

static void registry_handle_global(void *data, struct wl_registry *registry, uint32_t name, const char *iface, uint32_t version)
{
	if (strcmp(iface, zwp_input_method_manager_v2_interface.name) == 0) {
		ime_manager = wl_registry_bind(registry, name, &zwp_input_method_manager_v2_interface, 1);
	} else if (seat == NULL && strcmp(iface, wl_seat_interface.name) == 0) {
		seat = wl_registry_bind(registry, name, &wl_seat_interface, 2);
	}
}

static const struct wl_registry_listener registry_listener = {
	.global = registry_handle_global,
	.global_remove = noop_registry_global_remove,
};

// Length of the longest prefix of text that fits a message and ends on a character boundary.
static size_t chunk_length(const char *text)
{
	size_t length = strlen(text);
	if (length <= CHUNK) {
		return length;
	}
	length = CHUNK;
	while ((text[length] & 0xC0) == 0x80) {
		length--;
	}
	return length;
}

static void roundtrip(struct wl_display *display)
{
	if (wl_display_roundtrip(display) < 0) {
		fprintf(stderr, "wl_display_roundtrip failed\n");
		exit(1);
	}
	if (ime_unavailable) {
		fprintf(stderr, "IME is unavailable (maybe another IME is active?)\n");
		exit(1);
	}
}

// Queues text as real input, sending all but its last chunk.
static void type(struct wl_display *display, struct zwp_input_method_v2 *ime, const char *text)
{
	while (*text != '\0') {
		char *chunk = strndup(text, chunk_length(text));
		zwp_input_method_v2_commit_string(ime, chunk);
		free(chunk);
		text += chunk_length(text);
		if (*text != '\0') {
			zwp_input_method_v2_commit(ime, ime_serial);
			roundtrip(display);
		}
	}
}

int main(void)
{
	struct wl_display *display = wl_display_connect(NULL);
	if (display == NULL) {
		fprintf(stderr, "wl_display_connect failed\n");
		return 1;
	}

	struct wl_registry *registry = wl_display_get_registry(display);
	wl_registry_add_listener(registry, &registry_listener, NULL);
	roundtrip(display);

	if (seat == NULL) {
		fprintf(stderr, "No seat found\n");
		return 1;
	}
	if (ime_manager == NULL) {
		fprintf(stderr, "Compositor doesn't support input-method-unstable-v2\n");
		return 1;
	}

	struct zwp_input_method_v2 *ime = zwp_input_method_manager_v2_get_input_method(ime_manager, seat);
	zwp_input_method_v2_add_listener(ime, &ime_listener, NULL);

	char *line = NULL, *locked = NULL;
	const char *tentative = "";
	size_t capacity = 0, typed = 0;
	ssize_t length;
	while ((length = getline(&line, &capacity, stdin)) != -1) {
		if (length > 0 && line[length - 1] == '\n') {
			line[length - 1] = '\0';
		}
		// getline leaves its buffer undefined once input ends.
		free(locked);
		locked = strdup(line);
		char *tab = strchr(locked, '\t');
		if (tab != NULL) {
			*tab = '\0';
			tentative = tab + 1;
		}
		if (tab == NULL || strlen(locked) < typed) {
			fprintf(stderr, "Expected locked<TAB>tentative, with locked only growing\n");
			return 1;
		}
		// Also picks up the focused field and the serial the next commit must carry.
		roundtrip(display);
		if (!ime_active) {
			continue;
		}
		type(display, ime, locked + typed);
		typed = strlen(locked);
		// Terminals do not wrap provisional text, so only its end is worth sending.
		const char *tail = tentative;
		while (strlen(tail) > CHUNK) {
			tail += chunk_length(tail);
		}
		// An empty string leaves Ghostty composing and swallowing keys; a bare commit clears it.
		if (*tail != '\0') {
			zwp_input_method_v2_set_preedit_string(ime, tail, strlen(tail), strlen(tail));
		}
		zwp_input_method_v2_commit(ime, ime_serial);
	}

	roundtrip(display);
	if (locked == NULL || (locked[typed] == '\0' && *tentative == '\0')) {
		return 0;
	}
	if (!ime_active) {
		fprintf(stderr, "No text field\n");
		return 1;
	}

	type(display, ime, locked + typed);
	if (locked[typed] != '\0' && *tentative != '\0') {
		zwp_input_method_v2_commit(ime, ime_serial);
		roundtrip(display);
	}
	type(display, ime, tentative);
	zwp_input_method_v2_commit(ime, ime_serial);
	roundtrip(display);

	return 0;
}
