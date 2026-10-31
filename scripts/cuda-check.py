"""Small driver-level check: no models or Python dependencies are downloaded."""

import ctypes


def main():
    cuda = ctypes.CDLL("libcuda.so.1")

    def check(code):
        if code:
            message = ctypes.c_char_p()
            cuda.cuGetErrorString(code, ctypes.byref(message))
            raise RuntimeError(f"CUDA error {code}: {message.value!r}")

    check(cuda.cuInit(0))
    count = ctypes.c_int()
    check(cuda.cuDeviceGetCount(ctypes.byref(count)))
    if not count.value:
        raise RuntimeError("No CUDA devices visible to WSL")
    for device in range(count.value):
        name = ctypes.create_string_buffer(256)
        major, minor = ctypes.c_int(), ctypes.c_int()
        check(cuda.cuDeviceGetName(name, len(name), device))
        check(cuda.cuDeviceComputeCapability(ctypes.byref(major), ctypes.byref(minor), device))
        print(f"GPU {device}: {name.value.decode()} — compute capability {major.value}.{minor.value}")
    print("CUDA driver passthrough: OK")


if __name__ == "__main__":
    main()
