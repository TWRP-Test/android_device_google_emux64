#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
ARTIFACTS="${SCRIPT_DIR}/artifacts"

QEMU="${QEMU:-qemu-system-x86_64}"
QEMU_IMG="${QEMU_IMG:-qemu-img}"
RAMDISK="${RAMDISK:-${ARTIFACTS}/ramdisk-recovery.cpio}"
KERNEL="${KERNEL:-${ARTIFACTS}/kernel-ranchu}"
DATA_IMG="${DATA_IMG:-${ARTIFACTS}/qemu_userdata.img}"
LOG="${LOG:-${ARTIFACTS}/qemu_boot.log}"

WIDTH="${WIDTH:-1080}"
HEIGHT="${HEIGHT:-1920}"
REFRESH="${REFRESH:-60}"
WINDOW_MODE="${WINDOW_MODE:-auto}"

# QEMU's GTK frontend currently emits a Wayland assertion on some Linux
# desktops. Use the X11 backend when an X11 display is available.
if [[ "${XDG_SESSION_TYPE:-}" == "wayland" && -n "${DISPLAY:-}" ]]; then
    export GDK_BACKEND="${QEMU_GDK_BACKEND:-x11}"
fi

fit_qemu_window() {
    local qemu_pid="$1"
    local window_id
    local work_x work_y work_width work_height
    local workarea
    local margin=32
    local available_width available_height
    local target_width target_height
    local target_x target_y
    local candidate
    local geometry current_width current_height
    local stable_count=0

    while kill -0 "${qemu_pid}" 2>/dev/null; do
        window_id=""
        while read -r candidate; do
            if xprop -id "${candidate}" WM_CLASS >/dev/null 2>&1; then
                window_id="${candidate}"
                break
            fi
        done < <(xdotool search --onlyvisible --pid "${qemu_pid}" 2>/dev/null || true)

        if [[ -n "${window_id}" ]]; then
            workarea="$(xprop -root _NET_WORKAREA 2>/dev/null || true)"
            if [[ "${workarea}" =~ =\ *([0-9]+),\ *([0-9]+),\ *([0-9]+),\ *([0-9]+) ]]; then
                work_x="${BASH_REMATCH[1]}"
                work_y="${BASH_REMATCH[2]}"
                work_width="${BASH_REMATCH[3]}"
                work_height="${BASH_REMATCH[4]}"
            else
                work_x=0
                work_y=0
                read -r work_width work_height < <(xdotool getdisplaygeometry)
            fi

            available_width=$((work_width - margin * 2))
            available_height=$((work_height - margin * 2))
            if (( available_width * HEIGHT <= available_height * WIDTH )); then
                target_width="${available_width}"
                target_height=$((available_width * HEIGHT / WIDTH))
            else
                target_height="${available_height}"
                target_width=$((available_height * WIDTH / HEIGHT))
            fi

            geometry="$(xdotool getwindowgeometry --shell "${window_id}" 2>/dev/null || true)"
            current_width="$(sed -n 's/^WIDTH=//p' <<<"${geometry}")"
            current_height="$(sed -n 's/^HEIGHT=//p' <<<"${geometry}")"
            if [[ "${current_width}" == "${target_width}" && "${current_height}" == "${target_height}" ]]; then
                stable_count=$((stable_count + 1))
                if (( stable_count >= 6 )); then
                    return 0
                fi
            else
                stable_count=0
                xdotool windowsize --sync "${window_id}" "${target_width}" "${target_height}" 2>/dev/null || true
                target_x=$((work_x + (work_width - target_width) / 2))
                target_y=$((work_y + (work_height - target_height) / 2))
                xdotool windowmove --sync "${window_id}" "${target_x}" "${target_y}" 2>/dev/null || true
            fi
        fi
        sleep 0.5
    done
}

if [[ "${1:-auto}" == "tcg" ]]; then
    ACCEL="tcg"
    CPU="max"
elif [[ "${1:-auto}" == "kvm" ]]; then
    ACCEL="kvm"
    CPU="host"
elif [[ "${1:-auto}" == "auto" ]]; then
    if [[ -r /dev/kvm && -w /dev/kvm ]]; then
        ACCEL="kvm"
        CPU="host"
    else
        ACCEL="tcg"
        CPU="max"
    fi
else
    echo "Usage: $0 [auto|kvm|tcg]" >&2
    exit 2
fi

