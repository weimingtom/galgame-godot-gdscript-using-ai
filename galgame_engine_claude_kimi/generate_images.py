#!/usr/bin/env python3
import struct
import zlib

def png_chunk(chunk_type, data):
    chunk = chunk_type + data
    crc = zlib.crc32(chunk) & 0xffffffff
    return struct.pack('>I', len(data)) + chunk + struct.pack('>I', crc)

def create_png_rgba(width, height, get_pixel):
    raw = bytearray()
    for y in range(height):
        raw.append(0)  # filter type: none
        for x in range(width):
            r, g, b, a = get_pixel(x, y)
            raw.extend([r, g, b, a])

    compressed = zlib.compress(bytes(raw))
    signature = b'\x89PNG\r\n\x1a\n'
    ihdr = struct.pack('>IIBBBBB', width, height, 8, 6, 0, 0, 0)
    return signature + png_chunk(b'IHDR', ihdr) + png_chunk(b'IDAT', compressed) + png_chunk(b'IEND', b'')

def create_png_rgb(width, height, get_pixel):
    raw = bytearray()
    for y in range(height):
        raw.append(0)
        for x in range(width):
            r, g, b = get_pixel(x, y)
            raw.extend([r, g, b])

    compressed = zlib.compress(bytes(raw))
    signature = b'\x89PNG\r\n\x1a\n'
    ihdr = struct.pack('>IIBBBBB', width, height, 8, 2, 0, 0, 0)
    return signature + png_chunk(b'IHDR', ihdr) + png_chunk(b'IDAT', compressed) + png_chunk(b'IEND', b'')

def create_school_gate():
    w, h = 640, 360
    def pixel(x, y):
        if y < h * 0.6:
            r, g, b = 135, 206, 235
        elif y < h * 0.75:
            r, g, b = 100, 180, 100
        else:
            r, g, b = 140, 140, 140

        gate_l, gate_r = int(w * 0.35), int(w * 0.65)
        gate_t, gate_b = int(h * 0.3), int(h * 0.75)

        if gate_l <= x <= gate_r and gate_t <= y <= gate_b:
            if y < gate_t + 10 or x < gate_l + 10 or x > gate_r - 10 or y > gate_b - 5:
                r, g, b = 180, 140, 100

        if ((gate_l - 15 <= x <= gate_l) or (gate_r <= x <= gate_r + 15)) and y < gate_b:
            r, g, b = 160, 160, 170

        return r, g, b
    return create_png_rgb(w, h, pixel)

def create_heroine1():
    w, h = 256, 384
    cx, cy = w // 2, h // 2
    head_y = int(h * 0.15)
    head_r = int(w * 0.18)
    hair_r = int(w * 0.22)
    body_t, body_b = int(h * 0.32), int(h * 0.75)
    body_w = int(w * 0.2)
    arm_t, arm_b = int(h * 0.35), int(h * 0.6)
    arm_w = int(w * 0.08)
    arm_dx = int(w * 0.28)
    leg_t = int(h * 0.75)
    leg_w = int(w * 0.08)
    leg_dx = int(w * 0.1)

    def pixel(x, y):
        a = 0
        r = g = b = 0
        dx = x - cx
        dy = y - head_y
        d2 = dx*dx + dy*dy

        if d2 < head_r*head_r:
            a, r, g, b = 255, 255, 220, 200

        if d2 < hair_r*hair_r:
            if dy < -head_r * 0.3 or abs(dx) > head_r * 0.7:
                a, r, g, b = 255, 255, 150, 180

        if body_t <= y <= body_b and abs(x - cx) < body_w:
            a, r, g, b = 255, 80, 120, 200

        if arm_t <= y <= arm_b and (abs(x - (cx - arm_dx)) < arm_w or abs(x - (cx + arm_dx)) < arm_w):
            a, r, g, b = 255, 80, 120, 200

        if leg_t <= y and abs(x - (cx - leg_dx)) < leg_w:
            a, r, g, b = 255, 255, 220, 200
        if leg_t <= y and abs(x - (cx + leg_dx)) < leg_w:
            a, r, g, b = 255, 255, 220, 200

        return r, g, b, a
    return create_png_rgba(w, h, pixel)

def create_sakura():
    w, h = 640, 360
    tree_cx, tree_cy = int(w * 0.3), int(h * 0.4)

    def pixel(x, y):
        ratio = y / h
        r = int(255 - ratio * 50)
        g = int(200 - ratio * 80)
        b = int(220 - ratio * 60)

        dx = x - tree_cx
        dy = y - tree_cy
        dist = (dx*dx + dy*dy) ** 0.5

        if abs(x - tree_cx) < 10 and y > tree_cy:
            r, g, b = 101, 67, 33

        if dist < 75 and y < tree_cy + 25:
            r, g, b = 255, 183, 197

        if (x * 7 + y * 13) % 200 < 5 and y > h * 0.3:
            r, g, b = 255, 200, 210

        return r, g, b
    return create_png_rgb(w, h, pixel)

with open('assets/bg/school_gate.png', 'wb') as f:
    f.write(create_school_gate())
print("school_gate.png done")

with open('assets/characters/heroine1.png', 'wb') as f:
    f.write(create_heroine1())
print("heroine1.png done")

with open('assets/bg/sakura.png', 'wb') as f:
    f.write(create_sakura())
print("sakura.png done")
