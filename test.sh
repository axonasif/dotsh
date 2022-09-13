#!/bin/bash
self="$(< $0)"
echo "$self"
while printf '%s' "$self" | cmp --silent -- - "$0"; do {
				sleep 0.2;
} done