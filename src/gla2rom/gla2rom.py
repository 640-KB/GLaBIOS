import sys
import argparse


def build_padded_file_with_checksum(input_path, output_path, target_size=8192):
    # Read original file
    with open(input_path, "rb") as f:
        data = f.read()

    # Prepare buffer of exactly target_size bytes
    buf = bytearray(target_size)

    if len(data) >= target_size:
        # Truncate
        #buf[:] = data[:target_size]
        # Take the last (target_size) block of input and save to output
        buf[:] = data[-target_size:]
    else:
        # Copy and leave the rest zero-padded (including last byte temporarily)
        buf[:len(data)] = data

    # Compute 8-bit sum over first target_size - 1 bytes
    s = sum(buf[:-1]) & 0xFF

    # Compute checksum = (-sum) mod 256
    checksum = (-s) & 0xFF

    # Put checksum in the last byte
    buf[-1] = checksum

    # Write output file
    with open(output_path, "wb") as f:
        f.write(buf)

    print(f"Wrote {target_size} bytes to {output_path}")
    print(f"Checksum byte (last byte): 0x{checksum:02X}")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Pad/truncate a file and add checksum to final byte.")
    parser.add_argument("input", help="Input binary file")
    parser.add_argument("output", help="Output binary file")
    parser.add_argument("-s", "--size", type=int, default=8192,
                        help="Target output size in bytes (default 8192)")
    args = parser.parse_args()

    build_padded_file_with_checksum(args.input, args.output, args.size)