resolve_command() {
    command -v "$1" 2>/dev/null || true
}

if [[ ! -x "$(resolve_command "${QEMU}")" && ! -x "${QEMU}" ]]; then
    echo "Missing QEMU executable: ${QEMU}" >&2
    echo "Install qemu-system-x86 or set QEMU=/path/to/qemu-system-x86_64." >&2
    exit 1
fi

if [[ ! -x "$(resolve_command "${QEMU_IMG}")" && ! -x "${QEMU_IMG}" ]]; then
    echo "Missing qemu-img executable: ${QEMU_IMG}" >&2
    echo "Install qemu-utils or set QEMU_IMG=/path/to/qemu-img." >&2
    exit 1
fi

if [[ ! -f "${KERNEL}" ]]; then
    echo "Missing kernel: ${KERNEL}" >&2
    echo "Run ./download_kernel.sh or set KERNEL to a compatible kernel-ranchu file." >&2
    exit 1
fi

if [[ ! -f "${RAMDISK}" ]]; then
    echo "Missing ramdisk: ${RAMDISK}" >&2
    exit 1
fi

mkdir -p "${ARTIFACTS}"

if [[ ! -f "${DATA_IMG}" ]]; then
    echo "Creating 512M userdata image..."
    "${QEMU_IMG}" create -f raw "${DATA_IMG}" 512M
fi

case "${WINDOW_MODE}" in
    auto)
        if [[ -n "${DISPLAY:-}" ]] && command -v xdotool >/dev/null 2>&1; then
            FULLSCREEN="off"
            FIT_WINDOW="true"
        else
            FULLSCREEN="on"
            FIT_WINDOW="false"
        fi
        ;;
    window)
        if [[ -z "${DISPLAY:-}" ]] || ! command -v xdotool >/dev/null 2>&1; then
            echo "WINDOW_MODE=window requires X11 and xdotool." >&2
            echo "Install xdotool or use WINDOW_MODE=fullscreen." >&2
            exit 1
        fi
        FULLSCREEN="off"
        FIT_WINDOW="true"
        ;;
    fullscreen)
        FULLSCREEN="on"
        FIT_WINDOW="false"
        ;;
    *)
        echo "Usage: WINDOW_MODE=auto|window|fullscreen $0 [auto|kvm|tcg]" >&2
        exit 2
        ;;
esac

echo "Starting TWRP emux64..."
echo "Accel: ${ACCEL}"
echo "CPU: ${CPU}"
echo "QEMU log: ${LOG}"
echo "ADB command after boot: adb connect 127.0.0.1:5557"

"${QEMU}" \
    -machine "pc,accel=${ACCEL}" \
    -cpu "${CPU}" \
    -smp 4 \
    -m 4096 \
    -kernel "${KERNEL}" \
    -initrd "${RAMDISK}" \
    -drive "file=${DATA_IMG},if=none,format=raw,id=userdata" \
    -nodefaults \
    -append "8250.nr_uarts=1 clocksource=pit no_timer_check console=0 androidboot.hardware=ranchu androidboot.selinux=permissive androidboot.serialno=QEMU0001 qemu=1 skip_initramfs video=Virtual-1:${WIDTH}x${HEIGHT}@${REFRESH}" \
    -device "virtio-gpu-pci,edid=on,xres=${WIDTH},yres=${HEIGHT}" \
    -device virtio-rng-pci \
    -device virtio-serial-pci,ioeventfd=off \
    -device usb-ehci \
    -device usb-storage,drive=userdata \
    -device usb-tablet \
    -device virtio-net-pci,netdev=net0 \
    -netdev user,id=net0,hostfwd=tcp::5557-:5555 \
    -vga none \
    -display "gtk,full-screen=${FULLSCREEN},show-menubar=off,show-cursor=on,zoom-to-fit=on" \
    -serial "file:${LOG}" \
    -monitor tcp:127.0.0.1:5558,server,nowait \
    -no-reboot &
QEMU_PID=$!

FIT_PID=""
if [[ "${FIT_WINDOW}" == "true" ]]; then
    fit_qemu_window "${QEMU_PID}" &
    FIT_PID=$!
fi

set +e
wait "${QEMU_PID}"
QEMU_STATUS=$?
set -e

if [[ -n "${FIT_PID}" ]]; then
    kill "${FIT_PID}" 2>/dev/null || true
fi

exit "${QEMU_STATUS}"
