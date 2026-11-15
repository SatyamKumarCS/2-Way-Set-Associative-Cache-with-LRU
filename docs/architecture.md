# Architecture and address mapping

## Common cache configuration

- Byte address: 32 bits.
- Word: 32 bits (4 bytes).
- Cache line: 16 bytes (4 words).
- Data capacity: 128 bytes for each cache.
- CPU requests are word-aligned (`address[1:0] == 2'b00`).
- Both implementations are blocking and read-only for this project.

## Direct-mapped cache

Eight lines, one way per line. Address fields:

| Field | Bits | Width |
|---|---|---:|
| Tag | `[31:7]` | 25 |
| Line index | `[6:4]` | 3 |
| Byte offset | `[3:0]` | 4 |
| Word index within line | `[3:2]` | 2 |

Each line stores one 25-bit tag, one valid bit and four 32-bit words.

## Two-way set-associative cache

Four sets and two ways per set. Address fields:

| Field | Bits | Width |
|---|---|---:|
| Tag | `[31:6]` | 26 |
| Set index | `[5:4]` | 2 |
| Byte offset | `[3:0]` | 4 |
| Word index within line | `[3:2]` | 2 |

Each way in each set stores one 26-bit tag, one valid bit and four 32-bit words.

## LRU convention

One LRU bit is stored per set:

- `0`: Way 0 is the least-recently-used victim.
- `1`: Way 1 is the least-recently-used victim.

After a hit in Way 0, set the bit to `1` (Way 1 becomes the victim). After a hit in Way 1, set it to `0`. On a miss, select an invalid way first. Use the LRU bit only when both ways are valid. After filling a way, mark the newly filled way as most recently used.

## Refill

A miss fetches the four 32-bit words at the 16-byte-aligned line base:

- `line_base + 0`
- `line_base + 4`
- `line_base + 8`
- `line_base + 12`

The line's tag and valid bit should be committed only after all four words have been received successfully, unless the team deliberately documents and verifies another safe refill strategy.

## Suggested conflict example

`0x00000000` and `0x00000080` map to the same direct-mapped line and the same two-way set under these configurations. They conflict in direct mapping but can coexist in the two-way cache.
